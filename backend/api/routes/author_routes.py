from flask import Blueprint, jsonify, request
from services.author_service import AuthorService

author_bp = Blueprint('author_bp', __name__)
author_service = AuthorService()

@author_bp.route('/', methods=['GET'])
def get_authors():
    """
    Obtiene todos los autores.
    """
    authors = author_service.get_all_authors()
    return jsonify({"data": authors})

@author_bp.route('/<int:author_id>', methods=['GET'])
def get_author(author_id):
    """
    Obtiene un autor por su ID.
    """
    author = author_service.get_author_by_id(author_id)
    
    if author:
        return jsonify(author)
    else:
        return jsonify({"error": "Autor no encontrado"}), 404

@author_bp.route('/<int:author_id>/books', methods=['GET'])
def get_author_books(author_id):
    """
    Obtiene los libros de un autor específico.
    """
    books = author_service.get_books_by_author(author_id)
    
    if books:
        return jsonify({"data": books})
    else:
        return jsonify({"error": "No se encontraron libros para este autor"}), 404

@author_bp.route('/', methods=['POST'])
def add_author():
    """
    Añade un nuevo autor.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    required_fields = ['name']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Campo requerido: {field}"}), 400
    
    # Extraer campos del JSON
    name = data.get('name')
    last_name1 = data.get('last_name1', '')
    last_name2 = data.get('last_name2', '')
    description = data.get('description', '')
    
    result = author_service.add_author(name, last_name1, last_name2, description)
    
    if result:
        return jsonify({"message": "Autor añadido correctamente", "data": result}), 201
    else:
        return jsonify({"error": "Error al añadir el autor"}), 500

@author_bp.route('/<int:author_id>', methods=['PUT'])
def update_author(author_id):
    """
    Actualiza un autor existente.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
        
    # Verificar que el autor existe
    existing_author = author_service.get_author_by_id(author_id)
    if not existing_author:
        return jsonify({"error": f"Autor con ID {author_id} no encontrado"}), 404
    
    # Extraer campos del JSON
    name = data.get('name')
    last_name1 = data.get('last_name1')
    last_name2 = data.get('last_name2')
    description = data.get('description')
    
    result = author_service.update_author(author_id, name, last_name1, last_name2, description)
    
    if result:
        return jsonify({"message": "Autor actualizado correctamente", "data": result})
    else:
        return jsonify({"error": "Error al actualizar el autor"}), 500

@author_bp.route('/<int:author_id>', methods=['DELETE'])
def delete_author(author_id):
    """
    Elimina un autor.
    """
    # Verificar que el autor existe
    existing_author = author_service.get_author_by_id(author_id)
    if not existing_author:
        return jsonify({"error": f"Autor con ID {author_id} no encontrado"}), 404
        
    # Verificar si el autor tiene libros asociados
    books = author_service.get_books_by_author(author_id)
    if books:
        return jsonify({"error": "No se puede eliminar el autor porque tiene libros asociados"}), 400
    
    result = author_service.delete_author(author_id)
    
    if result:
        return jsonify({"message": f"Autor con ID {author_id} eliminado correctamente"})
    else:
        return jsonify({"error": "Error al eliminar el autor"}), 500

@author_bp.route('/search', methods=['GET'])
def search_authors():
    """
    Busca autores por nombre o apellidos.
    
    Query params:
    - query: Término de búsqueda para nombre o apellidos
    - page: Número de página (predeterminado: 1)
    - page_size: Tamaño de página (predeterminado: 10)
    """
    query = request.args.get('query', '')
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 10))
    
    results = author_service.search_authors(query, page, page_size)
    
    return jsonify(results)