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
        
    def update_author(self, author_id, name=None, last_name1=None, last_name2=None, description=None):
        """
        Actualiza la información de un autor existente.
        
        Args:
            author_id (int): ID del autor a actualizar
            name (str, optional): Nuevo nombre
            last_name1 (str, optional): Nuevo primer apellido
            last_name2 (str, optional): Nuevo segundo apellido
            description (str, optional): Nueva descripción
            
        Returns:
            dict: Información del autor actualizado o None si hubo un error
        """
        return self.author_model.update_author(author_id, name, last_name1, last_name2, description)
        
    def delete_author(self, author_id):
        """
        Elimina un autor por su ID.
        
        Args:
            author_id (int): ID del autor a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        return self.author_model.delete_author(author_id)
        
    def search_authors(self, search_term, page=1, page_size=10):
        """
        Busca autores por nombre o apellidos.
        
        Args:
            search_term (str): Término de búsqueda
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Resultado con autores y metadatos de paginación
        """
        return self.author_model.search_authors(search_term, page, page_size)