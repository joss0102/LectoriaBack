from config.database import DatabaseConnection

class UserModel:
    """
    Modelo para operaciones relacionadas con usuarios.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
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
        offset = (page - 1) * page_size
        query_params = []
        
        # Construir la consulta base
        query = """
            SELECT id, name, last_name1, last_name2, nickName, 
                   birthdate, union_date, id_role, 
                   (SELECT name FROM user_role WHERE id = user.id_role) AS role_name
            FROM user
        """
        
        count_query = "SELECT COUNT(*) as total FROM user"
        
        if search:
            # Añadir condición de búsqueda
            query += """ 
                WHERE name LIKE %s 
                   OR last_name1 LIKE %s 
                   OR last_name2 LIKE %s
                   OR nickName LIKE %s
            """
            count_query += """ 
                WHERE name LIKE %s 
                   OR last_name1 LIKE %s 
                   OR last_name2 LIKE %s
                   OR nickName LIKE %s
            """
            query_params = [f"%{search}%", f"%{search}%", f"%{search}%", f"%{search}%"]
        
        # Añadir ordenación y paginación
        query += " ORDER BY name, last_name1 LIMIT %s OFFSET %s"
        query_params.extend([page_size, offset])
        
        # Ejecutar consultas
        users = self.db.execute_query(query, query_params)
        
        if search:
            total_count = self.db.execute_query(count_query, query_params[:4])[0]['total']
        else:
            total_count = self.db.execute_query(count_query)[0]['total']
        
        return {
            'data': users,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_items': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }
    
    def get_user_by_nickname(self, nickname):
        """
        Obtiene un usuario por su nickname.
        
        Args:
            nickname (str): Nickname del usuario
            
        Returns:
            dict: Información del usuario o None si no existe
        """
        query = """
            SELECT u.id, u.name, u.last_name1, u.last_name2, u.nickName, 
                   u.birthdate, u.union_date, u.id_role, r.name as role_name
            FROM user u
            JOIN user_role r ON u.id_role = r.id
            WHERE u.nickName = %s
        """
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
        offset = (page - 1) * page_size
        query_params = [nickname]
        
        # Construir la consulta base
        query = "SELECT * FROM vw_user_reading_info WHERE user_nickname = %s"
        count_query = "SELECT COUNT(*) as total FROM vw_user_reading_info WHERE user_nickname = %s"
        
        if status:
            query += " AND reading_status = %s"
            count_query += " AND reading_status = %s"
            query_params.append(status)
        
        # Añadir ordenación y paginación
        query += " ORDER BY date_added DESC LIMIT %s OFFSET %s"
        query_params.extend([page_size, offset])
        
        # Ejecutar consultas
        books = self.db.execute_query(query, query_params)
        total_count = self.db.execute_query(count_query, query_params[:-2])[0]['total']
        
        return {
            'data': books,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_items': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }
    
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
        params = [name, last_name1, last_name2, birthdate, union_date, nickname, password, role_name]
        return self.db.call_procedure("add_user_full", params)
    
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
        try:
            # Obtener el usuario actual
            user = self.get_user_by_nickname(nickname)
            if not user:
                return None
            
            # Construir la consulta de actualización dinámica
            update_parts = []
            params = []
            
            if name:
                update_parts.append("name = %s")
                params.append(name)
                
            if last_name1 is not None:  # Permitir establecer a cadena vacía
                update_parts.append("last_name1 = %s")
                params.append(last_name1)
                
            if last_name2 is not None:  # Permitir establecer a cadena vacía
                update_parts.append("last_name2 = %s")
                params.append(last_name2)
                
            if birthdate:
                update_parts.append("birthdate = %s")
                params.append(birthdate)
            
            if role_name:
                # Obtener el ID del rol
                role_query = "SELECT id FROM user_role WHERE name = %s"
                role_result = self.db.execute_query(role_query, [role_name])
                
                if role_result:
                    role_id = role_result[0]['id']
                    update_parts.append("id_role = %s")
                    params.append(role_id)
            
            if not update_parts:
                # Si no hay nada que actualizar, simplemente retornar usuario actual
                return user
                
            # Completar la consulta
            query = f"UPDATE user SET {', '.join(update_parts)} WHERE nickName = %s"
            params.append(nickname)
            
            # Ejecutar la actualización
            self.db.execute_update(query, params)
            
            # Retornar el usuario actualizado
            return self.get_user_by_nickname(nickname)
        except Exception as e:
            print(f"Error al actualizar usuario: {e}")
            return None
    
    def change_password(self, nickname, new_password):
        """
        Cambia la contraseña de un usuario.
        
        Args:
            nickname (str): Nickname del usuario
            new_password (str): Nueva contraseña
            
        Returns:
            bool: True si el cambio fue exitoso, False en caso contrario
        """
        try:
            # Hashear la nueva contraseña (SHA-256)
            query = "UPDATE user SET password = SHA2(%s, 256) WHERE nickName = %s"
            result = self.db.execute_update(query, [new_password, nickname])
            
            return result > 0  # True si se actualizó al menos una fila
        except Exception as e:
            print(f"Error al cambiar contraseña: {e}")
            return False
    
    def delete_user(self, nickname):
        """
        Elimina un usuario por su nickname.
        
        Args:
            nickname (str): Nickname del usuario a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        try:
            # Obtener el ID del usuario
            user = self.get_user_by_nickname(nickname)
            if not user:
                return False
                
            user_id = user['id']
            
            # Eliminar relaciones en otras tablas
            # Eliminar notas de libros
            self.db.execute_update("DELETE FROM book_note WHERE id_user = %s", [user_id])
            
            # Eliminar frases destacadas
            self.db.execute_update("DELETE FROM phrase WHERE id_user = %s", [user_id])
            
            # Eliminar reseñas
            self.db.execute_update("DELETE FROM review WHERE id_user = %s", [user_id])
            
            # Eliminar progreso de lectura
            self.db.execute_update("DELETE FROM reading_progress WHERE id_user = %s", [user_id])
            
            # Eliminar descripciones de libros
            self.db.execute_update("DELETE FROM user_book_description WHERE id_user = %s", [user_id])
            
            # Eliminar relaciones usuario-libro
            self.db.execute_update("DELETE FROM user_has_book WHERE id_user = %s", [user_id])
            
            # Finalmente eliminar el usuario
            query = "DELETE FROM user WHERE id = %s"
            result = self.db.execute_update(query, [user_id])
            
            return result > 0  # True si se eliminó al menos una fila
        except Exception as e:
            print(f"Error al eliminar usuario: {e}")
            return False
    
    def authenticate(self, nickname, password):
        """
        Autentica a un usuario verificando sus credenciales.
        
        Args:
            nickname (str): Nickname del usuario
            password (str): Contraseña
            
        Returns:
            dict: Información del usuario si la autenticación es exitosa, None en caso contrario
        """
        try:
            # Hashear la contraseña proporcionada para compararla con la almacenada
            query = """
                SELECT u.id, u.name, u.last_name1, u.last_name2, u.nickName, 
                       u.birthdate, u.union_date, u.id_role, r.name as role_name
                FROM user u
                JOIN user_role r ON u.id_role = r.id
                WHERE u.nickName = %s AND u.password = SHA2(%s, 256)
            """
            results = self.db.execute_query(query, [nickname, password])
            
            return results[0] if results else None
        except Exception as e:
            print(f"Error al autenticar usuario: {e}")
            return None
    
    def verify_password(self, nickname, password):
        """
        Verifica si la contraseña proporcionada coincide con la almacenada para un usuario.
        
        Args:
            nickname (str): Nickname del usuario
            password (str): Contraseña a verificar
            
        Returns:
            bool: True si la contraseña es correcta, False en caso contrario
        """
        try:
            query = "SELECT 1 FROM user WHERE nickName = %s AND password = SHA2(%s, 256)"
            results = self.db.execute_query(query, [nickname, password])
            
            return len(results) > 0
        except Exception as e:
            print(f"Error al verificar contraseña: {e}")
            return False
    
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
        offset = (page - 1) * page_size
        
        # Construir la consulta
        query = """
            SELECT u.id, u.name, u.last_name1, u.last_name2, u.nickName, 
                   u.birthdate, u.union_date, u.id_role, r.name as role_name
            FROM user u
            JOIN user_role r ON u.id_role = r.id
            WHERE r.name = %s
            ORDER BY u.name, u.last_name1
            LIMIT %s OFFSET %s
        """
        
        count_query = """
            SELECT COUNT(*) as total
            FROM user u
            JOIN user_role r ON u.id_role = r.id
            WHERE r.name = %s
        """
        
        # Ejecutar consultas
        users = self.db.execute_query(query, [role_name, page_size, offset])
        total_count = self.db.execute_query(count_query, [role_name])[0]['total']
        
        return {
            'data': users,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_items': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }
    
    def get_all_roles(self):
        """
        Obtiene todos los roles disponibles.
        
        Returns:
            list: Lista de roles
        """
        query = "SELECT id, name FROM user_role ORDER BY name"
        return self.db.execute_query(query)