from datetime import date, timedelta
from app.base_datos.conexion import get_client


def actualizar_racha(id_usuario: int) -> dict:
    """
    Se llama cada vez que el usuario abre la app.
    
    Lógica:
    - Si ultimo_acceso es hoy → no hacer nada (ya se contó)
    - Si ultimo_acceso fue ayer → sumar 1 a la racha
    - Si ultimo_acceso fue hace más de 1 día → resetear racha a 1
    - Si nunca accedió → iniciar racha en 1
    """
    db  = get_client()
    hoy = date.today()

    # Obtener datos actuales del usuario
    res = db.table("usuario") \
            .select("racha_actual, ultimo_acceso") \
            .eq("id", id_usuario) \
            .single() \
            .execute()

    if not res.data:
        return {"racha_actual": 0, "cambio": "sin_cambio"}

    racha_actual  = res.data["racha_actual"]
    ultimo_acceso = res.data["ultimo_acceso"]

    # Parsear la fecha si existe
    if ultimo_acceso:
        ultimo_acceso = date.fromisoformat(ultimo_acceso)

    # ── Determinar qué hacer ─────────────────────────────────────────────
    if ultimo_acceso == hoy:
        # Ya entró hoy — no cambiar nada
        return {
            "racha_actual": racha_actual,
            "cambio":       "sin_cambio",
        }

    if ultimo_acceso == hoy - timedelta(days=1):
        # Entró ayer — sumar 1
        nueva_racha = racha_actual + 1
        cambio      = "incremento"
    else:
        # No entró ayer — resetear
        nueva_racha = 1
        cambio      = "reset" if racha_actual > 0 else "inicio"

    # Actualizar en BD
    db.table("usuario").update({
        "racha_actual":  nueva_racha,
        "ultimo_acceso": hoy.isoformat(),
    }).eq("id", id_usuario).execute()

    # Evaluar logros de racha
    logros_nuevos = _evaluar_logros_racha(db, id_usuario, nueva_racha)

    return {
        "racha_actual": nueva_racha,
        "cambio":       cambio,
        "logros_nuevos": logros_nuevos,
    }


def _evaluar_logros_racha(db, id_usuario: int, racha: int) -> list[dict]:
    """Otorga logros de racha si el usuario los cumple y no los tiene."""
    condiciones_racha = {
        'RACHA_3': racha >= 3,
        'RACHA_7': racha >= 7,
    }

    ya_tiene = {
        r["id_logro"]
        for r in db.table("usuario_logro")
                   .select("id_logro")
                   .eq("id_usuario", id_usuario)
                   .execute().data
    }

    logros_nuevos = []
    for condicion, cumple in condiciones_racha.items():
        if not cumple:
            continue

        logro = db.table("logro") \
                  .select("*") \
                  .eq("condicion", condicion) \
                  .execute().data

        if not logro or logro[0]["id"] in ya_tiene:
            continue

        db.table("usuario_logro").insert({
            "id_usuario": id_usuario,
            "id_logro":   logro[0]["id"],
            "notificado": False,
        }).execute()

        logros_nuevos.append({
            "id":     logro[0]["id"],
            "nombre": logro[0]["nombre"],
            "icono":  logro[0]["icono"],
        })

    return logros_nuevos