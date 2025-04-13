from flask import Blueprint, jsonify, request
from services.book_service import BookService
from datetime import datetime

book_bp = Blueprint('book_bp', __name__)
book_service = BookService()

@book_bp.route('/', methods=['GET'])
def get_books():
    """
    Obtiene todos los libros con paginación y filtros opcionales.
    
    Query params:
    - page: Número de página (predeterminado: 1)
    - page_size: Tamaño de página (predeterminado: 10)
    - search: Término de búsqueda general
    - genre: Filtro por género
    - author: Filtro por autor
    """
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 10))
    search_term = request.args.get('search')
    genre = request.args.get('genre')
    author = request.args.get('author')
    
    # Si hay algún parámetro de búsqueda o filtro
    if search_term or genre or author:
        result = book_service.search_books(search_term, genre, author, page, page_size)
    else:
        result = book_service.get_all_books(page, page_size)
    
    return jsonify(result)

@book_bp.route('/<int:book_id>', methods=['GET'])
def get_book(book_id):
    """
    Obtiene un libro por su ID.
    """
    book = book_service.get_book_by_id(book_id)
    
    if book:
        return jsonify(book)
    else:
        return jsonify({"error": "Libro no encontrado"}), 404

@book_bp.route('/', methods=['POST'])
def add_book():
    """
    Añade un nuevo libro.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    required_fields = ['title', 'pages', 'user_nickname']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Campo requerido: {field}"}), 400
    
    # Extraer todos los campos del JSON
    title = data.get('title')
    pages = data.get('pages')
    synopsis = data.get('synopsis', '')
    custom_description = data.get('custom_description', '')
    author_name = data.get('author_name', '')
    author_last_name1 = data.get('author_last_name1', '')
    author_last_name2 = data.get('author_last_name2', '')
    genre1 = data.get('genre1', '')
    genre2 = data.get('genre2', '')
    genre3 = data.get('genre3', '')
    genre4 = data.get('genre4', '')
    genre5 = data.get('genre5', '')
    saga_name = data.get('saga_name', '')
    user_nickname = data.get('user_nickname')
    status = data.get('status', 'plan_to_read')
    date_added = data.get('date_added', datetime.now().strftime('%Y-%m-%d'))
    date_start = data.get('date_start')
    date_ending = data.get('date_ending')
    review = data.get('review', '')
    rating = data.get('rating', 0)
    phrases = data.get('phrases', '')
    notes = data.get('notes', '')
    
    result = book_service.add_book_full(
        title, pages, synopsis, custom_description, author_name, 
        author_last_name1, author_last_name2, genre1, genre2, genre3, 
        genre4, genre5, saga_name, user_nickname, status, date_added,
        date_start, date_ending, review, rating, phrases, notes
    )
    
    if result:
        return jsonify({"message": "Libro añadido correctamente", "data": result}), 201
    else:
        return jsonify({"error": "Error al añadir el libro"}), 500

@book_bp.route('/<int:book_id>', methods=['PUT'])
def update_book(book_id):
    """
    Actualiza un libro existente por su ID.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    # Verificar que el libro existe
    existing_book = book_service.get_book_by_id(book_id)
    if not existing_book:
        return jsonify({"error": f"Libro con ID {book_id} no encontrado"}), 404
    
    # Extraer todos los campos del JSON que se pueden actualizar
    title = data.get('title')
    pages = data.get('pages')
    synopsis = data.get('synopsis')
    author_name = data.get('author_name')
    author_last_name1 = data.get('author_last_name1')
    author_last_name2 = data.get('author_last_name2')
    genre1 = data.get('genre1')
    genre2 = data.get('genre2')
    genre3 = data.get('genre3')
    genre4 = data.get('genre4')
    genre5 = data.get('genre5')
    saga_name = data.get('saga_name')
    
    result = book_service.update_book(
        book_id, title, pages, synopsis, author_name, 
        author_last_name1, author_last_name2, genre1, genre2, genre3, 
        genre4, genre5, saga_name
    )
    
    if result:
        return jsonify({"message": "Libro actualizado correctamente", "data": result})
    else:
        return jsonify({"error": "Error al actualizar el libro"}), 500

@book_bp.route('/<int:book_id>', methods=['DELETE'])
def delete_book(book_id):
    """
    Elimina un libro por su ID.
    """
    # Verificar que el libro existe
    existing_book = book_service.get_book_by_id(book_id)
    if not existing_book:
        return jsonify({"error": f"Libro con ID {book_id} no encontrado"}), 404
    
    result = book_service.delete_book(book_id)
    
    if result:
        return jsonify({"message": f"Libro con ID {book_id} eliminado correctamente"})
    else:
        return jsonify({"error": "Error al eliminar el libro"}), 500

@book_bp.route('/user/<string:user_nickname>', methods=['GET'])
def get_books_by_user(user_nickname):
    """
    Obtiene todos los libros de un usuario específico.
    
    Query params:
    - status: Filtrar por estado de lectura (opcional)
    - page: Número de página (predeterminado: 1)
    - page_size: Tamaño de página (predeterminado: 10)
    """
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 10))
    status = request.args.get('status')
    
    result = book_service.get_books_by_user(user_nickname, status, page, page_size)
    
    if result:
        return jsonify(result)
    else:
        return jsonify({"error": "Usuario no encontrado o sin libros"}), 404

@book_bp.route('/user/<string:user_nickname>/book/<int:book_id>', methods=['PUT'])
def update_user_book_relationship(user_nickname, book_id):
    """
    Actualiza la relación entre un usuario y un libro (estado de lectura, fechas, etc.)
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    # Extraer los campos del JSON
    status = data.get('status')
    date_start = data.get('date_start')
    date_ending = data.get('date_ending')
    custom_description = data.get('custom_description')
    review = data.get('review')
    rating = data.get('rating')
    phrases = data.get('phrases')
    notes = data.get('notes')
    
    result = book_service.update_user_book_relationship(
        user_nickname, book_id, status, date_start, date_ending,
        custom_description, review, rating, phrases, notes
    )
    
    if result:
        return jsonify({"message": "Relación usuario-libro actualizada correctamente", "data": result})
    else:
        return jsonify({"error": "Error al actualizar la relación usuario-libro"}), 500

@book_bp.route('/user/<string:user_nickname>/book/<int:book_id>', methods=['DELETE'])
def remove_book_from_user(user_nickname, book_id):
    """
    Elimina un libro de la colección de un usuario.
    """
    result = book_service.remove_book_from_user(user_nickname, book_id)
    
    if result:
        return jsonify({"message": f"Libro eliminado de la colección del usuario {user_nickname}"})
    else:
        return jsonify({"error": "Error al eliminar el libro de la colección del usuario"}), 500