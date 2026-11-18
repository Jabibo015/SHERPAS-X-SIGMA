import json
import os
import sqlite3
from typing import Any

from database import DB_NAME, actualizar_checkbox_objetivo, obtener_datos_cliente
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from langchain_core.messages import AIMessage, HumanMessage
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_openai import ChatOpenAI
from mcp_sync import sincronizar_casos_desde_mcp
from pydantic import BaseModel
from scalar_fastapi import get_scalar_api_reference

# 1. Cargar variables de entorno (.env)
load_dotenv()

TEAM_KEY = os.getenv("TEAM_KEY")
if not TEAM_KEY:
    raise ValueError("No se encontró la variable TEAM_KEY en el archivo .env")

# 2. Inicializar FastAPI (desactivamos docs por defecto para usar Scalar)
app = FastAPI(
    title="Sigma DZY Financial API",
    description="Backend del Asesor Financiero IA para la app móvil Sigma DZY",
    version="1.1.0",
    docs_url=None,
    redoc_url=None,
)

# Configurar CORS para permitir peticiones desde la app Flutter / DartPad
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 3. Configurar el modelo LLM con el endpoint de la hackathon de Sherpas
llm = ChatOpenAI(
    model="gpt-5-mini",
    api_key=TEAM_KEY,
    base_url="https://llm-hackathon.sherpaswealth.com/v1",
    temperature=0.3,
)

# 4. Definir el prompt y la cadena del Asesor IA (conciso y con diagnóstico financiero)
prompt_asesor = ChatPromptTemplate.from_messages([
    (
        "system",
        """Eres el Asesor Financiero IA de Sherpas en la app Sigma DZY. Tu prioridad absoluta es ser **muy conciso y directo**, ya que el usuario lee desde una pantalla móvil (máximo 2 o 3 frases o viñetas cortas).

DIAGNÓSTICO FINANCIERO Y PERFIL DE LA FAMILIA:
{contexto_financiero}

REGLAS DE ORO:
1. **Sé breve:** Ve directo al grano sin rodeos ni introducciones largas.
2. Basa tus respuestas en los datos reales del cliente (puntuación de salud, pilares, métricas clave, inversiones, deudas, liquidez, objetivos y preocupaciones de su perfil).
3. Adapta el tono a las preferencias y tensiones familiares descritas en su perfil (persona), manteniendo empatía y claridad, priorizando siempre el siguiente paso accionable.
4. Añade un breve disclaimer al final indicando que la información tiene fines únicamente educativos/informativos y no constituye asesoramiento financiero profesional."""
    ),
    MessagesPlaceholder(variable_name="historial"),
    ("human", "{pregunta}"),
])

cadena_asesor = prompt_asesor | llm | StrOutputParser()

# Memoria temporal en RAM para el historial de conversación por usuario
historial_chats: dict[str, list] = {}


# 5. Modelos de datos (Pydantic)
class MensajeChatRequest(BaseModel):
    user_id: str
    mensaje: str


class ActualizarObjetivoRequest(BaseModel):
    completado: bool


# 6. Helpers de extracción y normalización de casos Sherpas
def _construir_contexto_ia(datos: dict[str, Any]) -> str:
    """
    Construye un contexto financiero estructurado y compacto para el LLM,
    soportando tanto casos importados del MCP de Sherpas como el mock inicial.
    """
    diag = datos.get("diagnostico", {})

    # Si es un caso importado desde el MCP de Sherpas (tiene financial_health / investment_analysis)
    if "financial_health" in diag or "investment_analysis" in diag:
        fh = diag.get("financial_health", {})
        ia = diag.get("investment_analysis", {})
        persona = diag.get("persona_markdown", "")

        resumen_estructurado = {
            "cliente": datos.get("nombre"),
            "user_id": datos.get("user_id"),
            "puntuacion_salud": datos.get("puntuacion_salud"),
            "hogar": fh.get("case", {}),
            "score_y_pilares": fh.get("score", {}),
            "metricas_salud_financiera": fh.get("key_metrics", {}),
            "perfil_financiero": fh.get("profile", {}),
            "metas_financieras": fh.get("goals", {}),
            "narrativa_salud": fh.get("narrative", {}),
            "metricas_inversion": ia.get("key_metrics", {}),
            "posiciones_inversion": ia.get("positions", {}),
            "analisis_inversion": ia.get("analysis", {}),
            "narrativa_inversion": ia.get("narrative", {}),
            "objetivos_plan_accion": datos.get("objetivos", []),
            # Limitamos persona_markdown a 4500 chars para mantener baja latencia
            "perfil_conductual_persona": persona[:4500] if isinstance(persona, str) else "",
        }
        return json.dumps(resumen_estructurado, ensure_ascii=False, indent=2)

    # Caso mock inicial (user_timothy_01)
    return json.dumps(datos, ensure_ascii=False, indent=2)


def _normalizar_para_frontend(datos: dict[str, Any]) -> dict[str, Any]:
    """
    Entrega los datos completos del cliente más un bloque 'resumen_ui'
    unificado para que Flutter pinte tarjetas, pilares y plan de acción sin fallos.
    """
    diag = datos.get("diagnostico", {})

    if "financial_health" in diag:
        fh = diag.get("financial_health", {})
        ia = diag.get("investment_analysis", {})
        score_block = fh.get("score", {})
        fh_metrics = fh.get("key_metrics", {})
        ia_metrics = ia.get("key_metrics", {})

        datos["resumen_ui"] = {
            "nombre": datos.get("nombre"),
            "puntuacion_salud": score_block.get("published_score", datos.get("puntuacion_salud")),
            "banda": score_block.get("band", ""),
            "color_alerta": score_block.get("colour", ""),
            "mensaje_score": score_block.get("message", ""),
            "pilares": score_block.get("pillars", []),
            "top_moves": score_block.get("top_moves", []),
            "hogar": fh.get("case", {}).get("household", []),
            "ubicacion": f"{fh.get('case', {}).get('city', '')}, {fh.get('case', {}).get('state', '')}".strip(", "),
            "metricas_salud": fh_metrics,
            "metricas_inversion": ia_metrics,
            "narrativa_salud": fh.get("narrative", {}),
            "narrativa_inversion": ia.get("narrative", {}),
            "posiciones": ia.get("positions", []),
            "objetivos": datos.get("objetivos", []),
        }
    else:
        datos["resumen_ui"] = {
            "nombre": datos.get("nombre"),
            "puntuacion_salud": datos.get("puntuacion_salud"),
            "diagnostico_legacy": diag,
            "objetivos": datos.get("objetivos", []),
        }

    return datos


# 7. Endpoints de la API
@app.get("/scalar", include_in_schema=False)
async def scalar_html():
    """Documentación interactiva con Scalar."""
    return get_scalar_api_reference(
        openapi_url=app.openapi_url,
        title=app.title,
    )


@app.get("/")
def health_check():
    """Verificación rápida de estado del servidor."""
    return {"status": "ok", "servicio": "Sigma DZY Financial Backend"}


@app.get("/api/clientes")
def listar_clientes():
    """Lista todos los clientes disponibles en SQLite (mock + importados del MCP)."""
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT user_id, nombre, correo, puntuacion_salud FROM clientes ORDER BY nombre ASC"
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


@app.get("/api/cliente/{user_id}")
def detalle_cliente(user_id: str):
    """Devuelve el diagnóstico completo y normalizado para las pantallas de Flutter."""
    datos = obtener_datos_cliente(user_id)
    if not datos:
        raise HTTPException(status_code=404, detail=f"Cliente '{user_id}' no encontrado")
    return _normalizar_para_frontend(datos)


@app.patch("/api/objetivos/{objetivo_id}")
def toggle_objetivo(objetivo_id: int, req: ActualizarObjetivoRequest):
    """Actualiza el estado completado de un checkbox del Plan de Acción."""
    actualizar_checkbox_objetivo(objetivo_id, req.completado)
    return {"status": "ok", "objetivo_id": objetivo_id, "completado": req.completado}


@app.post("/api/sync-mcp")
async def endpoint_sync_mcp():
    """Ejecuta la sincronización bajo demanda contra el servidor MCP de Sherpas."""
    try:
        return await sincronizar_casos_desde_mcp()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al sincronizar con MCP: {str(e)}")


@app.post("/api/chat")
def chatear_con_asesor(req: MensajeChatRequest):
    """Endpoint para la pestaña 'Asesor IA' con contexto financiero completo de Sherpas."""
    try:
        datos = obtener_datos_cliente(req.user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al consultar la base de datos: {str(e)}")

    if not datos:
        raise HTTPException(status_code=404, detail=f"Cliente '{req.user_id}' no encontrado")

    if req.user_id not in historial_chats:
        historial_chats[req.user_id] = []

    contexto_completo = _construir_contexto_ia(datos)

    try:
        respuesta = cadena_asesor.invoke({
            "contexto_financiero": contexto_completo,
            "historial": historial_chats[req.user_id],
            "pregunta": req.mensaje,
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al consultar el LLM: {str(e)}")

    # Guardar mensajes en el historial y mantener solo los últimos 6 (3 turnos)
    historial_chats[req.user_id].append(HumanMessage(content=req.mensaje))
    historial_chats[req.user_id].append(AIMessage(content=respuesta))
    historial_chats[req.user_id] = historial_chats[req.user_id][-6:]

    return {"respuesta": respuesta}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)