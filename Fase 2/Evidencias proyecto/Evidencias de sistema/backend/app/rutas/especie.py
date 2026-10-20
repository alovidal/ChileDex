from fastapi import APIRouter, Query
from typing import Optional
from app.servicios import especie_servicio as svc

router = APIRouter(prefix="/especies", tags=["Especies"])

@router.get("/destacadas")
def destacadas():
    # Momentáneo: solo ids 1, 2, 3
    return svc.obtener_especies_destacadas([1, 2, 3])

@router.get("/regiones")
def regiones():
    return svc.obtener_regiones()

@router.get("/regiones/usuario")
def regiones_usuario():
    return svc.obtener_regiones_usuario()

@router.get("/regiones/{id_region}")
def detalle_region(id_region: int):
    return svc.obtener_region(id_region)

@router.get("/catalogo")
def catalogo(
    categoria:           Optional[str]       = Query(None),
    estado_conservacion: Optional[list[str]] = Query(None),
    habitat_ids:         Optional[list[int]] = Query(None),
    region_ids:          Optional[list[int]] = Query(None),
    busqueda:            Optional[str]        = Query(None),
    orden:               str                  = Query("asc"),
    pagina:              int                  = Query(1, ge=1),
    por_pagina:          int                  = Query(6, ge=1, le=50),
    id_usuario:          Optional[int]        = Query(None),   # ← nuevo
    solo_vistas:         Optional[bool]       = Query(None),   # ← nuevo
):
    return svc.obtener_catalogo(
        categoria, estado_conservacion,
        habitat_ids, region_ids, busqueda, orden,
        pagina, por_pagina,
        id_usuario, solo_vistas,
    )

@router.get("/habitats")
def habitats():
    return svc.obtener_habitats()

@router.get("/conteo-estados")
def conteo_estados():
    return svc.obtener_conteo_por_estado()

@router.get("/{id_especie}")
def detalle_especie(
    id_especie: int,
    id_usuario: Optional[int] = Query(None),
):
    return svc.obtener_detalle_especie(id_especie, id_usuario)

@router.get("/por-nombre/{nombre_cientifico}")
def por_nombre_cientifico(nombre_cientifico: str):
    return svc.obtener_especie_por_nombre_cientifico(nombre_cientifico)