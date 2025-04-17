import jwt
import datetime
import logging
from config.settings import JWT_SECRET_KEY, JWT_ALGORITHM, JWT_ACCESS_TOKEN_EXPIRES, JWT_REFRESH_TOKEN_EXPIRES
from functools import lru_cache

logger = logging.getLogger('auth')

def generate_access_token(user):
    """
    Genera un token JWT de acceso para un usuario.
    
    Args:
        user (dict): Información del usuario
        
    Returns:
        str: Token JWT generado
    """
    try:
        payload = {
            'sub': user['nickName'],
            'id': user['id'],
            'role': user['role_name'],
            'iat': datetime.datetime.utcnow(),
            'exp': datetime.datetime.utcnow() + JWT_ACCESS_TOKEN_EXPIRES,
            'type': 'access'
        }
        
        return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    except Exception as e:
        logger.error(f"Error al generar access token: {e}")
        raise

def generate_refresh_token(user):
    """
    Genera un token JWT de refresco para un usuario.
    
    Args:
        user (dict): Información del usuario
        
    Returns:
        str: Token JWT de refresco generado
    """
    try:
        payload = {
            'sub': user['nickName'],
            'id': user['id'],
            'iat': datetime.datetime.utcnow(),
            'exp': datetime.datetime.utcnow() + JWT_REFRESH_TOKEN_EXPIRES,
            'type': 'refresh'
        }
        
        return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    except Exception as e:
        logger.error(f"Error al generar refresh token: {e}")
        raise


_token_cache = {}

def decode_token(token):
    """
    Decodifica y verifica un token JWT.
    
    Args:
        token (str): Token JWT a decodificar
        
    Returns:
        dict: Payload del token si es válido
    """
    if token in _token_cache:
        return _token_cache[token]
        
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        if len(_token_cache) > 100:  # Limitar tamaño de caché
            _token_cache.clear()  # Limpiar cuando se llena
        _token_cache[token] = payload
        return payload
    except jwt.ExpiredSignatureError:
        logger.info("Token expirado")
        raise
    except jwt.InvalidTokenError as e:
        logger.warning(f"Token inválido: {e}")
        raise

def extract_token_from_header(auth_header):
    """
    Extrae el token JWT de la cabecera de autorización.
    
    Args:
        auth_header (str): Cabecera de autorización
        
    Returns:
        str: Token JWT sin el prefijo 'Bearer ' o None si no se encuentra
    """
    if not auth_header or not isinstance(auth_header, str) or not auth_header.startswith('Bearer '):
        return None
        
    return auth_header.split(' ')[1]

def get_token_expiration(token_data):
    """
    Obtiene la fecha de expiración de un token.
    
    Args:
        token_data (dict): Datos del token decodificado
        
    Returns:
        datetime: Fecha de expiración del token
    """
    try:
        exp_timestamp = token_data.get('exp')
        if not exp_timestamp:
            return None
            
        return datetime.datetime.fromtimestamp(exp_timestamp)
    except Exception as e:
        logger.error(f"Error al obtener expiración del token: {e}")
        return None

def is_token_expired(token_data):
    """
    Comprueba si un token ha expirado.
    
    Args:
        token_data (dict): Datos del token decodificado
        
    Returns:
        bool: True si el token ha expirado, False en caso contrario
    """
    try:
        exp_timestamp = token_data.get('exp')
        if not exp_timestamp:
            return True
            
        now = datetime.datetime.utcnow().timestamp()
        return exp_timestamp < now
    except Exception as e:
        logger.error(f"Error al comprobar expiración del token: {e}")
        return True