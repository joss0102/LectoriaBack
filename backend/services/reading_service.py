from models.reading import ReadingModel

class ReadingService:
    """
    Servicio para operaciones relacionadas con la lectura y progreso.
    Implementa la lógica de negocio.
    """
    def __init__(self):
        self.reading_model = ReadingModel()
    
    def get_reading_progress(self, user_nickname, book_title=None, page=1, page_size=10):
        """
        Obtiene el progreso de lectura de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str, optional): Título del libro. Default is None.
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Progreso de lectura del usuario con metadatos de paginación
        """
        return self.reading_model.get_reading_progress(user_nickname, book_title, page, page_size)
    
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
    
    def delete_reading_progress(self, user_nickname, book_id):
        """
        Elimina el progreso de lectura de un libro específico para un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_id (int): ID del libro
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        return self.reading_model.delete_reading_progress(user_nickname, book_id)
    
    def get_progress_by_id(self, progress_id):
        """
        Obtiene un registro de progreso de lectura por su ID.
        
        Args:
            progress_id (int): ID del registro de progreso
            
        Returns:
            dict: Información del progreso o None si no existe
        """
        return self.reading_model.get_progress_by_id(progress_id)

    def update_reading_progress(self, progress_id, pages=None, date=None):
        """
        Actualiza un registro de progreso de lectura existente.
        
        Args:
            progress_id (int): ID del registro de progreso a actualizar
            pages (int, optional): Nuevo número de páginas leídas
            date (str, optional): Nueva fecha de lectura (formato YYYY-MM-DD)
            
        Returns:
            dict: Información del progreso actualizado o None si hubo un error
        """
        return self.reading_model.update_reading_progress(progress_id, pages, date)
    def get_book_reviews(self, book_title=None, user_nickname=None, page=1, page_size=10):
        """
        Obtiene reseñas de libros.
        
        Args:
            book_title (str, optional): Título del libro. Default is None.
            user_nickname (str, optional): Nickname del usuario. Default is None.
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Reseñas que coinciden con los criterios con metadatos de paginación
        """
        return self.reading_model.get_book_reviews(book_title, user_nickname, page, page_size)
    
    def get_review_by_id(self, review_id):
        """
        Obtiene una reseña específica por su ID.
        
        Args:
            review_id (int): ID de la reseña
            
        Returns:
            dict: Información de la reseña o None si no existe
        """
        return self.reading_model.get_review_by_id(review_id)
    
    def add_review(self, user_nickname, book_title, text, rating):
        """
        Añade una nueva reseña para un libro.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str): Título del libro
            text (str): Texto de la reseña
            rating (float): Calificación (1-10)
            
        Returns:
            dict: Información de la reseña creada o None si hubo un error
        """
        return self.reading_model.add_review(user_nickname, book_title, text, rating)
    
    def update_review(self, review_id, text=None, rating=None):
        """
        Actualiza una reseña existente.
        
        Args:
            review_id (int): ID de la reseña a actualizar
            text (str, optional): Nuevo texto de la reseña
            rating (float, optional): Nueva calificación
            
        Returns:
            dict: Información de la reseña actualizada o None si hubo un error
        """
        return self.reading_model.update_review(review_id, text, rating)
    
    def delete_review(self, review_id):
        """
        Elimina una reseña por su ID.
        
        Args:
            review_id (int): ID de la reseña a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        return self.reading_model.delete_review(review_id)
    
    def get_user_reading_stats(self, user_nickname):
        """
        Obtiene estadísticas de lectura para un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            dict: Estadísticas de lectura del usuario o None si no existe
        """
        return self.reading_model.get_user_reading_stats(user_nickname)
    
    def get_phrases(self, book_title=None, user_nickname=None, page=1, page_size=10):
        """
        Obtiene frases destacadas con paginación.
        
        Args:
            book_title (str, optional): Título del libro. Default is None.
            user_nickname (str, optional): Nickname del usuario. Default is None.
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Frases destacadas que coinciden con los criterios con metadatos de paginación
        """
        return self.reading_model.get_phrases(book_title, user_nickname, page, page_size)
    
    def get_phrase_by_id(self, phrase_id):
        """
        Obtiene una frase destacada específica por su ID.
        
        Args:
            phrase_id (int): ID de la frase
            
        Returns:
            dict: Información de la frase o None si no existe
        """
        return self.reading_model.get_phrase_by_id(phrase_id)
    
    def add_phrase(self, user_nickname, book_title, text):
        """
        Añade una nueva frase destacada para un libro.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str): Título del libro
            text (str): Texto de la frase
            
        Returns:
            dict: Información de la frase creada o None si hubo un error
        """
        return self.reading_model.add_phrase(user_nickname, book_title, text)
    
    def update_phrase(self, phrase_id, text):
        """
        Actualiza una frase destacada existente.
        
        Args:
            phrase_id (int): ID de la frase a actualizar
            text (str): Nuevo texto de la frase
            
        Returns:
            dict: Información de la frase actualizada o None si hubo un error
        """
        return self.reading_model.update_phrase(phrase_id, text)
    
    def delete_phrase(self, phrase_id):
        """
        Elimina una frase destacada por su ID.
        
        Args:
            phrase_id (int): ID de la frase a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        return self.reading_model.delete_phrase(phrase_id)
    
    def get_notes(self, book_title=None, user_nickname=None, page=1, page_size=10):
        """
        Obtiene notas de libros con paginación.
        
        Args:
            book_title (str, optional): Título del libro. Default is None.
            user_nickname (str, optional): Nickname del usuario. Default is None.
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Notas que coinciden con los criterios con metadatos de paginación
        """
        return self.reading_model.get_notes(book_title, user_nickname, page, page_size)
    
    def get_note_by_id(self, note_id):
        """
        Obtiene una nota específica por su ID.
        
        Args:
            note_id (int): ID de la nota
            
        Returns:
            dict: Información de la nota o None si no existe
        """
        return self.reading_model.get_note_by_id(note_id)
    
    def add_note(self, user_nickname, book_title, text):
        """
        Añade una nueva nota para un libro.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str): Título del libro
            text (str): Texto de la nota
            
        Returns:
            dict: Información de la nota creada o None si hubo un error
        """
        return self.reading_model.add_note(user_nickname, book_title, text)
    
    def update_note(self, note_id, text):
        """
        Actualiza una nota existente.
        
        Args:
            note_id (int): ID de la nota a actualizar
            text (str): Nuevo texto de la nota
            
        Returns:
            dict: Información de la nota actualizada o None si hubo un error
        """
        return self.reading_model.update_note(note_id, text)
    
    def delete_note(self, note_id):
        """
        Elimina una nota por su ID.
        
        Args:
            note_id (int): ID de la nota a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        return self.reading_model.delete_note(note_id)