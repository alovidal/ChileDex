from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
import app.servicios.progreso_servicio as svc

router = APIRouter(prefix="/progreso", tags=["Progreso"])

class MarcarVistaRequest(BaseModel):
    id_usuario:     int
    id_especie:     int
    latitud:        Optional[float] = None
    longitud:       Optional[float] = None
    fotografia_url: Optional[str]   = None

@router.post("/marcar-vista")
def marcar_vista(body: MarcarVistaRequest):
    return svc.marcar_especie_vista(
        body.id_usuario,
        body.id_especie,
        body.latitud,
        body.longitud,
        body.fotografia_url,
    )

@router.get("/{id_usuario}/especies")
def progreso_especies(id_usuario: int):
    return svc.obtener_progreso_especies(id_usuario)