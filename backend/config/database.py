import mysql.connector
from mysql.connector import Error
import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

class DatabaseConnection:
    """
    Clase para manejar la conexión a la base de datos MySQL.
    """
    def __init__(self):
        # Configuración de la conexión desde variables de entorno
        self.config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'database': os.getenv('DB_NAME', 'Lectoria'),
            'user': os.getenv('DB_USER', 'Lectoria'),
            'password': os.getenv('DB_PASSWORD', '1234'),
            'port': os.getenv('DB_PORT', '3306')
        }
        self.connection = None
    
    def connect(self):
        """Establece la conexión a la base de datos."""
        try:
            if self.connection is None or not self.connection.is_connected():
                self.connection = mysql.connector.connect(**self.config)
                print("Conectado a la base de datos MySQL")
            return self.connection
        except Error as e:
            print(f"Error al conectar a MySQL: {e}")
            return None
    
    def disconnect(self):
        """Cierra la conexión a la base de datos."""
        if self.connection and self.connection.is_connected():
            self.connection.close()
            print("Conexión a MySQL cerrada")
    
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
        connection = self.connect()
        cursor = None
        results = None
        
        try:
            cursor = connection.cursor(dictionary=True)
            cursor.execute(query, params if params else ())
            
            if query.strip().upper().startswith(('SELECT', 'SHOW')):
                results = cursor.fetchall()
            else:
                connection.commit()
                results = cursor.rowcount
            
            return results
        except Error as e:
            print(f"Error al ejecutar la consulta: {e}")
            return None
        finally:
            if cursor:
                cursor.close()
    
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
        connection = self.connect()
        cursor = None
        results = None
        
        try:
            cursor = connection.cursor(dictionary=True)
            cursor.callproc(procedure_name, params if params else ())
            
            # Si el procedimiento devuelve resultados, los recuperamos
            for result in cursor.stored_results():
                results = result.fetchall()
            
            connection.commit()
            return results
        except Error as e:
            print(f"Error al llamar al procedimiento: {e}")
            return None
        finally:
            if cursor:
                cursor.close()
