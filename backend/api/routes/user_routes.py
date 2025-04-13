from flask import Blueprint, jsonify, request
from services.user_service import UserService
from datetime import datetime

user_bp = Blueprint('user_bp', __name__)
user_service = UserService()

@user_bp.route('/', methods=['GET'])
def get_users():
    """
    Obtiene todos los usuarios con paginación opcional.
    
    Query params:
    - page: Número de página (predeterminado: 1)
    - page_size: Tamaño de página (predeterminado: 10)
    - search: Término de búsqueda (opcional)
    """
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 10))
    search = request.args.get('search')
    
    users = user_service.get_all_users(page, page_size, search)
    return jsonify(users)

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
    Obtiene la lista de libros de un usuario con paginación y filtro opcional.
    
    Query params:
    - status: Estado de lectura para filtrar (opcional)
    - page: Número de página (predeterminado: 1)
    - page_size: Tamaño de página (predeterminado: 10)
    """
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 10))
    status = request.args.get('status')
    
    books = user_service.get_user_reading_list(nickname, status, page, page_size)
    
    if books:
        return jsonify(books)
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
    
    required_fields = ['name', 'nickname', 'password', 'role_name']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Campo requerido: {field}"}), 400
    
    # Extraer campos del JSON
    name = data.get('name')
    last_name1 = data.get('last_name1', '')
    last_name2 = data.get('last_name2', '')
    birthdate = data.get('birthdate')
    union_date = data.get('union_date', datetime.now().strftime('%Y-%m-%d'))
    nickname = data.get('nickname')
    password = data.get('password')
    role_name = data.get('role_name')
    
    result = user_service.add_user(name, last_name1, last_name2, birthdate, union_date, nickname, password, role_name)
    
    if result:
        return jsonify({"message": "Usuario añadido correctamente", "data": result}), 201
    else:
        return jsonify({"error": "Error al añadir el usuario"}), 500

@user_bp.route('/<string:nickname>', methods=['PUT'])
def update_user(nickname):
    """
    Actualiza un usuario existente.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    # Verificar que el usuario existe
    existing_user = user_service.get_user_by_nickname(nickname)
    if not existing_user:
        return jsonify({"error": f"Usuario con nickname {nickname} no encontrado"}), 404
    
    # Extraer campos del JSON
    name = data.get('name')
    last_name1 = data.get('last_name1')
    last_name2 = data.get('last_name2')
    birthdate = data.get('birthdate')
    role_name = data.get('role_name')
    
    result = user_service.update_user(nickname, name, last_name1, last_name2, birthdate, role_name)
    
    if result:
        return jsonify({"message": "Usuario actualizado correctamente", "data": result})
    else:
        return jsonify({"error": "Error al actualizar el usuario"}), 500

@user_bp.route('/<string:nickname>/password', methods=['PUT'])
def change_password(nickname):
    """
    Cambia la contraseña de un usuario.
    """
    data = request.get_json()
    
    if not data or 'new_password' not in data:
        return jsonify({"error": "Nueva contraseña no proporcionada"}), 400
    
    # Verificar que el usuario existe
    existing_user = user_service.get_user_by_nickname(nickname)
    if not existing_user:
        return jsonify({"error": f"Usuario con nickname {nickname} no encontrado"}), 404
    
    # Si se requiere verificación de contraseña actual
    current_password = data.get('current_password')
    if current_password:
        if not user_service.verify_password(nickname, current_password):
            return jsonify({"error": "Contraseña actual incorrecta"}), 401
    
    new_password = data.get('new_password')
    
    result = user_service.change_password(nickname, new_password)
    
    if result:
        return jsonify({"message": "Contraseña actualizada correctamente"})
    else:
        return jsonify({"error": "Error al actualizar la contraseña"}), 500

@user_bp.route('/<string:nickname>', methods=['DELETE'])
def delete_user(nickname):
    """
    Elimina un usuario.
    """
    # Verificar que el usuario existe
    existing_user = user_service.get_user_by_nickname(nickname)
    if not existing_user:
        return jsonify({"error": f"Usuario con nickname {nickname} no encontrado"}), 404
    
    result = user_service.delete_user(nickname)
    
    if result:
        return jsonify({"message": f"Usuario {nickname} eliminado correctamente"})
    else:
        return jsonify({"error": "Error al eliminar el usuario"}), 500

@user_bp.route('/login', methods=['POST'])
def login():
    """
    Autentica a un usuario.
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
    
    user = user_service.authenticate(nickname, password)
    
    if user:
        return jsonify({"message": "Autenticación exitosa", "user": user})
    else:
        return jsonify({"error": "Credenciales incorrectas"}), 401

@user_bp.route('/role/<string:role_name>/users', methods=['GET'])
def get_users_by_role(role_name):
    """
    Obtiene usuarios por rol.
    
    Query params:
    - page: Número de página (predeterminado: 1)
    - page_size: Tamaño de página (predeterminado: 10)
    """
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 10))
    
    users = user_service.get_users_by_role(role_name, page, page_size)
    
    return jsonify(users)

@user_bp.route('/roles', methods=['GET'])
def get_roles():
    """
    Obtiene todos los roles disponibles.
    """
    roles = user_service.get_all_roles()
    
    return jsonify({"data": roles})