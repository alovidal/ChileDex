from fastapi import HTTPException
from app.base_datos.conexion import get_client


def marcar_especie_vista(
    id_usuario: int,
    id_especie: int,
    latitud: float | None = None,
    longitud: float | None = None,
    fotografia_url: str | None = None,
) -> dict:
    """
    Flujo completo al identificar una especie:
    1. Verificar si ya fue vista por el usuario
    2. Si es nueva → registrar en usuario_especie + crear avistamiento
    3. Si ya fue vista → solo crear avistamiento (sin sumar al progreso)
    4. Evaluar logros en ambos casos
    """
    db = get_client()

    # ── 1. ¿Ya fue vista? ─────────────────────────────────────────────────
    existente = db.table("usuario_especie") \
                  .select("id_especie") \
                  .eq("id_usuario", id_usuario) \
                  .eq("id_especie", id_especie) \
                  .execute()
    es_nueva = not existente.data

    # ── 2. Registrar en usuario_especie si es nueva ───────────────────────
    if es_nueva:
        db.table("usuario_especie").insert({
            "id_usuario": id_usuario,
            "id_especie": id_especie,
        }).execute()

    # ── 3. Siempre crear avistamiento ─────────────────────────────────────
    avistamiento = {
        "id_usuario":          id_usuario,
        "especie_id":          id_especie,
        "con_geolocalizacion": latitud is not None and longitud is not None,
    }
    if latitud       is not None: avistamiento["latitud"]        = latitud
    if longitud      is not None: avistamiento["longitud"]       = longitud
    if fotografia_url is not None: avistamiento["fotografia_url"] = fotografia_url

    db.table("avistamiento").insert(avistamiento).execute()

    # ── 4. Calcular stats actuales ────────────────────────────────────────
    total_especies_vistas = db.table("usuario_especie") \
                              .select("id_especie", count="exact") \
                              .eq("id_usuario", id_usuario) \
                              .execute().count or 0

    total_avistamientos = db.table("avistamiento") \
                            .select("id", count="exact") \
                            .eq("id_usuario", id_usuario) \
                            .execute().count or 0

    racha = db.table("usuario") \
              .select("racha_actual") \
              .eq("id", id_usuario) \
              .single() \
              .execute().data["racha_actual"]

    stats = {
        "total_especies":      total_especies_vistas,
        "total_avistamientos": total_avistamientos,
        "racha_actual":        racha,
    }

    # ── 5. Evaluar y otorgar logros ───────────────────────────────────────
    logros_nuevos = _evaluar_logros(db, id_usuario, stats)

    return {
        "es_nueva":        es_nueva,
        "total_especies":  total_especies_vistas,
        "logros_nuevos":   logros_nuevos,
    }


def _evaluar_condicion(condicion: str, stats: dict) -> bool:
    """
    Evalúa condiciones en formato texto libre de la BD.
    Ejemplos: 'avistamientos >= 1', 'especies_unicas >= 5', 'racha >= 7'
    """
    try:
        # Parsear el formato "campo >= valor"
        partes = condicion.strip().split()
        if len(partes) != 3:
            return False

        campo, operador, valor = partes
        valor = int(valor)

        # Mapear campo a stat
        stat = {
            'avistamientos':  stats['total_avistamientos'],
            'especies_unicas': stats['total_especies'],
            'racha':           stats['racha_actual'],
        }.get(campo)

        if stat is None:
            return False

        # Evaluar operador
        return {
            '>=': stat >= valor,
            '>':  stat >  valor,
            '==': stat == valor,
            '<=': stat <= valor,
            '<':  stat <  valor,
        }.get(operador, False)

    except Exception:
        return False


def _evaluar_logros(db, id_usuario: int, stats: dict) -> list[dict]:
    ya_tiene = db.table("usuario_logro") \
                 .select("id_logro") \
                 .eq("id_usuario", id_usuario) \
                 .execute()
    ids_ya_tiene = {r["id_logro"] for r in ya_tiene.data}

    todos = db.table("logro") \
              .select("*") \
              .not_.is_("condicion", "null") \
              .execute().data

    logros_nuevos = []
    for logro in todos:
        if logro["id"] in ids_ya_tiene:
            continue
        if _evaluar_condicion(logro["condicion"], stats):
            db.table("usuario_logro").insert({
                "id_usuario": id_usuario,
                "id_logro":   logro["id"],
                "notificado": False,
            }).execute()
            logros_nuevos.append({
                "id":     logro["id"],
                "nombre": logro["nombre"],
                "icono":  logro["icono"],
            })

    return logros_nuevos


def obtener_progreso_especies(id_usuario: int) -> dict:
    db = get_client()

    total_app = db.table("especie") \
                  .select("id", count="exact") \
                  .execute().count or 0

    vistas_res = db.table("usuario_especie") \
                   .select("id_especie", count="exact") \
                   .eq("id_usuario", id_usuario) \
                   .execute()

    return {
        "total_app":    total_app,
        "total_vistas": vistas_res.count or 0,
    }