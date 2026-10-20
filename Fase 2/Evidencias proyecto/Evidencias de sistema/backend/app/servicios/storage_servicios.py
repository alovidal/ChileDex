import os
import uuid
from fastapi import UploadFile, HTTPException
from app.base_datos.conexion import get_client


async def subir_foto_perfil(id_usuario: int, archivo: UploadFile) -> str:
    tipos_permitidos = {"image/jpeg", "image/png", "image/webp", "image/jpg"}
    if archivo.content_type not in tipos_permitidos:
        raise HTTPException(status_code=400, detail="Solo se permiten imágenes JPG, PNG o WEBP")

    db        = get_client()
    contenido = await archivo.read()

    extension = archivo.filename.split(".")[-1]
    nombre    = f"usuario_{id_usuario}_{uuid.uuid4().hex[:8]}.{extension}"
    ruta      = f"perfiles/{nombre}"

    try:
        db.storage.from_("fotos-perfil").upload(
            path=ruta,
            file=contenido,
            file_options={"content-type": archivo.content_type},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al subir la imagen: {str(e)}")

    url = db.storage.from_("fotos-perfil").get_public_url(ruta)

    db.table("usuario") \
      .update({"foto_perfil_url": url}) \
      .eq("id", id_usuario) \
      .execute()

    return url