from models.reading import ReadingModel

class ReadingService:
    """
    Servicio para operaciones relacionadas con la lectura y progreso.
    Implementa la lógica de negocio.
    """
    def __init__(self):
        self.reading_model = ReadingModel()
    
    def get_reading_progress(self, user_nickname, book_title=None):
        """
        Obtiene el progreso de lectura de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str, optional): Título del libro. Default is None.
            
        Returns:
            list: Progreso de lectura del usuario
        """
        return self.reading_model.get_reading_progress(user_nickname, book_title)
    
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
        return self.reading_model.add_reading_progress(nickname, book_title, pages_read_list, dates_list)
    
    def get_book_reviews(self, book_title=None, user_nickname=None):
        """
        Obtiene reseñas de libros.
        
        Args:
            book_title (str, optional): Título del libro. Default is None.
            user_nickname (str, optional): Nickname del usuario. Default is None.
            
        Returns:
            list: Reseñas que coinciden con los criterios
        """
        return self.reading_model.get_book_reviews(book_title, user_nickname)