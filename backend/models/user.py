from config.database import DatabaseConnection
import logging
from utils.query_helper import build_conditional_query
from utils.cache import cache
from config.settings import ENABLE_CACHE, CACHE_DEFAULT_TIMEOUT

logger = logging.getLogger('user_model')

class UserModel:
    """
    Modelo para operaciones relacionadas con usuarios.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    @cache.memoize(timeout=300) if ENABLE_CACHE else lambda f: f
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
        try:
            offset = (page - 1) * page_size
            query_params = []
            conditions = []
            
            # Consulta base
            base_query = """
                SELECT id, name, last_name1, last_name2, nickName, 
                        birthdate, union_date, id_role, 
                        (SELECT name FROM user_role WHERE id = user.id_role) AS role_name
                FROM user
            """
            
            count_query = "SELECT COUNT(*) as total FROM user"
            
            if search:
                search_condition = """
                    name LIKE %s 
                    OR last_name1 LIKE %s 
                    OR last_name2 LIKE %s
                    OR nickName LIKE %s
                """
                conditions.append(f"({search_condition})")
                search_param = f"%{search}%"
                query_params.extend([search_param, search_param, search_param, search_param])
            
            query, params = build_conditional_query(
                base_query,
                conditions,
                query_params,
                "name, last_name1",
                page_size,
                offset
            )
            
            users = self.db.execute_query(query, params)
            
            count_query, count_params = build_conditional_query(
                count_query,
                conditions,
                query_params[:]
            )
            
            total_count = self.db.execute_query(count_query, count_params)[0]['total']
            
            return {
                'data': users,
                'pagination': {
                    'page': page,
                    'page_size': page_size,
                    'total_items': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size
                }
            }
        except Exception as e:
            logger.error(f"Error al obtener usuarios: {e}")
            return {'data': [], 'pagination': {'page': page, 'page_size': page_size, 'total_items': 0, 'total_pages': 0}}
    
    @cache.memoize(timeout=300) if ENABLE_CACHE else lambda f: f
    def get_user_by_nickname(self, nickname):
        """
        Obtiene un usuario por su nickname.
        
        Args:
            nickname (str): Nickname del usuario
            
        Returns:
            dict: Información del usuario o None si no existe
        """
        try:
            query = """
                SELECT u.id, u.name, u.last_name1, u.last_name2, u.nickName, 
                        u.birthdate, u.union_date, u.id_role, r.name as role_name
                FROM user u
                JOIN user_role r ON u.id_role = r.id
                WHERE u.nickName = %s
                LIMIT 1
            """
            results = self.db.execute_query(query, [nickname])
            return results[0] if results else None
        except Exception as e:
            logger.error(f"Error al obtener usuario por nickname {nickname}: {e}")
            return None
        
    def get_user_reading_stats(self, nickname):
        """
        Obtiene estadísticas de lectura de un usuario.
        
        Args:
            nickname (str): Nickname del usuario
            
        Returns:
            dict: Estadísticas de lectura del usuario
        """
        try:
            query = "SELECT * FROM vw_user_reading_stats WHERE user_nickname = %s LIMIT 1"
            results = self.db.execute_query(query, [nickname])
            return results[0] if results else None
        except Exception as e:
            logger.error(f"Error al obtener estadísticas de lectura para {nickname}: {e}")
            return None

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
        try:
            offset = (page - 1) * page_size
            conditions = ["user_nickname = %s"]
            query_params = [nickname]
            
            base_query = "SELECT * FROM vw_user_reading_info"
            count_query = "SELECT COUNT(*) as total FROM vw_user_reading_info"
            
            if status:
                conditions.append("reading_status = %s")
                query_params.append(status)
            
            query, params = build_conditional_query(
                base_query,
                conditions,
                query_params,
                "date_added DESC",
                page_size,
                offset
            )
            
            count_query, count_params = build_conditional_query(
                count_query,
                conditions,
                query_params[:]
            )
            
            books = self.db.execute_query(query, params)
            total_count = self.db.execute_query(count_query, count_params)[0]['total']
            
            return {
                'data': books,
                'pagination': {
                    'page': page,
                    'page_size': page_size,
                    'total_items': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size
                }
            }
        except Exception as e:
            logger.error(f"Error al obtener lista de lectura para {nickname}: {e}")
            return {'data': [], 'pagination': {'page': page, 'page_size': page_size, 'total_items': 0, 'total_pages': 0}}
    
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
            query = """
                SELECT u.id, u.name, u.last_name1, u.last_name2, u.nickName, 
                    u.birthdate, u.union_date, u.id_role, r.name as role_name
                FROM user u
                JOIN user_role r ON u.id_role = r.id
                WHERE u.nickName = %s AND u.password = SHA2(%s, 256)
                LIMIT 1
            """
            results = self.db.execute_query(query, [nickname, password])
            
            if results:
                logger.info(f"Autenticación exitosa para usuario: {nickname}")
                return results[0]
            else:
                logger.warning(f"Autenticación fallida para usuario: {nickname}")
                return None
        except Exception as e:
            logger.error(f"Error en la autenticación para usuario {nickname}: {e}")
            return None
    def add_user(self, name, last_name1, last_name2, birthdate, union_date, nickname, password, role_name):
        """
        Añade un nuevo usuario a la base de datos.
        
        Args:
            name (str): Nombre del usuario
            last_name1 (str): Primer apellido
            last_name2 (str): Segundo apellido
            birthdate (str): Fecha de nacimiento
            union_date (str): Fecha de unión
            nickname (str): Nombre de usuario
            password (str): Contraseña (se aplicará hash SHA2)
            role_name (str): Nombre del rol
        
        Returns:
            dict: Información del usuario añadido o None si falla
        """
        try:
            # Primero, obtener el ID del rol
            role_query = "SELECT id FROM user_role WHERE name = %s"
            role_results = self.db.execute_query(role_query, [role_name])
            
            if not role_results:
                logger.error(f"Rol no encontrado: {role_name}")
                return None
            
            role_id = role_results[0]['id']
            
            # Preparar la consulta de inserción
            insert_query = """
            INSERT INTO user 
            (name, last_name1, last_name2, nickName, birthdate, union_date, password, id_role) 
            VALUES 
            (%s, %s, %s, %s, %s, %s, SHA2(%s, 256), %s)
            """
            
            # Ejecutar la inserción
            self.db.execute_query(insert_query, [
                name, 
                last_name1, 
                last_name2, 
                nickname, 
                birthdate, 
                union_date, 
                password, 
                role_id
            ])
            
            # Obtener el usuario recién creado
            new_user_query = """
            SELECT u.id, u.name, u.last_name1, u.last_name2, u.nickName, 
                u.birthdate, u.union_date, u.id_role, r.name as role_name
            FROM user u
            JOIN user_role r ON u.id_role = r.id
            WHERE u.nickName = %s
            """
            
            new_user = self.db.execute_query(new_user_query, [nickname])
            
            if new_user:
                logger.info(f"Usuario añadido exitosamente: {nickname}")
                return new_user[0]
            else:
                logger.warning(f"No se pudo recuperar el usuario recién creado: {nickname}")
                return None
        
        except Exception as e:
            logger.error(f"Error al añadir usuario {nickname}: {e}")
            return None
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
                # Primero verificar que el usuario existe
                user_query = "SELECT id FROM user WHERE nickName = %s"
                user_result = self.db.execute_query(user_query, [nickname])
                
                if not user_result:
                    logger.error(f"Usuario no encontrado: {nickname}")
                    return None
                    
                user_id = user_result[0]['id']
                
                # Preparar los campos a actualizar
                update_fields = []
                update_values = []
                
                if name is not None:
                    update_fields.append("name = %s")
                    update_values.append(name)
                    
                if last_name1 is not None:
                    update_fields.append("last_name1 = %s")
                    update_values.append(last_name1)
                    
                if last_name2 is not None:
                    update_fields.append("last_name2 = %s")
                    update_values.append(last_name2)
                    
                if birthdate is not None and birthdate.strip() != '':
                    update_fields.append("birthdate = %s")
                    update_values.append(birthdate)
                    
                if role_name is not None:
                    # Obtener el ID del rol
                    role_query = "SELECT id FROM user_role WHERE name = %s"
                    role_result = self.db.execute_query(role_query, [role_name])
                    
                    if role_result:
                        update_fields.append("id_role = %s")
                        update_values.append(role_result[0]['id'])
                    else:
                        logger.error(f"Rol no encontrado: {role_name}")
                        return None
                
                if not update_fields:
                    logger.warning("No hay campos para actualizar")
                    return self.get_user_by_nickname(nickname)
                
                # Construir y ejecutar la consulta de actualización
                update_query = f"UPDATE user SET {', '.join(update_fields)} WHERE nickName = %s"
                update_values.append(nickname)
                
                self.db.execute_query(update_query, update_values)
                
                # Devolver el usuario actualizado
                updated_user = self.get_user_by_nickname(nickname)
                
                if updated_user:
                    logger.info(f"Usuario actualizado exitosamente: {nickname}")
                    return updated_user
                else:
                    logger.warning(f"No se pudo recuperar el usuario actualizado: {nickname}")
                    return None
                    
            except Exception as e:
                logger.error(f"Error al actualizar usuario {nickname}: {e}")
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
            # Verificar que el usuario existe
            user_query = "SELECT id FROM user WHERE nickName = %s"
            user_result = self.db.execute_query(user_query, [nickname])
            
            if not user_result:
                logger.error(f"Usuario no encontrado: {nickname}")
                return False
            
            # Actualizar la contraseña (hasheada)
            update_query = "UPDATE user SET password = SHA2(%s, 256) WHERE nickName = %s"
            self.db.execute_query(update_query, [new_password, nickname])
            
            logger.info(f"Contraseña actualizada exitosamente para usuario: {nickname}")
            return True
            
        except Exception as e:
            logger.error(f"Error al cambiar contraseña para usuario {nickname}: {e}")
            return False

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
            query = "SELECT id FROM user WHERE nickName = %s AND password = SHA2(%s, 256)"
            result = self.db.execute_query(query, [nickname, password])
            
            return len(result) > 0
            
        except Exception as e:
            logger.error(f"Error al verificar contraseña para usuario {nickname}: {e}")
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
            # Verificar que el usuario existe
            user_query = "SELECT id FROM user WHERE nickName = %s"
            user_result = self.db.execute_query(user_query, [nickname])
            
            if not user_result:
                logger.error(f"Usuario no encontrado: {nickname}")
                return False
            
            # Eliminar el usuario
            delete_query = "DELETE FROM user WHERE nickName = %s"
            self.db.execute_query(delete_query, [nickname])
            
            logger.info(f"Usuario eliminado exitosamente: {nickname}")
            return True
            
        except Exception as e:
            logger.error(f"Error al eliminar usuario {nickname}: {e}")
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
        try:
            offset = (page - 1) * page_size
            
            # Consulta principal
            query = """
                SELECT u.id, u.name, u.last_name1, u.last_name2, u.nickName, 
                       u.birthdate, u.union_date, u.id_role, r.name as role_name
                FROM user u
                JOIN user_role r ON u.id_role = r.id
                WHERE r.name = %s
                ORDER BY u.name, u.last_name1
                LIMIT %s OFFSET %s
            """
            
            users = self.db.execute_query(query, [role_name, page_size, offset])
            
            # Consulta para contar total
            count_query = """
                SELECT COUNT(*) as total 
                FROM user u
                JOIN user_role r ON u.id_role = r.id
                WHERE r.name = %s
            """
            
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
            
        except Exception as e:
            logger.error(f"Error al obtener usuarios por rol {role_name}: {e}")
            return {'data': [], 'pagination': {'page': page, 'page_size': page_size, 'total_items': 0, 'total_pages': 0}}

    def get_all_roles(self):
        """
        Obtiene todos los roles disponibles.
        
        Returns:
            list: Lista de roles
        """
        try:
            query = "SELECT id, name FROM user_role ORDER BY name"
            return self.db.execute_query(query)
            
        except Exception as e:
            logger.error(f"Error al obtener roles: {e}")
            return []