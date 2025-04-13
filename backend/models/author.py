from config.database import DatabaseConnection

class AuthorModel:
    """
    Modelo para operaciones relacionadas con autores.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_all_authors(self):
        """
        Obtiene todos los autores.
        
        Returns:
            list: Lista de autores
        """
        query = "SELECT id, name, last_name1, last_name2, description FROM author"
        return self.db.execute_query(query)
    
    def get_author_by_id(self, author_id):
        """
        Obtiene un autor por su ID.
        
        Args:
            author_id (int): ID del autor
            
        Returns:
            dict: Información del autor o None si no existe
        """
        query = "SELECT id, name, last_name1, last_name2, description FROM author WHERE id = %s"
        results = self.db.execute_query(query, [author_id])
        return results[0] if results else None
    
    def get_books_by_author(self, author_id):
        """
        Obtiene los libros de un autor específico.
        
        Args:
            author_id (int): ID del autor
            
        Returns:
            list: Lista de libros del autor
        """
        query = """
        SELECT b.id, b.title, b.pages, s.text as synopsis
        FROM book b
        JOIN book_has_author bha ON b.id = bha.id_book
        LEFT JOIN synopsis s ON b.id = s.id_book
        WHERE bha.id_author = %s
        """
        return self.db.execute_query(query, [author_id])
    
    def add_author(self, name, last_name1, last_name2, description):
        """
        Añade un nuevo autor.
        
        Args:
            name (str): Nombre del autor
            last_name1 (str): Primer apellido
            last_name2 (str): Segundo apellido
            description (str): Descripción o biografía
            
        Returns:
            dict: Resultado de la operación
        """
        params = [name, last_name1, last_name2, description]
        return self.db.call_procedure("add_author_full", params)
        
    def update_author(self, author_id, name=None, last_name1=None, last_name2=None, description=None):
        """
        Actualiza la información de un autor existente.
        
        Args:
            author_id (int): ID del autor a actualizar
            name (str, optional): Nuevo nombre
            last_name1 (str, optional): Nuevo primer apellido
            last_name2 (str, optional): Nuevo segundo apellido
            description (str, optional): Nueva descripción
            
        Returns:
            dict: Información del autor actualizado o None si hubo un error
        """
        try:
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
                
            if description is not None:  # Permitir establecer a cadena vacía
                update_parts.append("description = %s")
                params.append(description)
                
            if not update_parts:
                # Si no hay nada que actualizar, simplemente retornar autor actual
                return self.get_author_by_id(author_id)
                
            # Completar la consulta
            query = f"UPDATE author SET {', '.join(update_parts)} WHERE id = %s"
            params.append(author_id)
            
            # Ejecutar la actualización
            self.db.execute_update(query, params)
            
            # Retornar el autor actualizado
            return self.get_author_by_id(author_id)
        except Exception as e:
            print(f"Error al actualizar autor: {e}")
            return None
            
    def delete_author(self, author_id):
        """
        Elimina un autor por su ID.
        
        Args:
            author_id (int): ID del autor a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        try:
            # Verificar que el autor no tenga libros asociados
            books = self.get_books_by_author(author_id)
            if books:
                return False  # No se puede eliminar si tiene libros
                
            # Eliminar el autor
            query = "DELETE FROM author WHERE id = %s"
            result = self.db.execute_update(query, [author_id])
            
            return result > 0  # True si se eliminó al menos una fila
        except Exception as e:
            print(f"Error al eliminar autor: {e}")
            return False
            
    def search_authors(self, search_term, page=1, page_size=10):
        """
        Busca autores por nombre o apellidos.
        
        Args:
            search_term (str): Término de búsqueda
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Resultado con autores y metadatos de paginación
        """
        offset = (page - 1) * page_size
        
        # Construir la consulta de búsqueda
        search_query = """
            SELECT id, name, last_name1, last_name2, description 
            FROM author 
            WHERE name LIKE %s 
                OR last_name1 LIKE %s 
                OR last_name2 LIKE %s
            LIMIT %s OFFSET %s
        """
        search_params = [f"%{search_term}%", f"%{search_term}%", f"%{search_term}%", page_size, offset]
        
        # Ejecutar la búsqueda
        authors = self.db.execute_query(search_query, search_params)
        
        # Obtener el total de resultados para la paginación
        count_query = """
            SELECT COUNT(*) as total
            FROM author 
            WHERE name LIKE %s 
                OR last_name1 LIKE %s 
                OR last_name2 LIKE %s
        """
        count_params = [f"%{search_term}%", f"%{search_term}%", f"%{search_term}%"]
        total_count = self.db.execute_query(count_query, count_params)[0]['total']
        
        return {
            'data': authors,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_items': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }