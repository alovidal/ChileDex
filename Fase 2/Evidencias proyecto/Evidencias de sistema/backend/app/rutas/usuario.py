from fastapi import APIRouter, UploadFile, File
from app.modelos.usuario import LoginRequest, RecuperarRequest, RegistroRequest, EditarPerfilRequest, RestablecerRequest, UsuarioResponse
from app.servicios import usuario_servicio as svc
from app.servicios import storage_servicios as storage_servicio

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])

@router.post("/login")
def login(body: LoginRequest):
    return svc.login(body.correo, body.contrasena)

@router.post("/registro", status_code=201)
def registro(body: RegistroRequest):
    return svc.registrar(body)

@router.post("/recuperar")
def recuperar(body: RecuperarRequest):
    return svc.buscar_correo(body.correo)

@router.post("/restablecer")
def restablecer(body: RestablecerRequest):
    return svc.restablecer_contrasena(
        body.correo,
        body.nueva_contrasena,
        body.token,           
    )

@router.put("/{id_usuario}")
def editar_perfil(id_usuario: int, body: EditarPerfilRequest):
    return svc.editar_perfil(id_usuario, body)

@router.get("/{usuario_id}/perfil", response_model=UsuarioResponse)
def obtener_perfil(usuario_id: int):
    return svc.obtener_perfil(usuario_id)

@router.post("/{id_usuario}/foto-perfil")
async def subir_foto(id_usuario: int, archivo: UploadFile = File(...)):
    url = await storage_servicio.subir_foto_perfil(id_usuario, archivo)
    return {"foto_perfil_url": url}

@router.post("/{id_usuario}/marcar-visto")
def marcar_visto(id_usuario: int):
    return svc.marcar_usuario_visto(id_usuario)