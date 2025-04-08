from config.database import DatabaseConnection

class ReadingModel:
    """
    Modelo para operaciones relacionadas con la lectura y progreso.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_reading_progress(self, user_nickname, book_title=None):
        """
        Obtiene el progreso de lectura de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str, optional): Título del libro. Default is None.
            
        Returns:
            list: Progreso de lectura del usuario
        """
        if book_title:
            query = "SELECT * FROM vw_reading_progress_detailed WHERE user_nickname = %s AND book_title = %s ORDER BY reading_date"
            return self.db.execute_query(query, [user_nickname, book_title])
        else:
            query = "SELECT * FROM vw_reading_progress_detailed WHERE user_nickname = %s ORDER BY reading_date"
            return self.db.execute_query(query, [user_nickname])
    
    def add_reading_progress(self, nickname, book_title, pages_read_list, dates_list):
        """
        Añade progreso de lectura para un usuario y un libro.
        
        Args:
            nickname (str): Nickname del usuario
            book_title (str): Título del libro
            pages_read_list (str): Lista de páginas leídas separadas por comas
            dates_list (str): Lista de fechas correspondientes separadas por comas
            
        Returns:
            dict: Resultado de la operación
        """
        params = [nickname, book_title, pages_read_list, dates_list]
        return self.db.call_procedure("add_reading_progress_full", params)
    
    def get_book_reviews(self, book_title=None, user_nickname=None):
        """
        Obtiene reseñas de libros.
        
        Args:
            book_title (str, optional): Título del libro. Default is None.
            user_nickname (str, optional): Nickname del usuario. Default is None.
            
        Returns:
            list: Reseñas que coinciden con los criterios
        """
        if book_title and user_nickname:
            query = "SELECT * FROM vw_book_reviews WHERE book_title = %s AND user_nickname = %s"
            return self.db.execute_query(query, [book_title, user_nickname])
        elif book_title:
            query = "SELECT * FROM vw_book_reviews WHERE book_title = %s"
            return self.db.execute_query(query, [book_title])
        elif user_nickname:
            query = "SELECT * FROM vw_book_reviews WHERE user_nickname = %s"
            return self.db.execute_query(query, [user_nickname])
        else:
            query = "SELECT * FROM vw_book_reviews"
            return self.db.execute_query(query)