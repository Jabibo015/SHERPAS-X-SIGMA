import os
import sqlite3
import json

# Ruta absoluta garantizada hacia sherpas_sigma.db en la misma carpeta que este archivo
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_NAME = os.path.join(BASE_DIR, "sherpas_sigma.db")

def init_db():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()

    # Tabla de usuarios y su diagnóstico financiero
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS clientes (
        user_id TEXT PRIMARY KEY,
        nombre TEXT,
        correo TEXT,
        preferencia_visual INTEGER,
        puntuacion_salud INTEGER,
        diagnostico_json TEXT
    )
    """)

    # Tabla de objetivos / checkboxes del Plan de Acción
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS objetivos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        titulo TEXT,
        frecuencia TEXT,
        completado INTEGER,
        FOREIGN KEY(user_id) REFERENCES clientes(user_id)
    )
    """)

    # Insertar datos de prueba basados en el código Flutter de Sigma DZY
    diagnostico_timothy = {
        "familia": "Timothy Perez y Melanie (hijos: Liam y Josh)",
        "ingresos_conjuntos_anuales": 270000,
        "ingresos_timothy": 150000,
        "ingresos_melanie": 120000,
        "ahorro_anual": 61500,
        "tasa_ahorro": "22.8%",
        "flujo_libre_anual": 37000,
        "patrimonio_total": 788500,
        "desglose_patrimonio": {
            "vivienda": "44.4%",
            "inversiones": "26.6%",
            "efectivo": "19.0%",
            "otros": "10.0%"
        },
        "deuda_total": 93000,
        "desglose_deudas": [
            {"tipo": "Hipoteca", "monto": 50000, "interes": "6%"},
            {"tipo": "Tarjeta Chase", "monto": 18000, "interes": "18% (Punto crítico)"},
            {"tipo": "Préstamo Estudios", "monto": 15000, "interes": "5%"},
            {"tipo": "Préstamo Coche", "monto": 10000, "interes": "4%"}
        ],
        "ratios": {"debt_to_income": "13%", "housing_ratio": "11%"},
        "jubilacion": {
            "anio_objetivo": 2048,
            "cobertura_gastos": "93%",
            "patrimonio_proyectado_jubilacion": 2800000
        },
        "proteccion_y_educacion": {
            "fondo_emergencia_actual": 150801,
            "fondo_emergencia_recomendado": 85000,
            "seguro_vida_timothy_actual": 140000,
            "seguro_vida_recomendado": 750000,
            "poliza_umbrella": 0,
            "cuenta_universidad_529": 0
        }
    }

    cursor.execute("""
    INSERT OR IGNORE INTO clientes (user_id, nombre, correo, preferencia_visual, puntuacion_salud, diagnostico_json)
    VALUES (?, ?, ?, ?, ?, ?)
    """, (
        "user_timothy_01",
        "Timothy Perez",
        "timothy.perez@email.com",
        1,
        60,
        json.dumps(diagnostico_timothy, ensure_ascii=False)
    ))

    # Insertar objetivos de ejemplo si está vacía la tabla
    cursor.execute("SELECT COUNT(*) FROM objetivos WHERE user_id = 'user_timothy_01'")
    if cursor.fetchone()[0] == 0:
        objetivos_iniciales = [
            ("user_timothy_01", "Liquidar deuda de tarjeta Chase ($18,000 al 18%)", "Inmediato", 1),
            ("user_timothy_01", "Abrir y aportar $4,609/año a cuenta universitaria 529 (Liam y Josh)", "Anual", 0),
            ("user_timothy_01", "Ampliar seguro de vida de Timothy a $750,000", "Trimestral", 0),
            ("user_timothy_01", "Contratar póliza Umbrella de $1M", "Trimestral", 0),
            ("user_timothy_01", "Mantener ahorro mensual automático ($5,125/mes)", "Mensual", 1)
        ]
        cursor.executemany("""
        INSERT INTO objetivos (user_id, titulo, frecuencia, completado)
        VALUES (?, ?, ?, ?)
        """, objetivos_iniciales)

    conn.commit()
    conn.close()

def obtener_datos_cliente(user_id: str):
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM clientes WHERE user_id = ?", (user_id,))
    cliente = cursor.fetchone()
    if not cliente:
        conn.close()
        return None

    cursor.execute("SELECT id, titulo, frecuencia, completado FROM objetivos WHERE user_id = ?", (user_id,))
    objetivos = [dict(row) for row in cursor.fetchall()]
    conn.close()

    return {
        "user_id": cliente["user_id"],
        "nombre": cliente["nombre"],
        "correo": cliente["correo"],
        "puntuacion_salud": cliente["puntuacion_salud"],
        "diagnostico": json.loads(cliente["diagnostico_json"]),
        "objetivos": objetivos
    }

def actualizar_checkbox_objetivo(objetivo_id: int, completado: bool):
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("UPDATE objetivos SET completado = ? WHERE id = ?", (1 if completado else 0, objetivo_id))
    conn.commit()
    conn.close()

# Garantiza que las tablas y datos iniciales existan al importar database.py
init_db()