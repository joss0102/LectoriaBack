from config.database import DatabaseConnection

class ReadingGoalsModel:
    """
    Modelo para operaciones relacionadas con las metas de lectura de usuarios.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_reading_goals(self, user_nickname):
        """
        Obtiene las metas de lectura de un usuario por su nickname.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            dict: Información de las metas o None si no existe
        """
        try:
            query = """
                SELECT rg.id, rg.yearly, rg.monthly, rg.daily_pages
                FROM reading_goals rg
                JOIN user u ON rg.id_user = u.id
                WHERE u.nickName = %s
                LIMIT 1
            """
            results = self.db.execute_query(query, [user_nickname])
            
            if results:
                return results[0]
            else:
                # Si no existe, crear valores por defecto
                return self.create_default_goals(user_nickname)
        except Exception as e:
            print(f"Error al obtener metas de lectura: {e}")
            return None
    
    def create_default_goals(self, user_nickname):
        """
        Crea metas de lectura por defecto para un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            dict: Información de las metas creadas o None si hubo un error
        """
        try:
            # Obtener el ID del usuario
            user_query = "SELECT id FROM user WHERE nickName = %s"
            user_result = self.db.execute_query(user_query, [user_nickname])
            
            if not user_result:
                return None
                
            user_id = user_result[0]['id']
            
            # Valores por defecto
            defaults = {
                'yearly': 15,
                'monthly': 2,
                'daily_pages': 30
            }
            
            # Insertar metas por defecto
            insert_query = """
                INSERT INTO reading_goals 
                (id_user, yearly, monthly, daily_pages) 
                VALUES (%s, %s, %s, %s)
            """
            params = [
                user_id, 
                defaults['yearly'], 
                defaults['monthly'], 
                defaults['daily_pages']
            ]
            
            self.db.execute_update(insert_query, params)
            
            # Devolver los valores creados
            defaults['id'] = self.db.get_last_id()
            
            return defaults
        except Exception as e:
            print(f"Error al crear metas de lectura por defecto: {e}")
            return None
    
    def update_reading_goals(self, user_nickname, goals_data):
        """
        Actualiza las metas de lectura de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            goals_data (dict): Datos a actualizar
            
        Returns:
            dict: Información de las metas actualizadas o None si hubo un error
        """
        try:
            # Obtener el ID del usuario
            user_query = "SELECT id FROM user WHERE nickName = %s"
            user_result = self.db.execute_query(user_query, [user_nickname])
            
            if not user_result:
                return None
                
            user_id = user_result[0]['id']
            
            # Validar datos
            yearly = int(goals_data.get('yearly', 15))
            monthly = int(goals_data.get('monthly', 2))
            daily_pages = int(goals_data.get('daily_pages', 30))
            
            # Verificar si existen metas para este usuario
            check_query = "SELECT id FROM reading_goals WHERE id_user = %s"
            existing = self.db.execute_query(check_query, [user_id])
            
            if existing:
                # Actualizar
                update_query = """
                    UPDATE reading_goals 
                    SET yearly = %s, monthly = %s, daily_pages = %s
                    WHERE id_user = %s
                """
                self.db.execute_update(update_query, [
                    yearly, monthly, daily_pages, user_id
                ])
                
                goal_id = existing[0]['id']
            else:
                # Insertar
                insert_query = """
                    INSERT INTO reading_goals 
                    (id_user, yearly, monthly, daily_pages) 
                    VALUES (%s, %s, %s, %s)
                """
                self.db.execute_update(insert_query, [
                    user_id, yearly, monthly, daily_pages
                ])
                
                goal_id = self.db.get_last_id()
            
            # Retornar los valores actualizados
            return {
                'id': goal_id,
                'yearly': yearly,
                'monthly': monthly,
                'daily_pages': daily_pages
            }
        except Exception as e:
            print(f"Error al actualizar metas de lectura: {e}")
            return None