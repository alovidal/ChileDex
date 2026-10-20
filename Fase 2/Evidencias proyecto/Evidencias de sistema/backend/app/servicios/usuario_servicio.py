from passlib.context import CryptContext
from fastapi import HTTPException
from app.base_datos.conexion import get_client
from app.modelos.usuario import RegistroRequest, EditarPerfilRequest
import random
import string
from datetime import datetime, timedelta, timezone
from app.servicios.correo_servicio import enviar_correo_recuperacion

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

def login(correo: str, contrasena: str) -> dict:
    db = get_client()
    res = db.table("usuario").select("*").eq("correo", correo).single().execute()
    usuario = res.data

    if not usuario:
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")

    # ← verificar contra el hash
    if not pwd_context.verify(contrasena, usuario["contrasena_hash"]):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")

    db.table("usuario").update({"logeado": True}).eq("id", usuario["id"]).execute()
    return {k: v for k, v in usuario.items() if k != "contrasena_hash"}

def registrar(data: RegistroRequest) -> dict:
    db = get_client()

    existente = db.table("usuario").select("id").eq("correo", data.correo).execute()
    if existente.data:
        raise HTTPException(status_code=400, detail="El correo ya está registrado")

    nuevo = {
        "correo":           data.correo,
        "contrasena_hash":  pwd_context.hash(data.contrasena),  # ← activar hash
        "nombre":           data.nombre,
        "ap_paterno":       data.ap_paterno,
        "ap_materno":       data.ap_materno,
        "fecha_nacimiento": data.fecha_nacimiento,
        "id_region":        data.id_region,
    }

    res = db.table("usuario").insert(nuevo).execute()
    usuario = res.data[0]
    return {k: v for k, v in usuario.items() if k != "contrasena_hash"}

def buscar_correo(correo: str) -> dict:
    db = get_client()
    res = db.table("usuario").select("id", "correo") \
            .eq("correo", correo).execute()
    if not res.data:
        raise HTTPException(
            status_code=404,
            detail="No encontramos una cuenta con ese correo"
        )

    # Generar token de 6 dígitos
    token = ''.join(random.choices(string.digits, k=6))

    # Guardar token y expiración en BD
    expiracion = datetime.now(timezone.utc) + timedelta(minutes=15)
    db.table("usuario").update({
        "token_recuperacion": token,
        "token_expiracion":   expiracion.isoformat(),
    }).eq("correo", correo).execute()

    # Enviar correo
    enviar_correo_recuperacion(correo, token)

    return {"encontrado": True, "correo": correo}


def restablecer_contrasena(correo: str, nueva_contrasena: str, token: str) -> dict:
    db = get_client()

    # Buscar usuario con ese token
    res = db.table("usuario") \
            .select("id, token_recuperacion, token_expiracion") \
            .eq("correo", correo) \
            .execute()

    if not res.data:
        raise HTTPException(status_code=404, detail="Correo no encontrado")

    usuario = res.data[0]

    # Verificar token
    if usuario["token_recuperacion"] != token:
        raise HTTPException(status_code=400, detail="Código incorrecto")

    # Verificar expiración
    expiracion = datetime.fromisoformat(usuario["token_expiracion"])
    if datetime.now(timezone.utc) > expiracion:
        raise HTTPException(status_code=400, detail="El código ha expirado")

    # Actualizar contraseña y limpiar token
    db.table("usuario").update({
        "contrasena_hash":    pwd_context.hash(nueva_contrasena),
        "token_recuperacion": None,
        "token_expiracion":   None,
    }).eq("correo", correo).execute()

    return {"mensaje": "Contraseña restablecida correctamente"}

def editar_perfil(id_usuario: int, data: EditarPerfilRequest) -> dict:
    db = get_client()

    # Construir solo los campos que vienen con valor
    campos = {k: v for k, v in data.model_dump().items() if v is not None}

    if not campos:
        raise HTTPException(status_code=400, detail="No hay campos para actualizar")

    # Verificar correo duplicado si se está cambiando
    if "correo" in campos:
        existente = db.table("usuario") \
                      .select("id") \
                      .eq("correo", campos["correo"]) \
                      .neq("id", id_usuario) \
                      .execute()
        if existente.data:
            raise HTTPException(status_code=400, detail="El correo ya está en uso")

    res = db.table("usuario") \
            .update(campos) \
            .eq("id", id_usuario) \
            .execute()

    if not res.data:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    usuario = res.data[0]
    return {k: v for k, v in usuario.items() if k != "contrasena_hash"}

def obtener_perfil(usuario_id: int) -> dict:
    db = get_client()
    res = db.table("usuario").select(
        "id, correo, nombre, ap_paterno, ap_materno, "
        "foto_perfil_url, racha_actual, created_at, "
        "region:id_region(id, nombre)"  # ← join con región
    ).eq("id", usuario_id).single().execute()

    if not res.data:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return res.data

def marcar_usuario_visto(id_usuario: int) -> dict:
    """Marca al usuario como no nuevo después de ver el onboarding."""
    db = get_client()
    res = db.table("usuario") \
            .update({"es_nuevo": False}) \
            .eq("id", id_usuario) \
            .execute()
    return {"es_nuevo": False}