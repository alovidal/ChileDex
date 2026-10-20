from app.base_datos.conexion import get_client


def obtener_eventos_activos() -> list[dict]:
    """Devuelve los eventos activos ordenados por fecha más próxima."""
    db = get_client()
    res = db.table("evento") \
            .select("*") \
            .eq("activo", True) \
            .order("fecha", desc=False) \
            .execute()
    return res.data

def obtener_evento(id_evento: int) -> dict:
    db = get_client()
    res = db.table("evento") \
            .select("*") \
            .eq("id", id_evento) \
            .single() \
            .execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Evento no encontrado")
    return res.data