import mysql.connector
from mysql.connector import Error, pooling
import os
from dotenv import load_dotenv
import logging
from contextlib import contextmanager
from config.settings import DB_POOL_SIZE, DB_CONNECT_TIMEOUT, DB_POOL_TIMEOUT

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("app.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("database")

# Cargar variables de entorno
load_dotenv()

class DatabaseConnection:
    """
    Clase para manejar la conexión a la base de datos MySQL con pool de conexiones.
    """
    _instance = None
    _pool = None
    
    def __new__(cls):
        """Implementa el patrón Singleton para evitar múltiples instancias del pool de conexiones."""
        if cls._instance is None:
            cls._instance = super(DatabaseConnection, cls).__new__(cls)
            cls._create_pool()
        return cls._instance
    
    @classmethod
    def _create_pool(cls):
        """Crea un pool de conexiones a la base de datos."""
        try:
            # Configuración de la conexión desde variables de entorno
            config = {
                'host': os.getenv('DB_HOST', 'localhost'),
                'database': os.getenv('DB_NAME', 'Lectoria'),
                'user': os.getenv('DB_USER', 'Lectoria'),
                'password': os.getenv('DB_PASSWORD', '1234'),
                'port': os.getenv('DB_PORT', '3306'),
                'pool_name': 'lectoria_pool',
                'pool_size': DB_POOL_SIZE,
                'pool_reset_session': True,
                'connect_timeout': DB_CONNECT_TIMEOUT,
                'connection_timeout': DB_POOL_TIMEOUT,
                'use_pure': True,
                'autocommit': True,
                'charset': 'utf8mb4',
                'collation': 'utf8mb4_unicode_ci'
            }
            
            cls._pool = pooling.MySQLConnectionPool(**config)
            logger.info(f"Pool de conexiones a MySQL inicializado con tamaño {DB_POOL_SIZE}")
        except Error as e:
            logger.error(f"Error al crear el pool de conexiones a MySQL: {e}")
            raise
    
    @contextmanager
    def get_connection(self):
        """
        Obtiene una conexión del pool usando el patrón contextmanager.
        Esto garantiza que la conexión se devuelva al pool correctamente.
        
        Yields:
            connection: Conexión a la base de datos desde el pool
        """
        connection = None
        retry_count = 0
        max_retries = 3
        
        while retry_count < max_retries:
            try:
                if self._pool is None:
                    self._create_pool()
                    
                connection = self._pool.get_connection()
                if not connection.is_connected():
                    connection.reconnect()
                    
                yield connection
                break  # Si llegamos aquí, todo está bien, salimos del bucle
            except Error as e:
                retry_count += 1
                logger.warning(f"Intento {retry_count}/{max_retries} fallido al obtener conexión: {e}")
                if retry_count >= max_retries:
                    logger.error(f"Error al obtener conexión del pool después de {max_retries} intentos: {e}")
                    raise
                # Esperar antes de reintentar (con tiempo exponencial)
                import time
                time.sleep(0.5 * (2 ** retry_count))
            finally:
                if connection is not None:
                    connection.close()
                    logger.debug("Conexión devuelta al pool")
    
    @contextmanager
    def get_cursor(self, dictionary=True, prepared=False):
        """
        Obtiene un cursor para ejecutar queries con manejo automático de conexiones.
        
        Args:
            dictionary (bool): Si True, devuelve resultados como diccionarios
            prepared (bool): Si True, usa prepared statements para mejor rendimiento
            
        Yields:
            cursor: Cursor para ejecutar queries
        """
        with self.get_connection() as connection:
            cursor = None
            try:
                # NOTA: MySQL Connector no soporta cursores dictionary y prepared al mismo tiempo
                # Así que priorizamos dictionary y si se pide prepared, lo ignoramos con una advertencia
                if prepared and dictionary:
                    logger.warning("MySQL Connector no soporta cursores dictionary y prepared simultáneamente. Usando dictionary=True y ignorando prepared=True.")
                    cursor = connection.cursor(dictionary=True)
                else:
                    cursor = connection.cursor(dictionary=dictionary)
                    
                yield cursor
                connection.commit()
            except Error as e:
                connection.rollback()
                logger.error(f"Error de base de datos: {e}")
                raise
            finally:
                if cursor is not None:
                    cursor.close()
    
    def execute_query(self, query, params=None, fetch_all=True, dictionary=True):
        """
        Ejecuta una consulta SQL y devuelve los resultados.
        
        Args:
            query (str): Consulta SQL a ejecutar
            params (list, optional): Parámetros para la consulta. Default is None.
            fetch_all (bool): Si True, devuelve todos los resultados, sino solo el primero
            dictionary (bool): Si True, devuelve resultados como diccionarios
            
        Returns:
            list: Resultados de la consulta si es SELECT/SHOW
            int: Número de filas afectadas si es INSERT/UPDATE/DELETE
        """
        # Verificar si es una consulta que podría usar prepared statement
        is_parameterized = params is not None and len(str(query).split('%s')) > 1
        
        # Si tiene parámetros pero no es el formato %s, convertir a ese formato
        if params is not None and not is_parameterized:
            # Convertir ? o :param a %s
            if '?' in query:
                query = query.replace('?', '%s')
            elif any(p.startswith(':') for p in query.split() if p):
                for param in params:
                    query = query.replace(f":{param}", "%s")
        
        try:
            # No usamos prepared=is_parameterized porque priorizamos dictionary=True
            with self.get_cursor(dictionary=dictionary) as cursor:
                cursor.execute(query, params if params else ())
                
                if query.strip().upper().startswith(('SELECT', 'SHOW')):
                    if fetch_all:
                        return cursor.fetchall()
                    result = cursor.fetchone()
                    return result if result else None
                else:
                    return cursor.rowcount
        except Error as e:
            logger.error(f"Error al ejecutar la consulta: {e}, Query: {query}")
            logger.error(f"Parámetros: {params}")
            return None
    
    def execute_update(self, query, params=None):
        """
        Ejecuta una consulta SQL de actualización (INSERT, UPDATE, DELETE).
        
        Args:
            query (str): Consulta SQL
            params (list, optional): Parámetros para la consulta
            
        Returns:
            int: Número de filas afectadas
        """
        return self.execute_query(query, params)
    
    def get_last_id(self):
        """
        Obtiene el último ID insertado en la base de datos.
        
        Returns:
            int: Último ID insertado
        """
        result = self.execute_query("SELECT LAST_INSERT_ID() as last_id")
        return result[0]['last_id'] if result else None
    
    def execute_batch(self, query, params_list):
        """
        Ejecuta múltiples consultas con diferentes parámetros en un lote.
        
        Args:
            query (str): Consulta SQL con placeholders
            params_list (list): Lista de listas de parámetros
            
        Returns:
            int: Número total de filas afectadas
        """
        if not params_list:
            return 0
            
        try:
            with self.get_connection() as connection:
                cursor = None
                try:
                    cursor = connection.cursor()
                    total_rows = 0
                    
                    for params in params_list:
                        cursor.execute(query, params)
                        total_rows += cursor.rowcount
                        
                    connection.commit()
                    return total_rows
                except Error as e:
                    connection.rollback()
                    logger.error(f"Error al ejecutar batch: {e}, Query: {query}")
                    logger.error(f"Primer conjunto de parámetros: {params_list[0] if params_list else None}")
                    raise
                finally:
                    if cursor is not None:
                        cursor.close()
        except Error as e:
            logger.error(f"Error de conexión al ejecutar batch: {e}")
            return 0
    
    def call_procedure(self, procedure_name, params=None):
        """
        Llama a un procedimiento almacenado y devuelve los resultados.
        
        Args:
            procedure_name (str): Nombre del procedimiento
            params (list, optional): Parámetros para el procedimiento. Default is None.
            
        Returns:
            list: Resultados del procedimiento si devuelve algo
            None: Si no hay resultados
        """
        try:
            with self.get_connection() as connection:
                cursor = None
                try:
                    cursor = connection.cursor(dictionary=True)
                    cursor.callproc(procedure_name, params if params else ())
                    
                    # Si el procedimiento devuelve resultados, los recuperamos
                    results = []
                    for result in cursor.stored_results():
                        results = result.fetchall()
                    
                    connection.commit()
                    return results
                except Error as e:
                    connection.rollback()
                    logger.error(f"Error al llamar al procedimiento {procedure_name}: {e}")
                    logger.error(f"Parámetros: {params}")
                    return None
                finally:
                    if cursor is not None:
                        cursor.close()
        except Error as e:
            logger.error(f"Error de conexión al llamar al procedimiento {procedure_name}: {e}")
            return None