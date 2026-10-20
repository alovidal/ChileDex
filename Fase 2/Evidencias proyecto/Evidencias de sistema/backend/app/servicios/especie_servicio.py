from fastapi import HTTPException
from app.base_datos.conexion import get_client
from typing import Optional

CATEGORIAS_VALIDAS = {"FLORA","MAMIFERO","AVE","REPTIL","ANFIBIO","INSECTO"}

def obtener_especies_destacadas(ids: list[int]) -> list[dict]:
    db = get_client()

    # Obtener las especies por los ids indicados
    res = db.table("especie").select("*").in_("id", ids).execute()
    especies = res.data

    if not especies:
        raise HTTPException(status_code=404, detail="No se encontraron especies")

    # Para cada especie, obtener sus fotografías ordenadas
    for especie in especies:
        fotos = (
            db.table("especie_fotografia")
            .select("*")
            .eq("especie_id", especie["id"])
            .order("orden")
            .execute()
        )
        especie["fotografias"] = fotos.data

    return especies

def obtener_regiones() -> list[dict]:
    db = get_client()
    # res = db.table("region").select("*").order("id").execute()
    res = db.table("region").select("*").in_("id", [14, 16]).order("id").execute()
    return res.data

def obtener_regiones_usuario() -> list[dict]:
    """Todas las regiones para el registro/perfil — excluye la 16."""
    db = get_client()
    res = db.table("region").select("*").neq("id", 16).order("id").execute()
    return res.data

def obtener_region(id_region: int) -> dict:
    db = get_client()
    res = db.table("region") \
            .select("*") \
            .eq("id", id_region) \
            .single() \
            .execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Región no encontrada")
    return res.data

def obtener_catalogo(
    categoria: str | None = None,
    estado_conservacion: list[str] | None = None,
    habitat_ids: list[int] | None = None,
    region_ids: list[int] | None = None,
    busqueda: str | None = None,
    orden: str = "asc",
    pagina: int = 1,
    por_pagina: int = 6,
    id_usuario: int | None = None,    # ← nuevo
    solo_vistas: bool | None = None,  # ← nuevo
) -> dict:
    db = get_client()

    # ── Filtro por especies vistas/no vistas ──────────────────────────────
    ids_vistas = None
    if id_usuario is not None and solo_vistas is not None:
        res = db.table("usuario_especie") \
                .select("id_especie") \
                .eq("id_usuario", id_usuario) \
                .execute()
        ids_vistas = [r["id_especie"] for r in res.data]

    # ── Resolver IDs de especies por región usando RPC ────────────────────
    ids_por_region = None
    if region_ids:
        res = db.rpc("filtrar_especies_por_region", {
            "region_ids": region_ids
        }).execute()
        ids_por_region = [r["id_especie"] for r in res.data]

        if not ids_por_region:
            return {"especies": [], "total": 0, "pagina": pagina,
                    "por_pagina": por_pagina, "hay_mas": False}

    # ── Resolver IDs de especies por hábitat ──────────────────────────────
    ids_por_habitat = None
    if habitat_ids:
        res = db.table("habitat_especie") \
                .select("id_especie") \
                .in_("id_habitat", habitat_ids) \
                .execute()
        ids_por_habitat = list({r["id_especie"] for r in res.data})

        if not ids_por_habitat:
            return {"especies": [], "total": 0, "pagina": pagina,
                    "por_pagina": por_pagina, "hay_mas": False}

    # ── Intersección de todos los filtros de IDs ──────────────────────────
    sets = []
    if ids_por_region  is not None: sets.append(set(ids_por_region))
    if ids_por_habitat is not None: sets.append(set(ids_por_habitat))

    # Aplicar filtro de vistas
    if ids_vistas is not None:
        if solo_vistas:
            # Solo las que el usuario ya vio
            sets.append(set(ids_vistas))
        else:
            # Solo las que NO ha visto — se aplica como exclusión después
            pass

    ids_filtrados = None
    if sets:
        ids_filtrados = list(set.intersection(*sets))
        if not ids_filtrados and not (solo_vistas is False):
            return {"especies": [], "total": 0, "pagina": pagina,
                    "por_pagina": por_pagina, "hay_mas": False}

    # ── Query principal ───────────────────────────────────────────────────
    query = db.table("especie").select("*, especie_fotografia(id, url, orden)")

    if categoria:
        query = query.eq("categoria", categoria.upper())
    if estado_conservacion:
        query = query.in_("estado_conservacion", estado_conservacion)
    if busqueda:
        query = query.ilike("nombre_comun", f"%{busqueda}%")

    # Aplicar IDs filtrados (región + hábitat + vistas si solo_vistas=True)
    if ids_filtrados is not None:
        query = query.in_("id", ids_filtrados)

    # Excluir las ya vistas si solo_vistas=False
    if solo_vistas is False and ids_vistas:
        query = query.not_.in_("id", ids_vistas)

    query = query.order("nombre_comun", desc=(orden == "desc"))

    # ── Paginación ────────────────────────────────────────────────────────
    offset = (pagina - 1) * por_pagina
    query  = query.range(offset, offset + por_pagina - 1)

    res      = query.execute()
    especies = res.data

    # ── Adjuntar primer hábitat ───────────────────────────────────────────
    for especie in especies:
        try:
            hab = db.table("habitat_especie") \
                    .select("habitat(nombre)") \
                    .eq("id_especie", especie["id"]) \
                    .limit(1) \
                    .execute()
            especie["habitat_nombre"] = (
                hab.data[0]["habitat"]["nombre"] if hab.data else None
            )
        except Exception:
            especie["habitat_nombre"] = None

    # ── Conteo total (mismos filtros, sin paginar) ────────────────────────
    total_res = db.table("especie").select("id", count="exact")
    if categoria:
        total_res = total_res.eq("categoria", categoria.upper())
    if estado_conservacion:
        total_res = total_res.in_("estado_conservacion", estado_conservacion)
    if busqueda:
        total_res = total_res.ilike("nombre_comun", f"%{busqueda}%")
    if ids_filtrados is not None:
        total_res = total_res.in_("id", ids_filtrados)
    if solo_vistas is False and ids_vistas:
        total_res = total_res.not_.in_("id", ids_vistas)
    total = total_res.execute().count or 0

    return {
        "especies":   especies,
        "total":      total,
        "pagina":     pagina,
        "por_pagina": por_pagina,
        "hay_mas":    (offset + por_pagina) < total,
    }
                                                                              
def obtener_habitats() -> list[dict]:
    db = get_client()
    return db.table("habitat").select("id, nombre").order("nombre").execute().data


def obtener_conteo_por_estado() -> list[dict]:
    """Devuelve cuántas especies hay por estado de conservación."""
    db = get_client()
    res = db.table("especie").select("estado_conservacion").execute()
    conteos: dict[str, int] = {}
    for e in res.data:
        estado = e["estado_conservacion"] or "Sin clasificar"
        conteos[estado] = conteos.get(estado, 0) + 1
    return [{"estado": k, "cantidad": v} for k, v in conteos.items()]

def obtener_detalle_especie(id_especie: int, id_usuario: int | None = None) -> dict:
    """
    Devuelve la ficha completa de una especie:
    - Datos básicos + fotografías
    - Hábitats asociados
    - Avistamientos del usuario para esa especie (si se pasa id_usuario)
    """
    db = get_client()

    # ── Especie base ──────────────────────────────────────────────────────
    res = db.table("especie").select("*").eq("id", id_especie).single().execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Especie no encontrada")
    especie = res.data

    # ── Fotografías ordenadas ─────────────────────────────────────────────
    fotos = db.table("especie_fotografia") \
              .select("*") \
              .eq("especie_id", id_especie) \
              .order("orden") \
              .execute()
    especie["fotografias"] = fotos.data

    # ── Hábitats asociados ────────────────────────────────────────────────
    habitats = db.table("habitat_especie") \
                 .select("habitat(id, nombre, descripcion)") \
                 .eq("id_especie", id_especie) \
                 .execute()
    especie["habitats"] = [h["habitat"] for h in habitats.data]

    # ── Avistamientos del usuario para esta especie ───────────────────────
    if id_usuario:
        avist = db.table("avistamiento") \
                  .select("id, fecha, lugar:latitud, longitud, fotografia_url") \
                  .eq("especie_id", id_especie) \
                  .eq("id_usuario", id_usuario) \
                  .order("fecha", desc=True) \
                  .execute()
        especie["mis_avistamientos"] = avist.data
    else:
        especie["mis_avistamientos"] = []

    return especie

def obtener_especie_por_nombre_cientifico(nombre_cientifico: str) -> dict:
    db = get_client()
    res = db.table("especie") \
            .select("*") \
            .ilike("nombre_cientifico", nombre_cientifico) \
            .single() \
            .execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Especie no encontrada")
    especie = res.data
    fotos = db.table("especie_fotografia") \
              .select("*") \
              .eq("especie_id", especie["id"]) \
              .order("orden") \
              .execute()
    especie["fotografias"] = fotos.data
    return especie