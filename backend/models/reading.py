from config.database import DatabaseConnection
from datetime import datetime

class ReadingModel:
    """
    Modelo para operaciones relacionadas con la lectura y progreso.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_reading_progress(self, user_nickname, book_title=None, page=1, page_size=10):
        """
        Obtiene el progreso de lectura de un usuario con paginación.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str, optional): Título del libro. Default is None.
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Progreso de lectura del usuario con metadatos de paginación
        """
        offset = (page - 1) * page_size
        query_params = [user_nickname]
        
        if book_title:
            query = """
                SELECT * FROM vw_reading_progress_detailed 
                WHERE user_nickname = %s AND book_title = %s 
                ORDER BY reading_date 
                LIMIT %s OFFSET %s
            """
            query_params.extend([book_title, page_size, offset])
            
            # Consulta para contar el total de registros
            count_query = """
                SELECT COUNT(*) as total FROM vw_reading_progress_detailed 
                WHERE user_nickname = %s AND book_title = %s
            """
            count_params = [user_nickname, book_title]
        else:
            query = """
                SELECT * FROM vw_reading_progress_detailed 
                WHERE user_nickname = %s 
                ORDER BY reading_date 
                LIMIT %s OFFSET %s
            """
            query_params.extend([page_size, offset])
            
            # Consulta para contar el total de registros
            count_query = """
                SELECT COUNT(*) as total FROM vw_reading_progress_detailed 
                WHERE user_nickname = %s
            """
            count_params = [user_nickname]
        
        progress = self.db.execute_query(query, query_params)
        total_count = self.db.execute_query(count_query, count_params)[0]['total']
        
        return {
            'data': progress,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_items': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }
    
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
    
    def delete_reading_progress(self, user_nickname, book_id):
        """
        Elimina el progreso de lectura de un libro específico para un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_id (int): ID del libro
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        try:
            # Obtener el ID del usuario
            user_query = "SELECT id FROM user WHERE nickName = %s"
            user_result = self.db.execute_query(user_query, [user_nickname])
            
            if not user_result:
                return False
                
            user_id = user_result[0]['id']
            
            # Eliminar todos los registros de progreso de lectura para este usuario y libro
            delete_query = "DELETE FROM reading_progress WHERE id_user = %s AND id_book = %s"
            result = self.db.execute_update(delete_query, [user_id, book_id])
            
            return result >= 0  # True si se eliminó al menos un registro o si no había registros
        except Exception as e:
            print(f"Error al eliminar progreso de lectura: {e}")
            return False
    
    def get_book_reviews(self, book_title=None, user_nickname=None, page=1, page_size=10):
        """
        Obtiene reseñas de libros con paginación.
        
        Args:
            book_title (str, optional): Título del libro. Default is None.
            user_nickname (str, optional): Nickname del usuario. Default is None.
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Reseñas que coinciden con los criterios con metadatos de paginación
        """
        offset = (page - 1) * page_size
        query_conditions = []
        query_params = []
        
        if book_title:
            query_conditions.append("book_title = %s")
            query_params.append(book_title)
            
        if user_nickname:
            query_conditions.append("user_nickname = %s")
            query_params.append(user_nickname)
        
        # Construir la consulta base
        query = "SELECT * FROM vw_book_reviews"
        count_query = "SELECT COUNT(*) as total FROM vw_book_reviews"
        
        if query_conditions:
            where_clause = " WHERE " + " AND ".join(query_conditions)
            query += where_clause
            count_query += where_clause
        
        # Añadir ordenación y paginación
        query += " ORDER BY review_date DESC LIMIT %s OFFSET %s"
        query_params.extend([page_size, offset])
        
        # Ejecutar consultas
        reviews = self.db.execute_query(query, query_params)
        total_count = self.db.execute_query(count_query, query_params[:-2])[0]['total']
        
        return {
            'data': reviews,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_items': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }
    
    def get_review_by_id(self, review_id):
        """
        Obtiene una reseña específica por su ID.
        
        Args:
            review_id (int): ID de la reseña
            
        Returns:
            dict: Información de la reseña o None si no existe
        """
        query = "SELECT * FROM vw_book_reviews WHERE review_id = %s"
        results = self.db.execute_query(query, [review_id])
        return results[0] if results else None
    
    def add_review(self, user_nickname, book_title, text, rating):
        """
        Añade una nueva reseña para un libro.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str): Título del libro
            text (str): Texto de la reseña
            rating (float): Calificación (1-10)
            
        Returns:
            dict: Información de la reseña creada o None si hubo un error
        """
        try:
            # Obtener el ID del usuario
            user_query = "SELECT id FROM user WHERE nickName = %s"
            user_result = self.db.execute_query(user_query, [user_nickname])
            
            if not user_result:
                return None
                
            user_id = user_result[0]['id']
            
            # Obtener el ID del libro
            book_query = "SELECT id FROM book WHERE title = %s"
            book_result = self.db.execute_query(book_query, [book_title])
            
            if not book_result:
                return None
                
            book_id = book_result[0]['id']
            
            # Verificar si ya existe una reseña para este usuario y libro
            check_query = "SELECT id FROM review WHERE id_user = %s AND id_book = %s"
            existing_review = self.db.execute_query(check_query, [user_id, book_id])
            
            if existing_review:
                # Actualizar reseña existente
                update_query = """
                    UPDATE review 
                    SET text = %s, rating = %s, date_created = CURDATE() 
                    WHERE id = %s
                """
                self.db.execute_update(update_query, [text, rating, existing_review[0]['id']])
                review_id = existing_review[0]['id']
            else:
                # Insertar nueva reseña
                insert_query = """
                    INSERT INTO review (text, rating, date_created, id_book, id_user) 
                    VALUES (%s, %s, CURDATE(), %s, %s)
                """
                self.db.execute_update(insert_query, [text, rating, book_id, user_id])
                
                # Obtener el ID de la reseña insertada
                review_id = self.db.get_last_id()
            
            # Retornar la reseña creada/actualizada
            return self.get_review_by_id(review_id)
        except Exception as e:
            print(f"Error al añadir reseña: {e}")
            return None
    
    def update_review(self, review_id, text=None, rating=None):
        """
        Actualiza una reseña existente.
        
        Args:
            review_id (int): ID de la reseña a actualizar
            text (str, optional): Nuevo texto de la reseña
            rating (float, optional): Nueva calificación
            
        Returns:
            dict: Información de la reseña actualizada o None si hubo un error
        """
        try:
            # Construir la consulta de actualización dinámica
            update_parts = []
            params = []
            
            if text is not None:
                update_parts.append("text = %s")
                params.append(text)
                
            if rating is not None:
                update_parts.append("rating = %s")
                params.append(rating)
            
            if not update_parts:
                # Si no hay nada que actualizar, simplemente retornar la reseña actual
                return self.get_review_by_id(review_id)
            
            # Añadir fecha de actualización
            update_parts.append("date_created = CURDATE()")
            
            # Completar la consulta
            query = f"UPDATE review SET {', '.join(update_parts)} WHERE id = %s"
            params.append(review_id)
            
            # Ejecutar la actualización
            self.db.execute_update(query, params)
            
            # Retornar la reseña actualizada
            return self.get_review_by_id(review_id)
        except Exception as e:
            print(f"Error al actualizar reseña: {e}")
            return None
    
    def delete_review(self, review_id):
        """
        Elimina una reseña por su ID.
        
        Args:
            review_id (int): ID de la reseña a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        try:
            # Eliminar la reseña
            query = "DELETE FROM review WHERE id = %s"
            result = self.db.execute_update(query, [review_id])
            
            return result > 0  # True si se eliminó al menos una fila
        except Exception as e:
            print(f"Error al eliminar reseña: {e}")
            return False
    
    def get_user_reading_stats(self, user_nickname):
        """
        Obtiene estadísticas de lectura para un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            dict: Estadísticas de lectura del usuario o None si no existe
        """
        query = "SELECT * FROM vw_user_reading_stats WHERE user_nickname = %s"
        results = self.db.execute_query(query, [user_nickname])
        return results[0] if results else None
    
    def get_phrases(self, book_title=None, user_nickname=None, page=1, page_size=10):
        """
        Obtiene frases destacadas con paginación.
        
        Args:
            book_title (str, optional): Título del libro. Default is None.
            user_nickname (str, optional): Nickname del usuario. Default is None.
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Frases destacadas que coinciden con los criterios con metadatos de paginación
        """
        offset = (page - 1) * page_size
        query_conditions = []
        query_params = []
        
        # Construir la consulta base
        query = """
            SELECT p.id, p.text, p.date_added, u.nickName as user_nickname, 
                   b.id as book_id, b.title as book_title
            FROM phrase p
            JOIN user u ON p.id_user = u.id
            JOIN book b ON p.id_book = b.id
        """
        
        count_query = "SELECT COUNT(*) as total FROM phrase p JOIN user u ON p.id_user = u.id JOIN book b ON p.id_book = b.id"
        
        if book_title:
            query_conditions.append("b.title = %s")
            query_params.append(book_title)
            
        if user_nickname:
            query_conditions.append("u.nickName = %s")
            query_params.append(user_nickname)
        
        if query_conditions:
            where_clause = " WHERE " + " AND ".join(query_conditions)
            query += where_clause
            count_query += where_clause
        
        # Añadir ordenación y paginación
        query += " ORDER BY p.date_added DESC LIMIT %s OFFSET %s"
        query_params.extend([page_size, offset])
        
        # Ejecutar consultas
        phrases = self.db.execute_query(query, query_params)
        total_count = self.db.execute_query(count_query, query_params[:-2])[0]['total']
        
        return {
            'data': phrases,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_items': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }
    
    def get_phrase_by_id(self, phrase_id):
        """
        Obtiene una frase destacada específica por su ID.
        
        Args:
            phrase_id (int): ID de la frase
            
        Returns:
            dict: Información de la frase o None si no existe
        """
        query = """
            SELECT p.id, p.text, p.date_added, u.nickName as user_nickname, 
                   b.id as book_id, b.title as book_title
            FROM phrase p
            JOIN user u ON p.id_user = u.id
            JOIN book b ON p.id_book = b.id
            WHERE p.id = %s
        """
        results = self.db.execute_query(query, [phrase_id])
        return results[0] if results else None
    
    def add_phrase(self, user_nickname, book_title, text):
        """
        Añade una nueva frase destacada para un libro.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str): Título del libro
            text (str): Texto de la frase
            
        Returns:
            dict: Información de la frase creada o None si hubo un error
        """
        try:
            # Obtener el ID del usuario
            user_query = "SELECT id FROM user WHERE nickName = %s"
            user_result = self.db.execute_query(user_query, [user_nickname])
            
            if not user_result:
                return None
                
            user_id = user_result[0]['id']
            
            # Obtener el ID del libro
            book_query = "SELECT id FROM book WHERE title = %s"
            book_result = self.db.execute_query(book_query, [book_title])
            
            if not book_result:
                return None
                
            book_id = book_result[0]['id']
            
            # Insertar nueva frase
            insert_query = """
                INSERT INTO phrase (text, id_book, id_user, date_added) 
                VALUES (%s, %s, %s, CURDATE())
            """
            self.db.execute_update(insert_query, [text, book_id, user_id])
            
            # Obtener el ID de la frase insertada
            phrase_id = self.db.get_last_id()
            
            # Retornar la frase creada
            return self.get_phrase_by_id(phrase_id)
        except Exception as e:
            print(f"Error al añadir frase: {e}")
            return None
    
    def update_phrase(self, phrase_id, text):
        """
        Actualiza una frase destacada existente.
        
        Args:
            phrase_id (int): ID de la frase a actualizar
            text (str): Nuevo texto de la frase
            
        Returns:
            dict: Información de la frase actualizada o None si hubo un error
        """
        try:
            # Actualizar la frase
            query = "UPDATE phrase SET text = %s, date_added = CURDATE() WHERE id = %s"
            self.db.execute_update(query, [text, phrase_id])
            
            # Retornar la frase actualizada
            return self.get_phrase_by_id(phrase_id)
        except Exception as e:
            print(f"Error al actualizar frase: {e}")
            return None
    
    def delete_phrase(self, phrase_id):
        """
        Elimina una frase destacada por su ID.
        
        Args:
            phrase_id (int): ID de la frase a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        try:
            # Eliminar la frase
            query = "DELETE FROM phrase WHERE id = %s"
            result = self.db.execute_update(query, [phrase_id])
            
            return result > 0  # True si se eliminó al menos una fila
        except Exception as e:
            print(f"Error al eliminar frase: {e}")
            return False
    
    def get_notes(self, book_title=None, user_nickname=None, page=1, page_size=10):
        """
        Obtiene notas de libros con paginación.
        
        Args:
            book_title (str, optional): Título del libro. Default is None.
            user_nickname (str, optional): Nickname del usuario. Default is None.
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            dict: Notas que coinciden con los criterios con metadatos de paginación
        """
        offset = (page - 1) * page_size
        query_conditions = []
        query_params = []
        
        # Construir la consulta base
        query = """
            SELECT n.id, n.text, n.date_created, n.date_modified, u.nickName as user_nickname, 
                   b.id as book_id, b.title as book_title
            FROM book_note n
            JOIN user u ON n.id_user = u.id
            JOIN book b ON n.id_book = b.id
        """
        
        count_query = "SELECT COUNT(*) as total FROM book_note n JOIN user u ON n.id_user = u.id JOIN book b ON n.id_book = b.id"
        
        if book_title:
            query_conditions.append("b.title = %s")
            query_params.append(book_title)
            
        if user_nickname:
            query_conditions.append("u.nickName = %s")
            query_params.append(user_nickname)
        
        if query_conditions:
            where_clause = " WHERE " + " AND ".join(query_conditions)
            query += where_clause
            count_query += where_clause
        
        # Añadir ordenación y paginación
        query += " ORDER BY COALESCE(n.date_modified, n.date_created) DESC LIMIT %s OFFSET %s"
        query_params.extend([page_size, offset])
        
        # Ejecutar consultas
        notes = self.db.execute_query(query, query_params)
        total_count = self.db.execute_query(count_query, query_params[:-2])[0]['total']
        
        return {
            'data': notes,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_items': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }
    
    def get_note_by_id(self, note_id):
        """
        Obtiene una nota específica por su ID.
        
        Args:
            note_id (int): ID de la nota
            
        Returns:
            dict: Información de la nota o None si no existe
        """
        query = """
            SELECT n.id, n.text, n.date_created, n.date_modified, u.nickName as user_nickname, 
                   b.id as book_id, b.title as book_title
            FROM book_note n
            JOIN user u ON n.id_user = u.id
            JOIN book b ON n.id_book = b.id
            WHERE n.id = %s
        """
        results = self.db.execute_query(query, [note_id])
        return results[0] if results else None
    
    def add_note(self, user_nickname, book_title, text):
        """
        Añade una nueva nota para un libro.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_title (str): Título del libro
            text (str): Texto de la nota
            
        Returns:
            dict: Información de la nota creada o None si hubo un error
        """
        try:
            # Obtener el ID del usuario
            user_query = "SELECT id FROM user WHERE nickName = %s"
            user_result = self.db.execute_query(user_query, [user_nickname])
            
            if not user_result:
                return None
                
            user_id = user_result[0]['id']
            
            # Obtener el ID del libro
            book_query = "SELECT id FROM book WHERE title = %s"
            book_result = self.db.execute_query(book_query, [book_title])
            
            if not book_result:
                return None
                
            book_id = book_result[0]['id']
            
            # Verificar si ya existe una nota para este usuario y libro
            check_query = "SELECT id FROM book_note WHERE id_user = %s AND id_book = %s"
            existing_note = self.db.execute_query(check_query, [user_id, book_id])
            
            if existing_note:
                # Actualizar nota existente
                update_query = """
                    UPDATE book_note 
                    SET text = %s, date_modified = CURDATE() 
                    WHERE id = %s
                """
                self.db.execute_update(update_query, [text, existing_note[0]['id']])
                note_id = existing_note[0]['id']
            else:
                # Insertar nueva nota
                insert_query = """
                    INSERT INTO book_note (text, id_book, id_user, date_created, date_modified) 
                    VALUES (%s, %s, %s, CURDATE(), NULL)
                """
                self.db.execute_update(insert_query, [text, book_id, user_id])
                
                # Obtener el ID de la nota insertada
                note_id = self.db.get_last_id()
            
            # Retornar la nota creada/actualizada
            return self.get_note_by_id(note_id)
        except Exception as e:
            print(f"Error al añadir nota: {e}")
            return None
    
    def update_note(self, note_id, text):
        """
        Actualiza una nota existente.
        
        Args:
            note_id (int): ID de la nota a actualizar
            text (str): Nuevo texto de la nota
            
        Returns:
            dict: Información de la nota actualizada o None si hubo un error
        """
        try:
            # Actualizar la nota
            query = "UPDATE book_note SET text = %s, date_modified = CURDATE() WHERE id = %s"
            self.db.execute_update(query, [text, note_id])
            
            # Retornar la nota actualizada
            return self.get_note_by_id(note_id)
        except Exception as e:
            print(f"Error al actualizar nota: {e}")
            return None
    
    def delete_note(self, note_id):
        """
        Elimina una nota por su ID.
        
        Args:
            note_id (int): ID de la nota a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        try:
            # Eliminar la nota
            query = "DELETE FROM book_note WHERE id = %s"
            result = self.db.execute_update(query, [note_id])
            
            return result > 0  # True si se eliminó al menos una fila
        except Exception as e:
            print(f"Error al eliminar nota: {e}")
            return False