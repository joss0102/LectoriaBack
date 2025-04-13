from flask import Blueprint, jsonify, request, g
from services.auth_service import AuthService
from utils.auth import extract_token_from_header
from api.middlewares.auth_middleware import jwt_required, refresh_token_required

auth_bp = Blueprint('auth_bp', __name__)
auth_service = AuthService()

@auth_bp.route('/login', methods=['POST'])
def login():
    """
    Autentica a un usuario y devuelve tokens de acceso y refresco.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    required_fields = ['nickname', 'password']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Campo requerido: {field}"}), 400
    
    nickname = data.get('nickname')
    password = data.get('password')
    
    result = auth_service.login(nickname, password)
    
    if result:
        return jsonify({
            "message": "Autenticación exitosa",
            "access_token": result['access_token'],
            "refresh_token": result['refresh_token'],
            "user": result['user']
        })
    else:
        return jsonify({"error": "Credenciales incorrectas"}), 401

@auth_bp.route('/refresh', methods=['POST'])
@refresh_token_required
def refresh():
    """
    Genera un nuevo token de acceso usando un token de refresco válido.
    """
    auth_header = request.headers.get('Authorization')
    refresh_token = extract_token_from_header(auth_header)
    
    try:
        result = auth_service.refresh(refresh_token)
        
        if result:
            return jsonify({
                "message": "Token refrescado exitosamente",
                "access_token": result['access_token'],
                "user": result['user']
            })
        else:
            return jsonify({"error": "No se pudo refrescar el token"}), 401
    except Exception as e:
        return jsonify({"error": str(e)}), 401

@auth_bp.route('/logout', methods=['POST'])
@jwt_required
def logout():
    """
    Revoca los tokens de acceso y refresco de un usuario.
    """
    auth_header = request.headers.get('Authorization')
    access_token = extract_token_from_header(auth_header)
    
    data = request.get_json() or {}
    refresh_token = data.get('refresh_token')
    
    result = auth_service.logout(access_token, refresh_token)
    
    if result:
        return jsonify({"message": "Sesión cerrada exitosamente"})
    else:
        return jsonify({"error": "Error al cerrar sesión"}), 500

@auth_bp.route('/verify', methods=['GET'])
@jwt_required
def verify_token():
    """
    Verifica si el token de acceso actual es válido.
    """
    return jsonify({
        "message": "Token válido",
        "user": {
            "id": g.user['id'],
            "nickname": g.user['nickName'],
            "name": g.user['name'],
            "last_name1": g.user['last_name1'],
            "last_name2": g.user['last_name2'],
            "role": g.user['role_name']
        }
    })