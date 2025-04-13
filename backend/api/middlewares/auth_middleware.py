from functools import wraps
from flask import request, jsonify, g
import jwt
from utils.auth import extract_token_from_header, decode_token
from services.user_service import UserService

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
            return jsonify({'error': 'Token de autenticación no proporcionado'}), 401
            
        try:
            payload = decode_token(token)
            
            if payload.get('type') != 'access':
                return jsonify({'error': 'Tipo de token inválido'}), 401
                
            user = user_service.get_user_by_nickname(payload['sub'])
            
            if not user:
                return jsonify({'error': 'Usuario no encontrado'}), 401
                
            g.user = user
            g.user_id = payload['id']
            g.user_role = payload['role']
            
            return f(*args, **kwargs)
            
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token expirado'}), 401
            
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Token inválido'}), 401
            
    return decorated_function

def admin_required(f):
    """
    Decorador para requerir que el usuario sea administrador.
    
    Debe usarse después del decorador jwt_required.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not hasattr(g, 'user_role') or g.user_role != 'admin':
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
            return jsonify({'error': 'Token de refresco no proporcionado'}), 401
            
        try:
            payload = decode_token(token)
            
            if payload.get('type') != 'refresh':
                return jsonify({'error': 'Tipo de token inválido'}), 401
                
            user = user_service.get_user_by_nickname(payload['sub'])
            
            if not user:
                return jsonify({'error': 'Usuario no encontrado'}), 401
                
            g.user = user
            
            return f(*args, **kwargs)
            
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token de refresco expirado'}), 401
            
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Token de refresco inválido'}), 401
            
    return decorated_function