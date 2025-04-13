from models.user import UserModel

class UserService:
    """
    Servicio para operaciones relacionadas con usuarios.
    Implementa la lógica de negocio.
    """
    def __init__(self):
        self.user_model = UserModel()
    
    def get_all_users(self, page=1, page_size=10, search=None):
        """
        Obtiene todos los usuarios con paginación y búsqueda opcional.
        
        Args:
            page (int): Número de página
            page_size (int): Tamaño de la página
            search (str, optional): Término de búsqueda. Default is None.
            
        Returns:
            dict: Lista de usuarios con metadatos de paginación
        """
        return self.user_model.get_all_users(page, page_size, search)
    
    def get_user_by_nickname(self, nickname):
        """
        Obtiene un usuario por su nickname.
        
        Args:
            nickname (str): Nickname del usuario
            
        Returns:
            dict: Información del usuario o None si no existe
        """
        return self.user_model.get_user_by_nickname(nickname)
    
    def get_user_reading_stats(self, nickname):
        """
        Obtiene estadísticas de lectura de un usuario.
        
        Args:
            nickname (str): Nickname del usuario
            
        Returns:
            dict: Estadísticas de lectura del usuario
        """
        return self.user_model.get_user_reading_stats(nickname)
    
    def get_user_reading_list(self, nickname, status=None, page=1, page_size=10):
        """
        Obtiene la lista de lectura de un usuario con paginación y filtro opcional.
        
        Args:
            nickname (str): Nickname del usuario
            status (str, optional): Estado de lectura para filtrar. Default is None.
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Lista de libros del usuario con metadatos de paginación
        """
        return self.user_model.get_user_reading_list(nickname, status, page, page_size)
    
    def add_user(self, name, last_name1, last_name2, birthdate, union_date, nickname, password, role_name):
        """
        Añade un nuevo usuario.
        
        Args:
            name (str): Nombre del usuario
            last_name1 (str): Primer apellido
            last_name2 (str): Segundo apellido
            birthdate (str): Fecha de nacimiento
            union_date (str): Fecha de registro
            nickname (str): Nickname
            password (str): Contraseña
            role_name (str): Nombre del rol
            
        Returns:
            dict: Resultado de la operación
        """
        return self.user_model.add_user(name, last_name1, last_name2, birthdate, union_date, nickname, password, role_name)
    
    def update_user(self, nickname, name=None, last_name1=None, last_name2=None, birthdate=None, role_name=None):
        """
        Actualiza un usuario existente.
        
        Args:
            nickname (str): Nickname del usuario a actualizar
            name (str, optional): Nuevo nombre
            last_name1 (str, optional): Nuevo primer apellido
            last_name2 (str, optional): Nuevo segundo apellido
            birthdate (str, optional): Nueva fecha de nacimiento
            role_name (str, optional): Nuevo rol
            
        Returns:
            dict: Información del usuario actualizado o None si hubo un error
        """
        return self.user_model.update_user(nickname, name, last_name1, last_name2, birthdate, role_name)
    
    def change_password(self, nickname, new_password):
        """
        Cambia la contraseña de un usuario.
        
        Args:
            nickname (str): Nickname del usuario
            new_password (str): Nueva contraseña
            
        Returns:
            bool: True si el cambio fue exitoso, False en caso contrario
        """
        return self.user_model.change_password(nickname, new_password)
    
    def delete_user(self, nickname):
        """
        Elimina un usuario por su nickname.
        
        Args:
            nickname (str): Nickname del usuario a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        return self.user_model.delete_user(nickname)
    
    def authenticate(self, nickname, password):
        """
        Autentica a un usuario verificando sus credenciales.
        
        Args:
            nickname (str): Nickname del usuario
            password (str): Contraseña
            
        Returns:
            dict: Información del usuario si la autenticación es exitosa, None en caso contrario
        """
        return self.user_model.authenticate(nickname, password)
    
    def verify_password(self, nickname, password):
        """
        Verifica si la contraseña proporcionada coincide con la almacenada para un usuario.
        
        Args:
            nickname (str): Nickname del usuario
            password (str): Contraseña a verificar
            
        Returns:
            bool: True si la contraseña es correcta, False en caso contrario
        """
        return self.user_model.verify_password(nickname, password)
    
    def get_users_by_role(self, role_name, page=1, page_size=10):
        """
        Obtiene usuarios por rol con paginación.
        
        Args:
            role_name (str): Nombre del rol
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Lista de usuarios con el rol especificado con metadatos de paginación
        """
        return self.user_model.get_users_by_role(role_name, page, page_size)
    
    def get_all_roles(self):
        """
        Obtiene todos los roles disponibles.
        
        Returns:
            list: Lista de roles
        """
        return self.user_model.get_all_roles()