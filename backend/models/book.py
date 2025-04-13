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
    
    def update_book(self, book_id, title=None, pages=None, synopsis=None, author_name=None, 
                    author_last_name1=None, author_last_name2=None, genre1=None, genre2=None, 
                    genre3=None, genre4=None, genre5=None, saga_name=None):
        """
        Actualiza la información básica de un libro.
        
        Args:
            book_id (int): ID del libro a actualizar
            title (str, optional): Nuevo título
            pages (int, optional): Nuevo número de páginas
            synopsis (str, optional): Nueva sinopsis
            author_name (str, optional): Nuevo nombre del autor
            author_last_name1 (str, optional): Nuevo primer apellido del autor
            author_last_name2 (str, optional): Nuevo segundo apellido del autor
            genre1-5 (str, optional): Nuevos géneros
            saga_name (str, optional): Nuevo nombre de la saga
            
        Returns:
            bool: True si la actualización fue exitosa, False en caso contrario
        """
        # Primero obtenemos la información actual del libro
        current_book = self.get_book_by_id(book_id)
        if not current_book:
            return False
        
        # Actualizar el libro básico (título y páginas)
        if title or pages:
            update_params = []
            query_parts = []
            
            if title:
                query_parts.append("title = %s")
                update_params.append(title)
            
            if pages:
                query_parts.append("pages = %s")
                update_params.append(pages)
            
            if query_parts:
                query = f"UPDATE book SET {', '.join(query_parts)} WHERE id = %s"
                update_params.append(book_id)
                self.db.execute_update(query, update_params)
        
        # Actualizar la sinopsis si se proporciona
        if synopsis:
            # Verificar si ya existe una sinopsis para este libro
            check_query = "SELECT id FROM synopsis WHERE id_book = %s"
            synopsis_result = self.db.execute_query(check_query, [book_id])
            
            if synopsis_result:
                # Actualizar sinopsis existente
                update_query = "UPDATE synopsis SET text = %s WHERE id_book = %s"
                self.db.execute_update(update_query, [synopsis, book_id])
            else:
                # Insertar nueva sinopsis
                insert_query = "INSERT INTO synopsis (text, id_book) VALUES (%s, %s)"
                self.db.execute_update(insert_query, [synopsis, book_id])
        
        # Actualizar el autor si se proporciona información
        if author_name:
            # Primero verificamos si ya existe un autor con esos datos
            check_author_query = """
                SELECT id FROM author 
                WHERE name = %s 
                AND (last_name1 = %s OR (last_name1 IS NULL AND %s IS NULL))
                AND (last_name2 = %s OR (last_name2 IS NULL AND %s IS NULL))
            """
            author_params = [author_name, author_last_name1, author_last_name1, 
                            author_last_name2, author_last_name2]
            author_result = self.db.execute_query(check_author_query, author_params)
            
            author_id = None
            if author_result:
                # Autor existente
                author_id = author_result[0]['id']
            else:
                # Crear nuevo autor
                insert_author_query = """
                    INSERT INTO author (name, last_name1, last_name2) 
                    VALUES (%s, %s, %s)
                """
                self.db.execute_update(insert_author_query, [author_name, author_last_name1, author_last_name2])
                # Obtener el ID del autor insertado
                author_id = self.db.get_last_id()
            
            # Actualizar la relación libro-autor
            # Primero eliminamos las relaciones existentes
            delete_query = "DELETE FROM book_has_author WHERE id_book = %s"
            self.db.execute_update(delete_query, [book_id])
            
            # Luego añadimos la nueva relación
            insert_relation_query = "INSERT INTO book_has_author (id_book, id_author) VALUES (%s, %s)"
            self.db.execute_update(insert_relation_query, [book_id, author_id])
        
        # Actualizar géneros si se proporcionan
        if any([genre1, genre2, genre3, genre4, genre5]):
            # Eliminar relaciones de género existentes
            delete_genres_query = "DELETE FROM book_has_genre WHERE id_book = %s"
            self.db.execute_update(delete_genres_query, [book_id])
            
            # Añadir nuevos géneros
            genres = [g for g in [genre1, genre2, genre3, genre4, genre5] if g]
            for genre in genres:
                # Verificar si el género existe
                check_genre_query = "SELECT id FROM genre WHERE name = %s"
                genre_result = self.db.execute_query(check_genre_query, [genre])
                
                genre_id = None
                if genre_result:
                    genre_id = genre_result[0]['id']
                else:
                    # Crear nuevo género
                    insert_genre_query = "INSERT INTO genre (name) VALUES (%s)"
                    self.db.execute_update(insert_genre_query, [genre])
                    genre_id = self.db.get_last_id()
                
                # Añadir relación libro-género
                insert_relation_query = "INSERT INTO book_has_genre (id_book, id_genre) VALUES (%s, %s)"
                self.db.execute_update(insert_relation_query, [book_id, genre_id])
        
        # Actualizar saga si se proporciona
        if saga_name:
            # Verificar si la saga existe
            check_saga_query = "SELECT id FROM saga WHERE name = %s"
            saga_result = self.db.execute_query(check_saga_query, [saga_name])
            
            saga_id = None
            if saga_result:
                saga_id = saga_result[0]['id']
            else:
                # Crear nueva saga
                insert_saga_query = "INSERT INTO saga (name) VALUES (%s)"
                self.db.execute_update(insert_saga_query, [saga_name])
                saga_id = self.db.get_last_id()
            
            # Eliminar relaciones de saga existentes
            delete_saga_query = "DELETE FROM book_has_saga WHERE id_book = %s"
            self.db.execute_update(delete_saga_query, [book_id])
            
            # Añadir nueva relación libro-saga
            insert_relation_query = "INSERT INTO book_has_saga (id_book, id_saga) VALUES (%s, %s)"
            self.db.execute_update(insert_relation_query, [book_id, saga_id])
        
        # Retornar el libro actualizado
        return self.get_book_by_id(book_id)
    
    def delete_book(self, book_id):
        """
        Elimina un libro por su ID.
        
        Args:
            book_id (int): ID del libro a eliminar
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        try:
            # Primero eliminamos las relaciones en otras tablas
            # Eliminar sinopsis
            self.db.execute_update("DELETE FROM synopsis WHERE id_book = %s", [book_id])
            
            # Eliminar relaciones en book_has_author
            self.db.execute_update("DELETE FROM book_has_author WHERE id_book = %s", [book_id])
            
            # Eliminar relaciones en book_has_genre
            self.db.execute_update("DELETE FROM book_has_genre WHERE id_book = %s", [book_id])
            
            # Eliminar relaciones en book_has_saga
            self.db.execute_update("DELETE FROM book_has_saga WHERE id_book = %s", [book_id])
            
            # Eliminar notas del libro
            self.db.execute_update("DELETE FROM book_note WHERE id_book = %s", [book_id])
            
            # Eliminar frases del libro
            self.db.execute_update("DELETE FROM phrase WHERE id_book = %s", [book_id])
            
            # Eliminar reseñas del libro
            self.db.execute_update("DELETE FROM review WHERE id_book = %s", [book_id])
            
            # Eliminar progreso de lectura
            self.db.execute_update("DELETE FROM reading_progress WHERE id_book = %s", [book_id])
            
            # Eliminar descripciones de usuario
            self.db.execute_update("DELETE FROM user_book_description WHERE id_book = %s", [book_id])
            
            # Eliminar relaciones usuario-libro
            self.db.execute_update("DELETE FROM user_has_book WHERE id_book = %s", [book_id])
            
            # Finalmente eliminamos el libro
            delete_query = "DELETE FROM book WHERE id = %s"
            self.db.execute_update(delete_query, [book_id])
            
            return True
        except Exception as e:
            print(f"Error al eliminar libro: {e}")
            return False
    
    def get_books_by_user(self, user_nickname, status=None, page=1, page_size=10):
        """
        Obtiene todos los libros asociados a un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            status (str, optional): Estado de lectura para filtrar
            page (int): Número de página
            page_size (int): Tamaño de la página
            
        Returns:
            list: Lista de libros del usuario
        """
        offset = (page - 1) * page_size
        query_params = [user_nickname]
        
        # Construir la consulta base
        query = """
            SELECT * FROM vw_user_reading_info
            WHERE user_nickname = %s
        """
        
        count_query = """
            SELECT COUNT(*) as total FROM vw_user_reading_info
            WHERE user_nickname = %s
        """
        
        # Añadir filtro por estado si se proporciona
        if status:
            query += " AND reading_status = %s"
            count_query += " AND reading_status = %s"
            query_params.append(status)
        
        # Añadir paginación
        query += " LIMIT %s OFFSET %s"
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
    
    def update_user_book_relationship(self, user_nickname, book_id, status=None, date_start=None, 
                                    date_ending=None, custom_description=None, review=None, 
                                    rating=None, phrases=None, notes=None):
        """
        Actualiza la relación entre un usuario y un libro.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_id (int): ID del libro
            status (str, optional): Nuevo estado de lectura
            date_start (str, optional): Nueva fecha de inicio de lectura
            date_ending (str, optional): Nueva fecha de finalización de lectura
            custom_description (str, optional): Nueva descripción personalizada
            review (str, optional): Nueva reseña
            rating (float, optional): Nueva calificación
            phrases (str, optional): Nuevas frases destacadas
            notes (str, optional): Nuevas notas
            
        Returns:
            bool: True si la actualización fue exitosa, False en caso contrario
        """
        try:
            # Obtener el ID del usuario
            user_query = "SELECT id FROM user WHERE nickName = %s"
            user_result = self.db.execute_query(user_query, [user_nickname])
            
            if not user_result:
                return False
            
            user_id = user_result[0]['id']
            
            # Verificar si existe la relación usuario-libro
            check_query = "SELECT 1 FROM user_has_book WHERE id_user = %s AND id_book = %s"
            relation_exists = self.db.execute_query(check_query, [user_id, book_id])
            
            if not relation_exists:
                return False
            
            # Actualizar estado y fechas si se proporcionan
            if status or date_start or date_ending:
                update_params = []
                query_parts = []
                
                if status:
                    # Obtener el ID del estado
                    status_query = "SELECT id FROM reading_status WHERE name = %s"
                    status_result = self.db.execute_query(status_query, [status])
                    
                    if status_result:
                        query_parts.append("id_status = %s")
                        update_params.append(status_result[0]['id'])
                
                if date_start:
                    query_parts.append("date_start = %s")
                    update_params.append(date_start)
                
                if date_ending:
                    query_parts.append("date_ending = %s")
                    update_params.append(date_ending)
                
                if query_parts:
                    query = f"UPDATE user_has_book SET {', '.join(query_parts)} WHERE id_user = %s AND id_book = %s"
                    update_params.extend([user_id, book_id])
                    self.db.execute_update(query, update_params)
            
            # Actualizar descripción personalizada
            if custom_description:
                # Verificar si ya existe una descripción
                check_query = "SELECT 1 FROM user_book_description WHERE id_user = %s AND id_book = %s"
                description_exists = self.db.execute_query(check_query, [user_id, book_id])
                
                if description_exists:
                    # Actualizar descripción existente
                    update_query = "UPDATE user_book_description SET custom_description = %s WHERE id_user = %s AND id_book = %s"
                    self.db.execute_update(update_query, [custom_description, user_id, book_id])
                else:
                    # Insertar nueva descripción
                    insert_query = "INSERT INTO user_book_description (id_user, id_book, custom_description) VALUES (%s, %s, %s)"
                    self.db.execute_update(insert_query, [user_id, book_id, custom_description])
            
            # Actualizar reseña y rating
            if review or rating:
                # Verificar si ya existe una reseña
                check_query = "SELECT id FROM review WHERE id_user = %s AND id_book = %s"
                review_result = self.db.execute_query(check_query, [user_id, book_id])
                
                if review_result:
                    # Actualizar reseña existente
                    update_params = []
                    query_parts = []
                    
                    if review:
                        query_parts.append("text = %s")
                        update_params.append(review)
                    
                    if rating:
                        query_parts.append("rating = %s")
                        update_params.append(rating)
                    
                    query_parts.append("date_created = CURDATE()")
                    
                    query = f"UPDATE review SET {', '.join(query_parts)} WHERE id = %s"
                    update_params.append(review_result[0]['id'])
                    self.db.execute_update(query, update_params)
                elif review and rating:
                    # Insertar nueva reseña
                    insert_query = "INSERT INTO review (text, rating, date_created, id_book, id_user) VALUES (%s, %s, CURDATE(), %s, %s)"
                    self.db.execute_update(insert_query, [review, rating, book_id, user_id])
            
            # Actualizar frases
            if phrases:
                # Verificar si ya existen frases
                check_query = "SELECT id FROM phrase WHERE id_user = %s AND id_book = %s"
                phrase_result = self.db.execute_query(check_query, [user_id, book_id])
                
                if phrase_result:
                    # Actualizar frases existentes
                    update_query = "UPDATE phrase SET text = %s, date_added = CURDATE() WHERE id = %s"
                    self.db.execute_update(update_query, [phrases, phrase_result[0]['id']])
                else:
                    # Insertar nuevas frases
                    insert_query = "INSERT INTO phrase (text, id_book, id_user, date_added) VALUES (%s, %s, %s, CURDATE())"
                    self.db.execute_update(insert_query, [phrases, book_id, user_id])
            
            # Actualizar notas
            if notes:
                # Verificar si ya existen notas
                check_query = "SELECT id FROM book_note WHERE id_user = %s AND id_book = %s"
                notes_result = self.db.execute_query(check_query, [user_id, book_id])
                
                if notes_result:
                    # Actualizar notas existentes
                    update_query = "UPDATE book_note SET text = %s, date_modified = CURDATE() WHERE id = %s"
                    self.db.execute_update(update_query, [notes, notes_result[0]['id']])
                else:
                    # Insertar nuevas notas
                    insert_query = "INSERT INTO book_note (text, id_book, id_user, date_created, date_modified) VALUES (%s, %s, %s, CURDATE(), NULL)"
                    self.db.execute_update(insert_query, [notes, book_id, user_id])
            
            return True
        except Exception as e:
            print(f"Error al actualizar relación usuario-libro: {e}")
            return False
    
    def remove_book_from_user(self, user_nickname, book_id):
        """
        Elimina un libro de la colección de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_id (int): ID del libro
            
        Returns:
            bool: True si la eliminación fue exitosa, False en caso contrario
        """
        try:
            # Asegurarse de que book_id es un entero
            book_id = int(book_id)
            
            # Obtener el ID del usuario
            user_query = "SELECT id FROM user WHERE nickName = %s"
            user_result = self.db.execute_query(user_query, [user_nickname])
            
            if not user_result:
                print(f"Usuario {user_nickname} no encontrado")
                return False
                
            user_id = user_result[0]['id']
            
            # Verificar si la relación existe antes de eliminar
            check_query = "SELECT 1 FROM user_has_book WHERE id_user = %s AND id_book = %s"
            exists = self.db.execute_query(check_query, [user_id, book_id])
            print(f"¿Relación existe antes de eliminar? {bool(exists)}")
            
            if not exists:
                print(f"La relación entre usuario {user_nickname} y libro {book_id} no existe")
                return False
            
            # Eliminar relaciones en otras tablas
            # Eliminar notas del libro para este usuario
            note_result = self.db.execute_update("DELETE FROM book_note WHERE id_user = %s AND id_book = %s", [user_id, book_id])
            print(f"Notas eliminadas: {note_result}")
            
            # Eliminar frases del libro para este usuario
            phrase_result = self.db.execute_update("DELETE FROM phrase WHERE id_user = %s AND id_book = %s", [user_id, book_id])
            print(f"Frases eliminadas: {phrase_result}")
            
            # Eliminar reseñas del libro para este usuario
            review_result = self.db.execute_update("DELETE FROM review WHERE id_user = %s AND id_book = %s", [user_id, book_id])
            print(f"Reseñas eliminadas: {review_result}")
            
            # Eliminar progreso de lectura para este usuario
            progress_result = self.db.execute_update("DELETE FROM reading_progress WHERE id_user = %s AND id_book = %s", [user_id, book_id])
            print(f"Progreso de lectura eliminado: {progress_result}")
            
            # Eliminar descripciones de usuario
            desc_result = self.db.execute_update("DELETE FROM user_book_description WHERE id_user = %s AND id_book = %s", [user_id, book_id])
            print(f"Descripciones eliminadas: {desc_result}")
            
            # Eliminar relación usuario-libro
            relation_result = self.db.execute_update("DELETE FROM user_has_book WHERE id_user = %s AND id_book = %s", [user_id, book_id])
            print(f"Relación usuario-libro eliminada: {relation_result}")
            
            # Verificar si la relación aún existe después de eliminar
            exists_after = self.db.execute_query(check_query, [user_id, book_id])
            print(f"¿Relación existe después de eliminar? {bool(exists_after)}")
            
            # Verificar si las operaciones fueron exitosas
            if relation_result == 0:
                print("No se eliminó ninguna fila de user_has_book")
                # Esto es inusual ya que verificamos que existe antes
                return False
            
            return True
        except Exception as e:
            print(f"Error al eliminar libro de la colección del usuario: {e}")
            import traceback
            traceback.print_exc()
            return False