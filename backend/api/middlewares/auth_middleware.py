from functools import wraps
from flask import request, jsonify, g, current_app
import jwt
import logging
from utils.auth import extract_token_from_header, decode_token
from services.user_service import UserService
from models.token import TokenModel

logger = logging.getLogger("auth")
token_model = TokenModel()

user_service = UserService()

def jwt_required(f):
    """
    Decorador para requerir un token JWT válido en las rutas.
    
    Si el token es válido, almacena la información del usuario en g.user.
    Si el token no es válido o está ausente, retorna un error 401.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        token = extract_token_from_header(auth_header)
        
        if not token:
            logger.warning(f"Token de autenticación no proporcionado: {request.path}")
            return jsonify({'error': 'Token de autenticación no proporcionado'}), 401
            
        try:
            payload = decode_token(token)
            
            if payload.get('type') != 'access':
                logger.warning(f"Tipo de token inválido: {payload.get('type')}")
                return jsonify({'error': 'Tipo de token inválido'}), 401
            
            # Verificar si el token está en la lista negra
            if token_model.is_token_revoked(payload):
                logger.warning(f"Token revocado utilizado: {request.path}")
                return jsonify({'error': 'Token revocado'}), 401
                
            # Usar cache para reducir consultas a la base de datos
            # Si ya tenemos el usuario en g, no es necesario buscarlo de nuevo
            if hasattr(g, 'user') and g.user and g.user.get('nickName') == payload['sub']:
                user = g.user
            else:
                user = user_service.get_user_by_nickname(payload['sub'])
            
            if not user:
                logger.warning(f"Usuario no encontrado: {payload['sub']}")
                return jsonify({'error': 'Usuario no encontrado'}), 401
                
            g.user = user
            g.user_id = payload['id']
            g.user_role = payload['role']
            
            return f(*args, **kwargs)
            
        except jwt.ExpiredSignatureError:
            logger.warning(f"Token expirado: {request.path}")
            return jsonify({'error': 'Token expirado'}), 401
            
        except jwt.InvalidTokenError as e:
            logger.warning(f"Token inválido: {e}")
            return jsonify({'error': 'Token inválido'}), 401
        
        except Exception as e:
            logger.error(f"Error en el middleware de autenticación: {e}")
            return jsonify({'error': 'Error de autenticación'}), 401
            
    return decorated_function

def admin_required(f):
    """
    Decorador para requerir que el usuario sea administrador.
    
    Debe usarse después del decorador jwt_required.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not hasattr(g, 'user_role') or g.user_role != 'admin':
            logger.warning(f"Intento de acceso a ruta de administrador por usuario sin privilegios: {request.path}")
            return jsonify({'error': 'Se requieren privilegios de administrador'}), 403
            
        return f(*args, **kwargs)
        
    return decorated_function

def refresh_token_required(f):
    """
    Decorador para requerir un token de refresco válido.
    
    Si el token es válido, almacena la información del usuario en g.user.
    Si el token no es válido o está ausente, retorna un error 401.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        token = extract_token_from_header(auth_header)
        
        if not token:
            logger.warning(f"Token de refresco no proporcionado: {request.path}")
            return jsonify({'error': 'Token de refresco no proporcionado'}), 401
            
        try:
            payload = decode_token(token)
            
            if payload.get('type') != 'refresh':
                logger.warning(f"Tipo de token inválido para refresco: {payload.get('type')}")
                return jsonify({'error': 'Tipo de token inválido'}), 401
                
            # Verificar si el token está en la lista negra
            if token_model.is_token_revoked(payload):
                logger.warning(f"Token de refresco revocado utilizado: {request.path}")
                return jsonify({'error': 'Token revocado'}), 401
                
            user = user_service.get_user_by_nickname(payload['sub'])
            
            if not user:
                logger.warning(f"Usuario no encontrado en refresco: {payload['sub']}")
                return jsonify({'error': 'Usuario no encontrado'}), 401
                
            g.user = user
            
            return f(*args, **kwargs)
            
        except jwt.ExpiredSignatureError:
            logger.warning(f"Token de refresco expirado: {request.path}")
            return jsonify({'error': 'Token de refresco expirado'}), 401
            
        except jwt.InvalidTokenError as e:
            logger.warning(f"Token de refresco inválido: {e}")
            return jsonify({'error': 'Token de refresco inválido'}), 401
            
        except Exception as e:
            logger.error(f"Error en el middleware de refresco: {e}")
            return jsonify({'error': 'Error de autenticación en refresco'}), 401
            
    return decorated_function

def is_admin():
    """Comprueba si el usuario actual es administrador"""
    return hasattr(g, 'user_role') and g.user_role == 'admin'

def get_current_user_id():
    """Obtiene el ID del usuario actual"""
    return g.user_id if hasattr(g, 'user_id') else None

def get_current_user():
    """Obtiene la información completa del usuario actual"""
    return g.user if hasattr(g, 'user') else None