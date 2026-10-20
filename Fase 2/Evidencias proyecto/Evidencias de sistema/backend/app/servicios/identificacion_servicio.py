import httpx
from fastapi import UploadFile, HTTPException

GCP_URL = "https://chiledex-ia-884575410081.us-central1.run.app/identificar"
TIMEOUT = 120  # la primera petición carga el modelo, puede tardar

async def identificar_especie(imagen: UploadFile) -> dict:
    contenido = await imagen.read()
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            response = await client.post(
                GCP_URL,
                files={"imagen": (imagen.filename, contenido, imagen.content_type)},
            )
            response.raise_for_status()
            return response.json()
    except httpx.TimeoutException:
        raise HTTPException(status_code=504,
            detail="El servicio de IA tardó demasiado. Intenta nuevamente.")
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=502,
            detail=f"Error del servicio IA: {e.response.status_code}")