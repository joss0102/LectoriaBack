from flask import Blueprint, jsonify, request
from services.reading_service import ReadingService
from datetime import datetime

reading_bp = Blueprint('reading_bp', __name__)
reading_service = ReadingService()

@reading_bp.route('/progress/<string:user_nickname>', methods=['GET'])
def get_reading_progress(user_nickname):
    """
    Obtiene el progreso de lectura de un usuario.
    
    Query params:
    - book_title: Título del libro (opcional)
    - page: Número de página (predeterminado: 1)
    - page_size: Tamaño de página (predeterminado: 10)
    """
    book_title = request.args.get('book_title')
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 10))
    
    progress = reading_service.get_reading_progress(user_nickname, book_title, page, page_size)
    
    if progress:
        return jsonify(progress)
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
    Obtiene reseñas de libros con paginación.
    
    Query params:
    - book_title: Título del libro (opcional)
    - user_nickname: Nickname del usuario (opcional)
    - page: Número de página (predeterminado: 1)
    - page_size: Tamaño de página (predeterminado: 10)
    """
    book_title = request.args.get('book_title')
    user_nickname = request.args.get('user_nickname')
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 10))
    
    reviews = reading_service.get_book_reviews(book_title, user_nickname, page, page_size)
    
    return jsonify(reviews)

@reading_bp.route('/reviews/<int:review_id>', methods=['GET'])
def get_review_by_id(review_id):
    """
    Obtiene una reseña específica por su ID.
    """
    review = reading_service.get_review_by_id(review_id)
    
    if review:
        return jsonify(review)
    else:
        return jsonify({"error": "Reseña no encontrada"}), 404

@reading_bp.route('/reviews', methods=['POST'])
def add_review():
    """
    Añade una nueva reseña para un libro.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    required_fields = ['user_nickname', 'book_title', 'text', 'rating']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Campo requerido: {field}"}), 400
    
    # Extraer campos del JSON
    user_nickname = data.get('user_nickname')
    book_title = data.get('book_title')
    text = data.get('text')
    rating = data.get('rating')
    
    # Validar rating
    try:
        rating = float(rating)
        if rating < 1 or rating > 10:
            return jsonify({"error": "La calificación debe estar entre 1 y 10"}), 400
    except ValueError:
        return jsonify({"error": "La calificación debe ser un número"}), 400
    
    result = reading_service.add_review(user_nickname, book_title, text, rating)
    
    if result:
        return jsonify({"message": "Reseña añadida correctamente", "data": result}), 201
    else:
        return jsonify({"error": "Error al añadir la reseña"}), 500

@reading_bp.route('/reviews/<int:review_id>', methods=['PUT'])
def update_review(review_id):
    """
    Actualiza una reseña existente.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    # Verificar que la reseña existe
    existing_review = reading_service.get_review_by_id(review_id)
    if not existing_review:
        return jsonify({"error": f"Reseña con ID {review_id} no encontrada"}), 404
    
    # Extraer campos del JSON
    text = data.get('text')
    rating = data.get('rating')
    
    # Validar rating si está presente
    if rating is not None:
        try:
            rating = float(rating)
            if rating < 1 or rating > 10:
                return jsonify({"error": "La calificación debe estar entre 1 y 10"}), 400
        except ValueError:
            return jsonify({"error": "La calificación debe ser un número"}), 400
    
    result = reading_service.update_review(review_id, text, rating)
    
    if result:
        return jsonify({"message": "Reseña actualizada correctamente", "data": result})
    else:
        return jsonify({"error": "Error al actualizar la reseña"}), 500

@reading_bp.route('/reviews/<int:review_id>', methods=['DELETE'])
def delete_review(review_id):
    """
    Elimina una reseña.
    """
    # Verificar que la reseña existe
    existing_review = reading_service.get_review_by_id(review_id)
    if not existing_review:
        return jsonify({"error": f"Reseña con ID {review_id} no encontrada"}), 404
    
    result = reading_service.delete_review(review_id)
    
    if result:
        return jsonify({"message": f"Reseña con ID {review_id} eliminada correctamente"})
    else:
        return jsonify({"error": "Error al eliminar la reseña"}), 500

@reading_bp.route('/stats/<string:user_nickname>', methods=['GET'])
def get_user_reading_stats(user_nickname):
    """
    Obtiene estadísticas de lectura para un usuario.
    """
    stats = reading_service.get_user_reading_stats(user_nickname)
    
    if stats:
        return jsonify(stats)
    else:
        return jsonify({"error": "No se encontraron estadísticas para el usuario"}), 404

@reading_bp.route('/progress/<string:user_nickname>/book/<int:book_id>', methods=['DELETE'])
def delete_reading_progress(user_nickname, book_id):
    """
    Elimina el progreso de lectura de un libro específico para un usuario.
    """
    result = reading_service.delete_reading_progress(user_nickname, book_id)
    
    if result:
        return jsonify({"message": f"Progreso de lectura eliminado correctamente"})
    else:
        return jsonify({"error": "Error al eliminar el progreso de lectura"}), 500

@reading_bp.route('/phrases', methods=['GET'])
def get_phrases():
    """
    Obtiene frases destacadas con paginación.
    
    Query params:
    - book_title: Título del libro (opcional)
    - user_nickname: Nickname del usuario (opcional)
    - page: Número de página (predeterminado: 1)
    - page_size: Tamaño de página (predeterminado: 10)
    """
    book_title = request.args.get('book_title')
    user_nickname = request.args.get('user_nickname')
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 10))
    
    phrases = reading_service.get_phrases(book_title, user_nickname, page, page_size)
    
    return jsonify(phrases)

@reading_bp.route('/phrases', methods=['POST'])
def add_phrase():
    """
    Añade una nueva frase destacada para un libro.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    required_fields = ['user_nickname', 'book_title', 'text']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Campo requerido: {field}"}), 400
    
    # Extraer campos del JSON
    user_nickname = data.get('user_nickname')
    book_title = data.get('book_title')
    text = data.get('text')
    
    result = reading_service.add_phrase(user_nickname, book_title, text)
    
    if result:
        return jsonify({"message": "Frase destacada añadida correctamente", "data": result}), 201
    else:
        return jsonify({"error": "Error al añadir la frase destacada"}), 500

@reading_bp.route('/phrases/<int:phrase_id>', methods=['PUT'])
def update_phrase(phrase_id):
    """
    Actualiza una frase destacada existente.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    # Verificar que la frase existe
    existing_phrase = reading_service.get_phrase_by_id(phrase_id)
    if not existing_phrase:
        return jsonify({"error": f"Frase destacada con ID {phrase_id} no encontrada"}), 404
    
    # Extraer campos del JSON
    text = data.get('text')
    
    if not text:
        return jsonify({"error": "El texto de la frase es requerido"}), 400
    
    result = reading_service.update_phrase(phrase_id, text)
    
    if result:
        return jsonify({"message": "Frase destacada actualizada correctamente", "data": result})
    else:
        return jsonify({"error": "Error al actualizar la frase destacada"}), 500

@reading_bp.route('/phrases/<int:phrase_id>', methods=['DELETE'])
def delete_phrase(phrase_id):
    """
    Elimina una frase destacada.
    """
    # Verificar que la frase existe
    existing_phrase = reading_service.get_phrase_by_id(phrase_id)
    if not existing_phrase:
        return jsonify({"error": f"Frase destacada con ID {phrase_id} no encontrada"}), 404
    
    result = reading_service.delete_phrase(phrase_id)
    
    if result:
        return jsonify({"message": f"Frase destacada con ID {phrase_id} eliminada correctamente"})
    else:
        return jsonify({"error": "Error al eliminar la frase destacada"}), 500

@reading_bp.route('/notes', methods=['GET'])
def get_notes():
    """
    Obtiene notas de libros con paginación.
    
    Query params:
    - book_title: Título del libro (opcional)
    - user_nickname: Nickname del usuario (opcional)
    - page: Número de página (predeterminado: 1)
    - page_size: Tamaño de página (predeterminado: 10)
    """
    book_title = request.args.get('book_title')
    user_nickname = request.args.get('user_nickname')
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 10))
    
    notes = reading_service.get_notes(book_title, user_nickname, page, page_size)
    
    return jsonify(notes)

@reading_bp.route('/notes', methods=['POST'])
def add_note():
    """
    Añade una nueva nota para un libro.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    required_fields = ['user_nickname', 'book_title', 'text']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Campo requerido: {field}"}), 400
    
    # Extraer campos del JSON
    user_nickname = data.get('user_nickname')
    book_title = data.get('book_title')
    text = data.get('text')
    
    result = reading_service.add_note(user_nickname, book_title, text)
    
    if result:
        return jsonify({"message": "Nota añadida correctamente", "data": result}), 201
    else:
        return jsonify({"error": "Error al añadir la nota"}), 500

@reading_bp.route('/notes/<int:note_id>', methods=['PUT'])
def update_note(note_id):
    """
    Actualiza una nota existente.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    # Verificar que la nota existe
    existing_note = reading_service.get_note_by_id(note_id)
    if not existing_note:
        return jsonify({"error": f"Nota con ID {note_id} no encontrada"}), 404
    
    # Extraer campos del JSON
    text = data.get('text')
    
    if not text:
        return jsonify({"error": "El texto de la nota es requerido"}), 400
    
    result = reading_service.update_note(note_id, text)
    
    if result:
        return jsonify({"message": "Nota actualizada correctamente", "data": result})
    else:
        return jsonify({"error": "Error al actualizar la nota"}), 500

@reading_bp.route('/notes/<int:note_id>', methods=['DELETE'])
def delete_note(note_id):
    """
    Elimina una nota.
    """
    # Verificar que la nota existe
    existing_note = reading_service.get_note_by_id(note_id)
    if not existing_note:
        return jsonify({"error": f"Nota con ID {note_id} no encontrada"}), 404
    
    result = reading_service.delete_note(note_id)
    
    if result:
        return jsonify({"message": f"Nota con ID {note_id} eliminada correctamente"})
    else:
        return jsonify({"error": "Error al eliminar la nota"}), 500