import jwt
import datetime
from config.settings import JWT_SECRET_KEY, JWT_ALGORITHM, JWT_ACCESS_TOKEN_EXPIRES, JWT_REFRESH_TOKEN_EXPIRES

def generate_access_token(user):
    """
    Genera un token JWT de acceso para un usuario.
    
    Args:
        user (dict): Información del usuario
        
    Returns:
        str: Token JWT generado
    """
    payload = {
        'sub': user['nickName'],
        'id': user['id'],
        'role': user['role_name'],
        'iat': datetime.datetime.utcnow(),
        'exp': datetime.datetime.utcnow() + JWT_ACCESS_TOKEN_EXPIRES,
        'type': 'access'
    }
    
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

def generate_refresh_token(user):
    """
    Genera un token JWT de refresco para un usuario.
    
    Args:
        user (dict): Información del usuario
        
    Returns:
        str: Token JWT de refresco generado
    """
    payload = {
        'sub': user['nickName'],
        'id': user['id'],
        'iat': datetime.datetime.utcnow(),
        'exp': datetime.datetime.utcnow() + JWT_REFRESH_TOKEN_EXPIRES,
        'type': 'refresh'
    }
    
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

def decode_token(token):
    """
    Decodifica y verifica un token JWT.
    
    Args:
        token (str): Token JWT a decodificar
        
    Returns:
        dict: Payload del token si es válido
        
    Raises:
        jwt.ExpiredSignatureError: Si el token ha expirado
        jwt.InvalidTokenError: Si el token es inválido por cualquier otra razón
    """
    return jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])

def extract_token_from_header(auth_header):
    """
    Extrae el token JWT de la cabecera de autorización.
    
    Args:
        auth_header (str): Cabecera de autorización
        
    Returns:
        str: Token JWT sin el prefijo 'Bearer ' o None si no se encuentra
    """
    if not auth_header or not auth_header.startswith('Bearer '):
        return None
        
    return auth_header.split(' ')[1]