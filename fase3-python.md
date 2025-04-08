### 8. Implementación del Servicio de Libros
Archivo: `backend/services/book_service.py`

```python
from models.book import BookModel

class BookService:
    """
    Servicio para operaciones relacionadas con libros.
    Implementa la lógica de negocio.
    """
    def __init__(self):
        self.book_model = BookModel()
    
    def get_all_books(self, page=1, page_size=10):
        """
        Obtiene todos los libros con paginación.
        
        Args:
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Resultado con libros y metadatos de paginación
        """
        books = self.book_model.get_all_books(page, page_size)
        
        # Contar el total de libros para la paginación
        count_query = "SELECT COUNT(*) as total FROM vw_book_complete_info"
        total_count = self.book_model.db.execute_query(count_query)[0]['total']
        
        return {
            'data': books,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_items': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }
    
    def get_book_by_id(self, book_id):
        """
        Obtiene un libro por su ID.
        
        Args:
            book_id (int): ID del libro
            
        Returns:
            dict: Información del libro o None si no existe
        """
        return self.book_model.get_book_by_id(book_id)
    
    def search_books(self, search_term=None, genre=None, author=None, page=1, page_size=10):
        """
        Busca libros por término, género o autor.
        
        Args:
            search_term (str, optional): Término a buscar. Default is None.
            genre (str, optional): Género a buscar. Default is None.
            author (str, optional): Autor a buscar. Default is None.
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Resultado con libros y metadatos de paginación
        """
        query_conditions = []
        query_params = []
        
        if search_term:
            query_conditions.append("(book_title LIKE %s OR authors LIKE %s OR genres LIKE %s)")
            query_params.extend([f"%{search_term}%", f"%{search_term}%", f"%{search_term}%"])
        
        if genre:
            query_conditions.append("genres LIKE %s")
            query_params.append(f"%{genre}%")
        
        if author:
            query_conditions.append("authors LIKE %s")
            query_params.append(f"%{author}%")
        
        # Construir la consulta
        query = "SELECT * FROM vw_book_complete_info"
        count_query = "SELECT COUNT(*) as total FROM vw_book_complete_info"
        
        if query_conditions:
            where_clause = " WHERE " + " AND ".join(query_conditions)
            query += where_clause
            count_query += where_clause
        
        # Añadir paginación
        query += " LIMIT %s OFFSET %s"
        offset = (page - 1) * page_size
        query_params.extend([page_size, offset])
        
        # Ejecutar consultas
        books = self.book_model.db.execute_query(query, query_params)
        total_count = self.book_model.db.execute_query(count_query, query_params[:-2])[0]['total']
        
        return {
            'data': books,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_items': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }
```
### 9. Configuración de la API REST con Flask
Archivo: `backend/api/app.py`

```python
from flask import Flask, jsonify
from flask_cors import CORS
from config.settings import API_HOST, API_PORT, DEBUG_MODE

# Importar rutas
from api.routes.book_routes import book_bp

app = Flask(__name__)
CORS(app)  # Habilitar CORS para toda la aplicación

# Registrar blueprints (rutas)
app.register_blueprint(book_bp, url_prefix='/api/books')

@app.route('/')
def index():
    return jsonify({
        "message": "Bienvenido a la API de TFG2",
        "version": "1.0"
    })

def start_api():
    app.run(host=API_HOST, port=API_PORT, debug=DEBUG_MODE)

if __name__ == "__main__":
    start_api()
```
### Implementación de Rutas para Libros
Archivo: `backend/api/routes/book_routes.py`

```python
from flask import Blueprint, jsonify, request
from services.book_service import BookService

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
```

### 11. Archivo Principal
Archivo: `backend/main.py`

```python
from api.app import start_api

if __name__ == "__main__":
    print("Iniciando la API TFG2...")
    start_api()
```
## Cómo Ejecutar la Aplicación

1. Instalar las dependencias:

```bash
pip install -r backend/requirements.txt
```
2. Configura tu archivo .env con las credenciales correctas de la base de datos.
3. Ejecuta la aplicación:

```bash	
python backend/main.py
```
4. Accede a la API en http://localhost:5000/
## Próximos Pasos
A medida que te familiarices con la estructura básica, puedes:

1. Implementar más rutas en api/routes/ para usuarios y lecturas.
2. Añadir autenticación con JWT.
3. Implementar validación de datos con bibliotecas como Pydantic.
4. Desarrollar el frontend con Angular para conectarlo con esta API.