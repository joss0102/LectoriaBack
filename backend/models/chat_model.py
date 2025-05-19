from config.database import DatabaseConnection
import logging
from utils.query_helper import build_conditional_query

logger = logging.getLogger('chat_model')

class ChatModel:
    """
    Modelo para operaciones relacionadas con el chat.
    """
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_chat_data(self, user_nickname):
        """
        Obtiene todos los datos necesarios para el chat de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            dict: Datos para el chat del usuario
        """
        try:
            user_profile = self._get_user_profile(user_nickname)
            if not user_profile:
                return None
            
            reading_stats = self._get_reading_stats(user_nickname)
            
            user_books = self._get_user_books(user_nickname)
            
            reading_goals = self._get_reading_goals(user_nickname)
            
            reading_progress = self._get_all_reading_progress(user_nickname)
            
            return {
                "user_profile": user_profile,
                "reading_stats": reading_stats,
                "user_books": user_books,
                "reading_goals": reading_goals,
                "reading_progress": reading_progress
            }
            
        except Exception as e:
            logger.error(f"Error al obtener datos de chat para {user_nickname}: {e}")
            return None
    
    def _get_user_profile(self, user_nickname):
        """
        Obtiene el perfil básico del usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            dict: Datos del perfil o None si no existe
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
            results = self.db.execute_query(query, [user_nickname])
            return results[0] if results else None
        except Exception as e:
            logger.error(f"Error al obtener perfil para {user_nickname}: {e}")
            return None
    
    def _get_reading_stats(self, user_nickname):
        """
        Obtiene estadísticas de lectura del usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            dict: Estadísticas de lectura o None si hay un error
        """
        try:
            query = """
                SELECT * FROM vw_user_reading_stats 
                WHERE user_nickname = %s 
                LIMIT 1
            """
            results = self.db.execute_query(query, [user_nickname])
            return results[0] if results else None
        except Exception as e:
            logger.error(f"Error al obtener estadísticas para {user_nickname}: {e}")
            return None
    
    def _get_user_books(self, user_nickname):
        """
        Obtiene la lista de libros del usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            list: Lista de libros o lista vacía si hay un error
        """
        try:
            query = """
                SELECT uhb.id_book, b.title, rs.name as status, 
                        uhb.date_added, uhb.date_start, uhb.date_ending,
                        COALESCE(SUM(rp.pages), 0) as pages_read,
                        b.pages as total_pages,
                        CASE WHEN b.pages > 0 
                            THEN ROUND((COALESCE(SUM(rp.pages), 0) / b.pages) * 100, 2)
                            ELSE 0
                        END as progress_percentage,
                        GROUP_CONCAT(DISTINCT CONCAT(a.name, ' ', 
                                    COALESCE(a.last_name1, ''), ' ', 
                                    COALESCE(a.last_name2, ''))
                                    SEPARATOR ', ') as authors,
                        GROUP_CONCAT(DISTINCT g.name SEPARATOR ', ') as genres,
                        GROUP_CONCAT(DISTINCT sg.name SEPARATOR ', ') as sagas,
                        MAX(r.rating) as rating,
                        MAX(r.text) as review
                FROM user u
                JOIN user_has_book uhb ON u.id = uhb.id_user
                JOIN book b ON uhb.id_book = b.id
                JOIN reading_status rs ON uhb.id_status = rs.id
                LEFT JOIN reading_progress rp ON (u.id = rp.id_user AND b.id = rp.id_book)
                LEFT JOIN book_has_author bha ON b.id = bha.id_book
                LEFT JOIN author a ON bha.id_author = a.id
                LEFT JOIN book_has_genre bhg ON b.id = bhg.id_book
                LEFT JOIN genre g ON bhg.id_genre = g.id
                LEFT JOIN book_has_saga bhs ON b.id = bhs.id_book
                LEFT JOIN saga sg ON bhs.id_saga = sg.id
                LEFT JOIN review r ON (u.id = r.id_user AND b.id = r.id_book)
                WHERE u.nickName = %s
                GROUP BY uhb.id_book, b.title, rs.name, uhb.date_added, 
                            uhb.date_start, uhb.date_ending, b.pages
                ORDER BY uhb.date_added DESC
            """
            return self.db.execute_query(query, [user_nickname])
        except Exception as e:
            logger.error(f"Error al obtener libros para {user_nickname}: {e}")
            return []
    
    def _get_reading_goals(self, user_nickname):
        """
        Obtiene las metas de lectura del usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            dict: Metas de lectura o None si hay un error
        """
        try:
            query = """
                SELECT rg.yearly, rg.monthly, rg.daily_pages,
                        (SELECT COUNT(*) FROM user_has_book uhb 
                        JOIN user u ON uhb.id_user = u.id
                        JOIN reading_status rs ON uhb.id_status = rs.id
                        WHERE u.nickName = %s AND rs.name = 'completed'
                        AND YEAR(uhb.date_ending) = YEAR(CURDATE())) as completed_books_this_year,
                        (SELECT COUNT(*) FROM user_has_book uhb 
                        JOIN user u ON uhb.id_user = u.id
                        JOIN reading_status rs ON uhb.id_status = rs.id
                        WHERE u.nickName = %s AND rs.name = 'completed'
                        AND MONTH(uhb.date_ending) = MONTH(CURDATE())
                        AND YEAR(uhb.date_ending) = YEAR(CURDATE())) as completed_books_this_month
                FROM reading_goals rg
                JOIN user u ON rg.id_user = u.id
                WHERE u.nickName = %s
                LIMIT 1
            """
            results = self.db.execute_query(query, [user_nickname, user_nickname, user_nickname])
            return results[0] if results else None
        except Exception as e:
            logger.error(f"Error al obtener metas para {user_nickname}: {e}")
            return None

    def _get_all_reading_progress(self, user_nickname):
        """
        Obtiene todo el progreso de lectura del usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            list: Lista completa de registros de progreso o lista vacía si hay un error
        """
        try:
            query = """
                SELECT rp.id, rp.date, rp.pages, b.title as book_title, b.id as book_id,
                        b.pages as total_pages,
                        (SELECT SUM(rp2.pages) FROM reading_progress rp2 
                            WHERE rp2.id_user = u.id 
                            AND rp2.id_book = b.id 
                            AND rp2.date <= rp.date) as cumulative_pages,
                        CASE WHEN b.pages > 0 
                            THEN ROUND(((SELECT SUM(rp2.pages) FROM reading_progress rp2 
                                        WHERE rp2.id_user = u.id 
                                        AND rp2.id_book = b.id 
                                        AND rp2.date <= rp.date) / b.pages) * 100, 2)
                            ELSE 0
                        END as cumulative_percentage,
                        GROUP_CONCAT(DISTINCT CONCAT(a.name, ' ', 
                                    COALESCE(a.last_name1, ''), ' ', 
                                    COALESCE(a.last_name2, ''))
                                    SEPARATOR ', ') as authors
                FROM reading_progress rp
                JOIN user u ON rp.id_user = u.id
                JOIN book b ON rp.id_book = b.id
                LEFT JOIN book_has_author bha ON b.id = bha.id_book
                LEFT JOIN author a ON bha.id_author = a.id
                WHERE u.nickName = %s
                GROUP BY rp.id, rp.date, rp.pages, b.title, b.id, b.pages
                ORDER BY rp.date DESC
            """
            return self.db.execute_query(query, [user_nickname])
        except Exception as e:
            logger.error(f"Error al obtener progreso de lectura para {user_nickname}: {e}")
            return []

    def get_reading_progress_paged(self, user_nickname, limit=50, offset=0):
        """
        Obtiene el progreso de lectura del usuario con paginación.
        
        Args:
            user_nickname (str): Nickname del usuario
            limit (int): Número máximo de registros a retornar
            offset (int): Desplazamiento para paginación
            
        Returns:
            dict: Progreso de lectura con metadatos de paginación
        """
        try:
            query = """
                SELECT rp.id, rp.date, rp.pages, b.title as book_title, b.id as book_id,
                        b.pages as total_pages,
                        (SELECT SUM(rp2.pages) FROM reading_progress rp2 
                            WHERE rp2.id_user = u.id 
                            AND rp2.id_book = b.id 
                            AND rp2.date <= rp.date) as cumulative_pages,
                        CASE WHEN b.pages > 0 
                            THEN ROUND(((SELECT SUM(rp2.pages) FROM reading_progress rp2 
                                        WHERE rp2.id_user = u.id 
                                        AND rp2.id_book = b.id 
                                        AND rp2.date <= rp.date) / b.pages) * 100, 2)
                            ELSE 0
                        END as cumulative_percentage,
                        GROUP_CONCAT(DISTINCT CONCAT(a.name, ' ', 
                                    COALESCE(a.last_name1, ''), ' ', 
                                    COALESCE(a.last_name2, ''))
                                    SEPARATOR ', ') as authors
                FROM reading_progress rp
                JOIN user u ON rp.id_user = u.id
                JOIN book b ON rp.id_book = b.id
                LEFT JOIN book_has_author bha ON b.id = bha.id_book
                LEFT JOIN author a ON bha.id_author = a.id
                WHERE u.nickName = %s
                GROUP BY rp.id, rp.date, rp.pages, b.title, b.id, b.pages
                ORDER BY rp.date DESC
                LIMIT %s OFFSET %s
            """
            
            count_query = """
                SELECT COUNT(*) as total FROM reading_progress rp
                JOIN user u ON rp.id_user = u.id
                WHERE u.nickName = %s
            """
            
            progress = self.db.execute_query(query, [user_nickname, limit, offset])
            total_count = self.db.execute_query(count_query, [user_nickname])[0]['total']
            
            return {
                "data": progress,
                "pagination": {
                    "limit": limit,
                    "offset": offset,
                    "total_items": total_count
                }
            }
        except Exception as e:
            logger.error(f"Error al obtener progreso de lectura paginado para {user_nickname}: {e}")
            return {"data": [], "pagination": {"limit": limit, "offset": offset, "total_items": 0}}

    def get_reading_history(self, user_nickname, book_id=None, start_date=None, end_date=None, limit=50, offset=0):
        """
        Obtiene el historial de lectura detallado de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            book_id (int, optional): ID del libro para filtrar
            start_date (str, optional): Fecha de inicio para filtrar (formato YYYY-MM-DD)
            end_date (str, optional): Fecha de fin para filtrar (formato YYYY-MM-DD)
            limit (int): Número máximo de registros a retornar
            offset (int): Desplazamiento para paginación
            
        Returns:
            dict: Historial de lectura con metadatos de paginación
        """
        try:
            conditions = ["u.nickName = %s"]
            params = [user_nickname]
            
            if book_id:
                conditions.append("b.id = %s")
                params.append(book_id)
            
            if start_date:
                conditions.append("rp.date >= %s")
                params.append(start_date)
            
            if end_date:
                conditions.append("rp.date <= %s")
                params.append(end_date)
            
            query = """
                SELECT rp.id, rp.date, rp.pages, b.title as book_title, b.id as book_id,
                        b.pages as total_pages,
                        (SELECT SUM(pages) FROM reading_progress 
                            WHERE id_user = u.id AND id_book = b.id) as total_pages_read,
                        CASE WHEN b.pages > 0 
                            THEN ROUND(((SELECT SUM(pages) FROM reading_progress 
                                        WHERE id_user = u.id AND id_book = b.id) / b.pages) * 100, 2)
                            ELSE 0
                        END as progress_percentage,
                        rs.name as reading_status,
                        GROUP_CONCAT(DISTINCT CONCAT(a.name, ' ', 
                                    COALESCE(a.last_name1, ''), ' ', 
                                    COALESCE(a.last_name2, ''))
                                    SEPARATOR ', ') as authors
                FROM reading_progress rp
                JOIN user u ON rp.id_user = u.id
                JOIN book b ON rp.id_book = b.id
                LEFT JOIN book_has_author bha ON b.id = bha.id_book
                LEFT JOIN author a ON bha.id_author = a.id
                LEFT JOIN user_has_book uhb ON (u.id = uhb.id_user AND b.id = uhb.id_book)
                LEFT JOIN reading_status rs ON uhb.id_status = rs.id
            """
            
            where_clause = " WHERE " + " AND ".join(conditions)
            group_by = """ 
                GROUP BY rp.id, rp.date, rp.pages, b.title, b.id, b.pages, 
                        total_pages_read, reading_status
            """
            order_by = " ORDER BY rp.date DESC"
            limit_clause = " LIMIT %s OFFSET %s"
            
            full_query = query + where_clause + group_by + order_by + limit_clause
            count_query = f"SELECT COUNT(*) as total FROM reading_progress rp JOIN user u ON rp.id_user = u.id JOIN book b ON rp.id_book = b.id {where_clause}"
            
            params.extend([limit, offset])
            
            history = self.db.execute_query(full_query, params)
            total_count = self.db.execute_query(count_query, params[:-2])[0]['total']
            
            return {
                "data": history,
                "pagination": {
                    "limit": limit,
                    "offset": offset,
                    "total_items": total_count
                }
            }
        except Exception as e:
            logger.error(f"Error al obtener historial de lectura para {user_nickname}: {e}")
            return {"data": [], "pagination": {"limit": limit, "offset": offset, "total_items": 0}}

    def get_daily_reading_stats(self, user_nickname, days=30):
        """
        Obtiene estadísticas de lectura diaria del usuario para los últimos N días.
        
        Args:
            user_nickname (str): Nickname del usuario
            days (int): Número de días a retornar
            
        Returns:
            list: Lista de estadísticas diarias
        """
        try:
            query = """
                SELECT DATE(rp.date) as reading_date, 
                        SUM(rp.pages) as pages_read,
                        COUNT(DISTINCT rp.id_book) as books_read,
                        GROUP_CONCAT(DISTINCT b.title SEPARATOR ', ') as book_titles
                FROM reading_progress rp
                JOIN user u ON rp.id_user = u.id
                JOIN book b ON rp.id_book = b.id
                WHERE u.nickName = %s
                AND rp.date >= DATE_SUB(CURDATE(), INTERVAL %s DAY)
                GROUP BY DATE(rp.date)
                ORDER BY reading_date DESC
            """
            return self.db.execute_query(query, [user_nickname, days])
        except Exception as e:
            logger.error(f"Error al obtener estadísticas diarias para {user_nickname}: {e}")
            return []
