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