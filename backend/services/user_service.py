from models.user import UserModel

class UserService:
    """
    Servicio para operaciones relacionadas con usuarios.
    Implementa la lógica de negocio.
    """
    def __init__(self):
        self.user_model = UserModel()
    
    def get_all_users(self):
        """
        Obtiene todos los usuarios.
        
        Returns:
            list: Lista de usuarios
        """
        return self.user_model.get_all_users()
    
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
    
    def get_user_reading_list(self, nickname):
        """
        Obtiene la lista de lectura de un usuario.
        
        Args:
            nickname (str): Nickname del usuario
            
        Returns:
            list: Lista de libros del usuario
        """
        return self.user_model.get_user_reading_list(nickname)
    
    def add_user(self, name, last_name1, last_name2, birthdate, union_date, nickname, password, role_name):
        """
        Añade un nuevo usuario.
        
        Returns:
            dict: Resultado de la operación
        """
        return self.user_model.add_user(name, last_name1, last_name2, birthdate, union_date, nickname, password, role_name)