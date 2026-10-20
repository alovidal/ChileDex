import io
import json
from pathlib import Path

import numpy as np
import open_clip
import torch
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image

MODELO_CLIP      = "hf-hub:imageomics/bioclip-2"
DIR_MODELO       = Path("modelo")
UMBRAL_SIMILITUD = 0.85

app = FastAPI(title="ChileDex Inferencia", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# Se carga en la primera petición, no al arrancar
_recursos = None

def cargar_recursos():
    global _recursos
    if _recursos is None:
        dispositivo = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"[carga] cargando {MODELO_CLIP} en {dispositivo}...")
        modelo, _, preproceso = open_clip.create_model_and_transforms(MODELO_CLIP)
        modelo = modelo.to(dispositivo).eval()
        datos = np.load(DIR_MODELO / "centroides.npz")
        centroides = datos["centroides"].astype(np.float32)
        clases = json.loads((DIR_MODELO / "clases.json").read_text(encoding="utf-8"))
        print(f"[carga] listo. {len(clases)} clases.")
        _recursos = (modelo, preproceso, dispositivo, centroides, clases)
    return _recursos


@app.get("/")
def estado():
    return {"estado": "ok"}


@app.post("/identificar")
async def identificar(imagen: UploadFile = File(...)):
    if not imagen.content_type or not imagen.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Se esperaba una imagen.")

    contenido = await imagen.read()
    try:
        img = Image.open(io.BytesIO(contenido)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=422, detail="No se pudo decodificar la imagen.")

    modelo, preproceso, dispositivo, centroides, clases = cargar_recursos()

    tensor = preproceso(img).unsqueeze(0).to(dispositivo)
    with torch.no_grad():
        vector = modelo.encode_image(tensor)
        vector = vector / vector.norm(dim=-1, keepdim=True)

    vector_np = vector.cpu().numpy()[0].astype(np.float32)
    puntajes  = vector_np @ centroides.T
    indice    = int(puntajes.argmax())
    similitud = float(puntajes[indice])

    identificado = similitud >= UMBRAL_SIMILITUD
    return {
        "identificado":  identificado,
        "especie":       clases[indice] if identificado else None,
        "similitud":     round(similitud, 4),
        "confianza_pct": round(similitud * 100, 1),
    }