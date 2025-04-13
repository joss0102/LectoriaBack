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
    
    def add_book_full(self, title, pages, synopsis, custom_description, author_name, 
                     author_last_name1, author_last_name2, genre1, genre2, genre3, 
                     genre4, genre5, saga_name, user_nickname, status, date_added,
                     date_start, date_ending, review, rating, phrases, notes):
        """
        Añade un libro completo utilizando el procedimiento almacenado.
        
        Returns:
            dict: Resultado de la operación
        """
        return self.book_model.add_book_full(
            title, pages, synopsis, custom_description, author_name, 
            author_last_name1, author_last_name2, genre1, genre2, genre3, 
            genre4, genre5, saga_name, user_nickname, status, date_added,
            date_start, date_ending, review, rating, phrases, notes
        )
    
    def update_book(self, book_id, title=None, pages=None, synopsis=None, author_name=None, 
                   author_last_name1=None, author_last_name2=None, genre1=None, genre2=None, 
                   genre3=None, genre4=None, genre5=None, saga_name=None):
        """
        Actualiza la información básica de un libro.
        
        Args:
            book_id (int): ID del libro a actualizar
            title (str, optional): Nuevo título
            pages (int, optional): Nuevo número de páginas
            synopsis (str, optional): Nueva sinopsis
            author_name (str, optional): Nuevo nombre del autor
            author_last_name1 (str, optional): Nuevo primer apellido del autor
            author_last_name2 (str, optional): Nuevo segundo apellido del autor
            genre1-5 (str, optional): Nuevos géneros
            saga_name (str, optional): Nuevo nombre de la saga
            
        Returns:
            dict: Información del libro actualizado o None si hubo un error
        """
        return self.book_model.update_book(
            book_id, title, pages, synopsis, author_name, 
            author_last_name1, author_last_name2, genre1, genre2, 
            genre3, genre4, genre5, saga_name
        )
    
    def delete_book(self, book_id):
        """
        Elimina un libro por su ID.
        
        Args:
            book_id (int): ID del libro a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        return self.book_model.delete_book(book_id)
    
    def get_books_by_user(self, user_nickname, status=None, page=1, page_size=10):
        """
        Obtiene todos los libros asociados a un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            status (str, optional): Estado de lectura para filtrar
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Resultado con libros y metadatos de paginación
        """
        return self.book_model.get_books_by_user(user_nickname, status, page, page_size)
    
    def update_user_book_relationship(self, user_nickname, book_id, status=None, date_start=None, 
                                     date_ending=None, custom_description=None, review=None, 
                                     rating=None, phrases=None, notes=None):
        """
        Actualiza la relación entre un usuario y un libro.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_id (int): ID del libro
            status (str, optional): Nuevo estado de lectura
            date_start (str, optional): Nueva fecha de inicio de lectura
            date_ending (str, optional): Nueva fecha de finalización de lectura
            custom_description (str, optional): Nueva descripción personalizada
            review (str, optional): Nueva reseña
            rating (float, optional): Nueva calificación
            phrases (str, optional): Nuevas frases destacadas
            notes (str, optional): Nuevas notas
            
        Returns:
            bool: True si la actualización fue exitosa, False en caso contrario
        """
        result = self.book_model.update_user_book_relationship(
            user_nickname, book_id, status, date_start, date_ending,
            custom_description, review, rating, phrases, notes
        )
        
        if result:
            # Si la actualización fue exitosa, retornar los datos actualizados
            # Obtener el libro actualizado con la información del usuario
            book_info = self.book_model.get_books_by_user(user_nickname, None, 1, 1)
            
            # Filtrar para obtener solo el libro específico
            book_data = None
            if book_info and 'data' in book_info and book_info['data']:
                for book in book_info['data']:
                    if book['book_id'] == book_id:
                        book_data = book
                        break
            
            return book_data if book_data else True
        
        return False
    
    def remove_book_from_user(self, user_nickname, book_id):
        """
        Elimina un libro de la colección de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_id (int): ID del libro
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        return self.book_model.remove_book_from_user(user_nickname, book_id)