from config.database import DatabaseConnection

class AuthorModel:
    """
    Modelo para operaciones relacionadas con autores.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_all_authors(self):
        """
        Obtiene todos los autores.
        
        Returns:
            list: Lista de autores
        """
        query = "SELECT id, name, last_name1, last_name2, description FROM author"
        return self.db.execute_query(query)
    
    def get_author_by_id(self, author_id):
        """
        Obtiene un autor por su ID.
        
        Args:
            author_id (int): ID del autor
            
        Returns:
            dict: Información del autor o None si no existe
        """
        query = "SELECT id, name, last_name1, last_name2, description FROM author WHERE id = %s"
        results = self.db.execute_query(query, [author_id])
        return results[0] if results else None
    
    def get_books_by_author(self, author_id):
        """
        Obtiene los libros de un autor específico.
        
        Args:
            author_id (int): ID del autor
            
        Returns:
            list: Lista de libros del autor
        """
        query = """
        SELECT b.id, b.title, b.pages, s.text as synopsis
        FROM book b
        JOIN book_has_author bha ON b.id = bha.id_book
        LEFT JOIN synopsis s ON b.id = s.id_book
        WHERE bha.id_author = %s
        """
        return self.db.execute_query(query, [author_id])
    
    def add_author(self, name, last_name1, last_name2, description):
        """
        Añade un nuevo autor.
        
        Args:
            name (str): Nombre del autor
            last_name1 (str): Primer apellido
            last_name2 (str): Segundo apellido
            description (str): Descripción o biografía
            
        Returns:
            dict: Resultado de la operación
        """
        params = [name, last_name1, last_name2, description]
        return self.db.call_procedure("add_author_full", params)