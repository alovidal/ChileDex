from fastapi import APIRouter
from pydantic import BaseModel
import app.servicios.racha_servicio as svc

router = APIRouter(prefix="/racha", tags=["Racha"])

class RachaRequest(BaseModel):
    id_usuario: int

@router.post("/actualizar")
def actualizar_racha(body: RachaRequest):
    return svc.actualizar_racha(body.id_usuario)