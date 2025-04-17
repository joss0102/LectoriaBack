import mysql.connector
from mysql.connector import Error, pooling
import os
from dotenv import load_dotenv
import logging
from contextlib import contextmanager

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
                'pool_size': 10,
                'pool_reset_session': True,
                'connect_timeout': 30,  # Timeout para conexiones
                'connection_timeout': 30
            }
            
            cls._pool = pooling.MySQLConnectionPool(**config)
            logger.info("Pool de conexiones a MySQL inicializado")
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
        try:
            if self._pool is None:
                self._create_pool()
                
            connection = self._pool.get_connection()
            if not connection.is_connected():
                connection.reconnect()
                
            yield connection
        except Error as e:
            logger.error(f"Error al obtener conexión del pool: {e}")
            raise
        finally:
            if connection is not None:
                connection.close()
                logger.debug("Conexión devuelta al pool")
    
    @contextmanager
    def get_cursor(self, dictionary=True):
        """
        Obtiene un cursor para ejecutar queries con manejo automático de conexiones.
        
        Args:
            dictionary (bool): Si True, devuelve resultados como diccionarios
            
        Yields:
            cursor: Cursor para ejecutar queries
        """
        with self.get_connection() as connection:
            cursor = None
            try:
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
    
    def execute_query(self, query, params=None):
        """
        Ejecuta una consulta SQL y devuelve los resultados.
        
        Args:
            query (str): Consulta SQL a ejecutar
            params (list, optional): Parámetros para la consulta. Default is None.
            
        Returns:
            list: Resultados de la consulta si es SELECT/SHOW
            int: Número de filas afectadas si es INSERT/UPDATE/DELETE
        """
        try:
            with self.get_cursor() as cursor:
                cursor.execute(query, params if params else ())
                
                if query.strip().upper().startswith(('SELECT', 'SHOW')):
                    return cursor.fetchall()
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