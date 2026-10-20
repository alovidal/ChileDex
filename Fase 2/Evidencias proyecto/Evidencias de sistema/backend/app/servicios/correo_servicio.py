import os
import resend
from fastapi import HTTPException


resend.api_key = os.environ.get("RESEND_API_KEY")

# Dominio verificado en Resend — mientras no tengas dominio propio
# usar el sandbox: onboarding@resend.dev (solo envía a tu propio correo)
REMITENTE = "ChileDex <onboarding@resend.dev>"


def enviar_correo_recuperacion(correo_destino: str, token: str) -> None:
    """
    Envía el correo con el token de recuperación.
    El token es un código de 6 dígitos que el usuario ingresa en la app.
    """
    try:
        resend.Emails.send({
            "from":    REMITENTE,
            "to":      [correo_destino],
            "subject": "Recupera tu contraseña — ChileDex",
            "html":    _template_recuperacion(token),
        })
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error al enviar el correo: {str(e)}"
        )


def _template_recuperacion(token: str) -> str:
    """HTML del correo de recuperación."""
    return f"""
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <div style="background: #27533B; padding: 24px; border-radius: 12px 12px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 24px; text-align: center;">ChileDex</h1>
        </div>
        <div style="background: #ffffff; padding: 32px; border-radius: 0 0 12px 12px;
                    border: 1px solid #D5DCD7;">
            <h2 style="color: #1C3829; margin-top: 0;">Recupera tu contraseña</h2>
            <p style="color: #4D6357;">
                Recibimos una solicitud para restablecer tu contraseña.
                Ingresa el siguiente código en la app:
            </p>
            <div style="background: #E8ECE9; border-radius: 8px; padding: 24px;
                        text-align: center; margin: 24px 0;">
                <span style="font-size: 36px; font-weight: 900; letter-spacing: 8px;
                             color: #27533B;">{token}</span>
            </div>
            <p style="color: #4D6357; font-size: 14px;">
                Este código expira en <strong>15 minutos</strong>.
                Si no solicitaste esto, ignora este correo.
            </p>
        </div>
    </div>
    """