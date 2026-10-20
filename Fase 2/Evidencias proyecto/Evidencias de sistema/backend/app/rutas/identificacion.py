from fastapi import APIRouter, UploadFile, File
from app.servicios.identificacion_servicio import identificar_especie

router = APIRouter(prefix="/identificar", tags=["Identificación IA"])

@router.post("/")
async def identificar(imagen: UploadFile = File(...)):
    return await identificar_especie(imagen)