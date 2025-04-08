### 2. Configuración de Variables de Entorno
Crea un archivo .env en la carpeta backend/:

```bash
DB_HOST=localhost
DB_NAME=TFG2
DB_USER=root
DB_PASSWORD=tupassword
DB_PORT=3306
```

### 3. Implementación de la Conexión a la Base de Datos
En `backend/config/database.py`:

```python
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
            'database': os.getenv('DB_NAME', 'TFG2'),
            'user': os.getenv('DB_USER', 'root'),
            'password': os.getenv('DB_PASSWORD', ''),
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
```
### 4. Configuración de Ajustes Globales
Archivo: `backend/config/settings.py`

```python
import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Configuración de la API
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "5000"))
DEBUG_MODE = os.getenv("DEBUG_MODE", "True").lower() == "true"

# Configuración de paginación
DEFAULT_PAGE_SIZE = 10
```

### 5. Implementación del Modelo de Libros
Archivo: `backend/models/book.py`

```python
from config.database import DatabaseConnection

class BookModel:
    """
    Modelo para operaciones relacionadas con libros.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_all_books(self, page=1, page_size=10):
        """
        Obtiene todos los libros con paginación.
        
        Args:
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            list: Lista de libros
        """
        offset = (page - 1) * page_size
        query = "SELECT * FROM vw_book_complete_info LIMIT %s OFFSET %s"
        return self.db.execute_query(query, [page_size, offset])
    
    def get_book_by_id(self, book_id):
        """
        Obtiene un libro por su ID.
        
        Args:
            book_id (int): ID del libro
            
        Returns:
            dict: Información del libro o None si no existe
        """
        query = "SELECT * FROM vw_book_complete_info WHERE book_id = %s"
        results = self.db.execute_query(query, [book_id])
        return results[0] if results else None
    
    def get_books_by_genre(self, genre):
        """
        Obtiene libros por género.
        
        Args:
            genre (str): Género a buscar
            
        Returns:
            list: Lista de libros que coinciden con el género
        """
        query = "SELECT * FROM vw_book_complete_info WHERE genres LIKE %s"
        return self.db.execute_query(query, [f"%{genre}%"])
    
    def get_books_by_author(self, author):
        """
        Obtiene libros por autor.
        
        Args:
            author (str): Autor a buscar
            
        Returns:
            list: Lista de libros del autor
        """
        query = "SELECT * FROM vw_book_complete_info WHERE authors LIKE %s"
        return self.db.execute_query(query, [f"%{author}%"])
    
    def add_book_full(self, title, pages, synopsis, custom_description, author_name, 
                     author_last_name1, author_last_name2, genre1, genre2, genre3, 
                     genre4, genre5, saga_name, user_nickname, status, date_added,
                     date_start, date_ending, review, rating, phrases, notes):
        """
        Añade un libro completo utilizando el procedimiento almacenado.
        
        Returns:
            dict: Resultado de la operación
        """
        params = [title, pages, synopsis, custom_description, author_name, 
                 author_last_name1, author_last_name2, genre1, genre2, genre3, 
                 genre4, genre5, saga_name, user_nickname, status, date_added,
                 date_start, date_ending, review, rating, phrases, notes]
        
        return self.db.call_procedure("add_book_full", params)
```
### 6. Implementación del Modelo de Usuarios
Archivo: `backend/models/user.py`

```python
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
```
### 7. Implementación del Modelo de Lecturas
Archivo: `backend/models/reading.py`

```python
from config.database import DatabaseConnection

class ReadingModel:
    """
    Modelo para operaciones relacionadas con la lectura y progreso.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_reading_progress(self, user_nickname, book_title=None):
        """
        Obtiene el progreso de lectura de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str, optional): Título del libro. Default is None.
            
        Returns:
            list: Progreso de lectura del usuario
        """
        if book_title:
            query = "SELECT * FROM vw_reading_progress_detailed WHERE user_nickname = %s AND book_title = %s ORDER BY reading_date"
            return self.db.execute_query(query, [user_nickname, book_title])
        else:
            query = "SELECT * FROM vw_reading_progress_detailed WHERE user_nickname = %s ORDER BY reading_date"
            return self.db.execute_query(query, [user_nickname])
    
    def add_reading_progress(self, nickname, book_title, pages_read_list, dates_list):
        """
        Añade progreso de lectura para un usuario y un libro.
        
        Args:
            nickname (str): Nickname del usuario
            book_title (str): Título del libro
            pages_read_list (str): Lista de páginas leídas separadas por comas
            dates_list (str): Lista de fechas correspondientes separadas por comas
            
        Returns:
            dict: Resultado de la operación
        """
        params = [nickname, book_title, pages_read_list, dates_list]
        return self.db.call_procedure("add_reading_progress_full", params)
    
    def get_book_reviews(self, book_title=None, user_nickname=None):
        """
        Obtiene reseñas de libros.
        
        Args:
            book_title (str, optional): Título del libro. Default is None.
            user_nickname (str, optional): Nickname del usuario. Default is None.
            
        Returns:
            list: Reseñas que coinciden con los criterios
        """
        if book_title and user_nickname:
            query = "SELECT * FROM vw_book_reviews WHERE book_title = %s AND user_nickname = %s"
            return self.db.execute_query(query, [book_title, user_nickname])
        elif book_title:
            query = "SELECT * FROM vw_book_reviews WHERE book_title = %s"
            return self.db.execute_query(query, [book_title])
        elif user_nickname:
            query = "SELECT * FROM vw_book_reviews WHERE user_nickname = %s"
            return self.db.execute_query(query, [user_nickname])
        else:
            query = "SELECT * FROM vw_book_reviews"
            return self.db.execute_query(query)
```