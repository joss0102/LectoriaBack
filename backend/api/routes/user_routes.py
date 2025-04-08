from flask import Blueprint, jsonify, request
from services.user_service import UserService

user_bp = Blueprint('user_bp', __name__)
user_service = UserService()

@user_bp.route('/', methods=['GET'])
def get_users():
    """
    Obtiene todos los usuarios.
    """
    users = user_service.get_all_users()
    return jsonify({"data": users})

@user_bp.route('/<string:nickname>', methods=['GET'])
def get_user(nickname):
    """
    Obtiene un usuario por su nickname.
    """
    user = user_service.get_user_by_nickname(nickname)
    
    if user:
        return jsonify(user)
    else:
        return jsonify({"error": "Usuario no encontrado"}), 404

@user_bp.route('/<string:nickname>/stats', methods=['GET'])
def get_user_stats(nickname):
    """
    Obtiene estadísticas de lectura de un usuario.
    """
    stats = user_service.get_user_reading_stats(nickname)
    
    if stats:
        return jsonify(stats)
    else:
        return jsonify({"error": "Estadísticas no encontradas"}), 404

@user_bp.route('/<string:nickname>/books', methods=['GET'])
def get_user_books(nickname):
    """
    Obtiene la lista de libros de un usuario.
    """
    books = user_service.get_user_reading_list(nickname)
    
    if books:
        return jsonify({"data": books})
    else:
        return jsonify({"error": "No se encontraron libros para este usuario"}), 404

@user_bp.route('/', methods=['POST'])
def add_user():
    """
    Añade un nuevo usuario.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    required_fields = ['name', 'nickname', 'password', 'role_name', 'union_date']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Campo requerido: {field}"}), 400
    
    # Extraer campos del JSON
    name = data.get('name')
    last_name1 = data.get('last_name1', '')
    last_name2 = data.get('last_name2', '')
    birthdate = data.get('birthdate')
    union_date = data.get('union_date')
    nickname = data.get('nickname')
    password = data.get('password')
    role_name = data.get('role_name')
    
    result = user_service.add_user(name, last_name1, last_name2, birthdate, union_date, nickname, password, role_name)
    
    if result:
        return jsonify({"message": "Usuario añadido correctamente", "data": result}), 201
    else:
        return jsonify({"error": "Error al añadir el usuario"}), 500