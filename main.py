import os
import json
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from scalar_fastapi import get_scalar_api_reference

from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.output_parsers import StrOutputParser
from langchain_core.messages import HumanMessage, AIMessage

# Importamos la función de acceso a los datos del cliente desde database.py
from database import obtener_datos_cliente

# 1. Cargar variables de entorno (.env)
load_dotenv()

TEAM_KEY = os.getenv("TEAM_KEY")
if not TEAM_KEY:
    raise ValueError("No se encontró la variable TEAM_KEY en el archivo .env")

# 2. Inicializar FastAPI (desactivamos docs por defecto para usar Scalar)
app = FastAPI(
    title="Sigma DZY Financial API",
    description="Backend del Asesor Financiero IA para la app móvil Sigma DZY",
    version="1.0.0",
    docs_url=None,
    redoc_url=None,
)

# Configurar CORS para permitir peticiones desde la app Flutter
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

DIAGNÓSTICO FINANCIERO Y DATOS DE LA FAMILIA:
{contexto_financiero}

REGLAS DE ORO:
1. **Sé breve:** Ve directo al grano sin rodeos ni introducciones largas.
2. Basa tus respuestas en los datos reales del cliente (deudas, ahorros, fondo de emergencia, objetivos, etc.).
3. Mantén un tono empático, profesional y motivador, priorizando siempre el siguiente paso accionable.
4.Añade un pequeño disclaimer que indique que el fin de la conversación es solo para fines informativos y no constituye asesoramiento financiero profesional."""
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


# 6. Endpoints de la API
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


@app.post("/api/chat")
def chatear_con_asesor(req: MensajeChatRequest):
    """Endpoint para la pestaña 'Asesor IA' con contexto financiero completo."""
    try:
        datos = obtener_datos_cliente(req.user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al consultar la base de datos: {str(e)}")

    if not datos:
        raise HTTPException(status_code=404, detail=f"Cliente '{req.user_id}' no encontrado")

    # Inicializar historial si es la primera interacción del usuario
    if req.user_id not in historial_chats:
        historial_chats[req.user_id] = []

    # Serialización segura: evita KeyError/AttributeError sin importar el formato que devuelva database.py
    if isinstance(datos, dict):
        contexto_completo = json.dumps(datos, ensure_ascii=False, indent=2)
    elif hasattr(datos, "__dict__"):
        datos_limpios = {k: v for k, v in vars(datos).items() if not k.startswith("_")}
        contexto_completo = json.dumps(datos_limpios, ensure_ascii=False, indent=2, default=str)
    else:
        contexto_completo = str(datos)

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