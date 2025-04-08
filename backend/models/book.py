from config.database import DatabaseConnection

class BookModel:
    """
    Modelo para operaciones relacionadas con libros.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_all_books(self, page=1, page_size=10):
        """
        Obtiene todos los libros con paginación.
        
        Args:
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            list: Lista de libros
        """
        offset = (page - 1) * page_size
        query = "SELECT * FROM vw_book_complete_info LIMIT %s OFFSET %s"
        return self.db.execute_query(query, [page_size, offset])
    
    def get_book_by_id(self, book_id):
        """
        Obtiene un libro por su ID.
        
        Args:
            book_id (int): ID del libro
            
        Returns:
            dict: Información del libro o None si no existe
        """
        query = "SELECT * FROM vw_book_complete_info WHERE book_id = %s"
        results = self.db.execute_query(query, [book_id])
        return results[0] if results else None
    
    def get_books_by_genre(self, genre):
        """
        Obtiene libros por género.
        
        Args:
            genre (str): Género a buscar
            
        Returns:
            list: Lista de libros que coinciden con el género
        """
        query = "SELECT * FROM vw_book_complete_info WHERE genres LIKE %s"
        return self.db.execute_query(query, [f"%{genre}%"])
    
    def get_books_by_author(self, author):
        """
        Obtiene libros por autor.
        
        Args:
            author (str): Autor a buscar
            
        Returns:
            list: Lista de libros del autor
        """
        query = "SELECT * FROM vw_book_complete_info WHERE authors LIKE %s"
        return self.db.execute_query(query, [f"%{author}%"])
    
    def add_book_full(self, title, pages, synopsis, custom_description, author_name, 
                     author_last_name1, author_last_name2, genre1, genre2, genre3, 
                     genre4, genre5, saga_name, user_nickname, status, date_added,
                     date_start, date_ending, review, rating, phrases, notes):
        """
        Añade un libro completo utilizando el procedimiento almacenado.
        
        Returns:
            dict: Resultado de la operación
        """
        params = [title, pages, synopsis, custom_description, author_name, 
                 author_last_name1, author_last_name2, genre1, genre2, genre3, 
                 genre4, genre5, saga_name, user_nickname, status, date_added,
                 date_start, date_ending, review, rating, phrases, notes]
        
        return self.db.call_procedure("add_book_full", params)