from config.database import DatabaseConnection

class UserModel:
    """
    Modelo para operaciones relacionadas con usuarios.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_all_users(self):
        """
        Obtiene todos los usuarios.
        
        Returns:
            list: Lista de usuarios
        """
        query = "SELECT id, name, last_name1, last_name2, nickName, id_role FROM user"
        return self.db.execute_query(query)
    
    def get_user_by_nickname(self, nickname):
        """
        Obtiene un usuario por su nickname.
        
        Args:
            nickname (str): Nickname del usuario
            
        Returns:
            dict: Información del usuario o None si no existe
        """
        query = "SELECT id, name, last_name1, last_name2, nickName, id_role FROM user WHERE nickName = %s"
        results = self.db.execute_query(query, [nickname])
        return results[0] if results else None
    
    def get_user_reading_stats(self, nickname):
        """
        Obtiene estadísticas de lectura de un usuario.
        
        Args:
            nickname (str): Nickname del usuario
            
        Returns:
            dict: Estadísticas de lectura del usuario
        """
        query = "SELECT * FROM vw_user_reading_stats WHERE user_nickname = %s"
        results = self.db.execute_query(query, [nickname])
        return results[0] if results else None
    
    def get_user_reading_list(self, nickname):
        """
        Obtiene la lista de lectura de un usuario.
        
        Args:
            nickname (str): Nickname del usuario
            
        Returns:
            list: Lista de libros del usuario
        """
        query = "SELECT * FROM vw_user_reading_info WHERE user_nickname = %s"
        return self.db.execute_query(query, [nickname])
    
    def add_user(self, name, last_name1, last_name2, birthdate, union_date, nickname, password, role_name):
        """
        Añade un nuevo usuario.
        
        Returns:
            dict: Resultado de la operación
        """
        params = [name, last_name1, last_name2, birthdate, union_date, nickname, password, role_name]
        return self.db.call_procedure("add_user_full", params)