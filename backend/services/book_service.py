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