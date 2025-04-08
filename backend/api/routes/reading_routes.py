from flask import Blueprint, jsonify, request
from services.reading_service import ReadingService

reading_bp = Blueprint('reading_bp', __name__)
reading_service = ReadingService()

@reading_bp.route('/progress/<string:user_nickname>', methods=['GET'])
def get_reading_progress(user_nickname):
    """
    Obtiene el progreso de lectura de un usuario.
    
    Query params:
    - book_title: Título del libro (opcional)
    """
    book_title = request.args.get('book_title')
    progress = reading_service.get_reading_progress(user_nickname, book_title)
    
    if progress:
        return jsonify({"data": progress})
    else:
        return jsonify({"error": "No se encontró progreso de lectura"}), 404

@reading_bp.route('/progress', methods=['POST'])
def add_reading_progress():
    """
    Añade progreso de lectura para un usuario y un libro.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    required_fields = ['nickname', 'book_title', 'pages_read_list', 'dates_list']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Campo requerido: {field}"}), 400
    
    # Extraer campos del JSON
    nickname = data.get('nickname')
    book_title = data.get('book_title')
    pages_read_list = data.get('pages_read_list')
    dates_list = data.get('dates_list')
    
    result = reading_service.add_reading_progress(nickname, book_title, pages_read_list, dates_list)
    
    if result:
        return jsonify({"message": "Progreso de lectura añadido correctamente", "data": result}), 201
    else:
        return jsonify({"error": "Error al añadir el progreso de lectura"}), 500

@reading_bp.route('/reviews', methods=['GET'])
def get_book_reviews():
    """
    Obtiene reseñas de libros.
    
    Query params:
    - book_title: Título del libro (opcional)
    - user_nickname: Nickname del usuario (opcional)
    """
    book_title = request.args.get('book_title')
    user_nickname = request.args.get('user_nickname')
    
    reviews = reading_service.get_book_reviews(book_title, user_nickname)
    
    return jsonify({"data": reviews})