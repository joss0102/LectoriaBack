from models.reading_goals import ReadingGoalsModel

class ReadingGoalsService:
    """
    Servicio para operaciones relacionadas con las metas de lectura.
    Implementa la lógica de negocio.
    """
    def __init__(self):
        self.reading_goals_model = ReadingGoalsModel()
    
    def get_reading_goals(self, user_nickname):
        """
        Obtiene las metas de lectura de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            dict: Información de las metas o None si no existe
        """
        return self.reading_goals_model.get_reading_goals(user_nickname)
    
    def update_reading_goals(self, user_nickname, goals_data):
        """
        Actualiza las metas de lectura de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            goals_data (dict): Datos a actualizar
            
        Returns:
            dict: Información de las metas actualizadas o None si hubo un error
        """
        return self.reading_goals_model.update_reading_goals(user_nickname, goals_data)