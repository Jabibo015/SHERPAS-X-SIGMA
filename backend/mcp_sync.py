import os
import sys
import json
import sqlite3
import asyncio
import httpx
from dotenv import load_dotenv
from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client

APP_DIR = os.path.dirname(os.path.abspath(__file__))
if APP_DIR not in sys.path:
    sys.path.insert(0, APP_DIR)

try:
    from .database import DB_NAME, init_db
except ImportError:
    from database import DB_NAME, init_db

load_dotenv()

MCP_URL = os.getenv("MCP_URL")
MCP_TOKEN = os.getenv("MCP_KEY")


def _extraer_texto_mcp(resultado) -> str:
    if not resultado or not getattr(resultado, "content", None):
        return ""
    return "\n".join(item.text for item in resultado.content if getattr(item, "text", None))


def _formatear_nombre_hogar(fh_json: dict, case_id: str) -> str:
    """Extrae 'Daniel & Emily Johnson' desde case.household o usa el case_id."""
    case_info = fh_json.get("case", {}) if isinstance(fh_json, dict) else {}
    household = case_info.get("household", [])
    adultos = [
        m.get("first_name")
        for m in household
        if isinstance(m, dict) and m.get("role") in ("client", "co-client") and m.get("first_name")
    ]
    partes_slug = case_id.split("-")
    apellido = partes_slug[-1].title() if partes_slug else ""
    if adultos:
        return f"{' & '.join(adultos)} {apellido}".strip()
    return case_id.replace("-", " ").title()


async def sincronizar_casos_desde_mcp() -> dict:
    if not MCP_URL or not MCP_TOKEN:
        raise ValueError("Faltan MCP_URL o MCP_TOKEN en el archivo .env")

    init_db()
    headers = {"Authorization": f"Bearer {MCP_TOKEN}"}

    async with httpx.AsyncClient(headers=headers, timeout=60.0) as http_client:
        async with streamable_http_client(MCP_URL, http_client=http_client) as (read, write):
            async with ClientSession(read, write) as session:
                await session.initialize()

                res_lista = await session.call_tool("list_cases", {})
                data_lista = json.loads(_extraer_texto_mcp(res_lista))
                casos = data_lista if isinstance(data_lista, list) else data_lista.get("cases", [])

                conn = sqlite3.connect(DB_NAME)
                cursor = conn.cursor()
                sincronizados = []

                for caso in casos:
                    case_id = caso.get("caseId") or caso.get("id")
                    if not case_id:
                        continue

                    res_fh = await session.call_tool(
                        "get_case", {"caseId": case_id, "part": "financial-health"}
                    )
                    res_ia = await session.call_tool(
                        "get_case", {"caseId": case_id, "part": "investment-analysis"}
                    )
                    res_persona = await session.call_tool(
                        "get_case", {"caseId": case_id, "part": "persona"}
                    )

                    txt_fh = _extraer_texto_mcp(res_fh)
                    txt_ia = _extraer_texto_mcp(res_ia)
                    txt_persona = _extraer_texto_mcp(res_persona)

                    fh_json = json.loads(txt_fh) if txt_fh else {}
                    ia_json = json.loads(txt_ia) if txt_ia else {}

                    # 1. Nombre limpio del hogar
                    nombre = _formatear_nombre_hogar(fh_json, case_id)

                    # 2. Puntuación real (score.published_score)
                    score_block = fh_json.get("score", {}) if isinstance(fh_json, dict) else {}
                    puntuacion = int(
                        score_block.get("published_score")
                        or caso.get("score")
                        or 60
                    )

                    # 3. Guardar todo el paquete completo en diagnostico_json
                    diagnostico_completo = {
                        "case_id": case_id,
                        "financial_health": fh_json,
                        "investment_analysis": ia_json,
                        "persona_markdown": txt_persona,
                    }

                    correo = f"{case_id.replace('-', '.')}@sigmadzy.com"

                    cursor.execute(
                        """
                        INSERT INTO clientes (user_id, nombre, correo, preferencia_visual, puntuacion_salud, diagnostico_json)
                        VALUES (?, ?, ?, ?, ?, ?)
                        ON CONFLICT(user_id) DO UPDATE SET
                            nombre = excluded.nombre,
                            puntuacion_salud = excluded.puntuacion_salud,
                            diagnostico_json = excluded.diagnostico_json
                        """,
                        (
                            case_id,
                            nombre,
                            correo,
                            1,
                            puntuacion,
                            json.dumps(diagnostico_completo, ensure_ascii=False),
                        ),
                    )

                    # 4. Poblar objetivos del Plan de Acción desde score.top_moves
                    top_moves = score_block.get("top_moves", [])
                    if top_moves:
                        cursor.execute("DELETE FROM objetivos WHERE user_id = ?", (case_id,))
                        for move in top_moves:
                            titulo = f"{move.get('title', '')}: {move.get('action', '')}".strip(": ")
                            effort = str(move.get("effort", "medium")).lower()
                            frecuencia = (
                                "Inmediato" if effort == "low"
                                else "Trimestral" if effort == "medium"
                                else "Anual"
                            )
                            cursor.execute(
                                """
                                INSERT INTO objetivos (user_id, titulo, frecuencia, completado)
                                VALUES (?, ?, ?, 0)
                                """,
                                (case_id, titulo, frecuencia),
                            )

                    sincronizados.append({
                        "user_id": case_id,
                        "nombre": nombre,
                        "score": puntuacion,
                        "objetivos_creados": len(top_moves),
                    })

                conn.commit()
                conn.close()
                return {"total": len(sincronizados), "clientes": sincronizados}


if __name__ == "__main__":
    resultado = asyncio.run(sincronizar_casos_desde_mcp())
    print("Sincronizacion MCP completada:", json.dumps(resultado, indent=2, ensure_ascii=False))