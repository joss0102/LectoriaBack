from models.author import AuthorModel

class AuthorService:
    """
    Servicio para operaciones relacionadas con autores.
    Implementa la lógica de negocio.
    """
    def __init__(self):
        self.author_model = AuthorModel()
    
    def get_all_authors(self):
        """
        Obtiene todos los autores.
        
        Returns:
            list: Lista de autores
        """
        return self.author_model.get_all_authors()
    
    def get_author_by_id(self, author_id):
        """
        Obtiene un autor por su ID.
        
        Args:
            author_id (int): ID del autor
            
        Returns:
            dict: Información del autor o None si no existe
        """
        return self.author_model.get_author_by_id(author_id)
    
    def get_books_by_author(self, author_id):
        """
        Obtiene los libros de un autor específico.
        
        Args:
            author_id (int): ID del autor
            
        Returns:
            list: Lista de libros del autor
        """
        return self.author_model.get_books_by_author(author_id)
    
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
        return self.author_model.add_author(name, last_name1, last_name2, description)