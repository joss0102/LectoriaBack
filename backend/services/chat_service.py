from models.chat_model import ChatModel

class ChatService:
    """
    Servicio para operaciones relacionadas con el chat.
    Implementa la lógica de negocio.
    """
    def __init__(self):
        self.chat_model = ChatModel()
    
    def get_chat_data(self, user_nickname):
        """
        Obtiene todos los datos necesarios para el chat de un usuario.
        
        Args:
            user_nickname (str): Nickname del usuario
            
        Returns:
            dict: Datos para el chat del usuario
        """
        return self.chat_model.get_chat_data(user_nickname)
    
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
        return self.chat_model.get_reading_progress_paged(user_nickname, limit, offset)
    
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
        return self.chat_model.get_reading_history(user_nickname, book_id, start_date, end_date, limit, offset)
    
    def get_daily_reading_stats(self, user_nickname, days=30):
        """
        Obtiene estadísticas de lectura diaria del usuario para los últimos N días.
        
        Args:
            user_nickname (str): Nickname del usuario
            days (int): Número de días a retornar
            
        Returns:
            list: Lista de estadísticas diarias
        """
        return self.chat_model.get_daily_reading_stats(user_nickname, days)
    
    
    def process_query(self, query, user_nicknamee):
        """
        Procesa una consulta de chat utilizando un sistema híbrido de reglas
        avanzadas y modelo de lenguaje cuando está disponible.
        
        Args:
            query (str): La pregunta o consulta del usuario
            user_nickname (str): Nickname del usuario
            
        Returns:
            str: Respuesta generada para la consulta
        """
        try:
            chat_data = self.get_chat_data(user_nickname)
            if not chat_data:
                return "No puedo encontrar tus datos de lectura. Por favor, intenta más tarde."
            
            advanced_rule_response = self._analyze_query_advanced(query, chat_data)
            if advanced_rule_response:
                return advanced_rule_response
            
            try:
                from transformers import pipeline, AutoModelForCausalLM, AutoTokenizer
                import torch
                has_transformers = True
            except ImportError:
                has_transformers = False
            
            if has_transformers:
                try:
                    if not hasattr(self, '_nlp_model') or self._nlp_model is None:
                        model_name = "distilgpt2"
                        
                        device = 0 if torch.cuda.is_available() else -1
                        
                        self._tokenizer = AutoTokenizer.from_pretrained(model_name)
                        self._model = AutoModelForCausalLM.from_pretrained(model_name)
                        self._nlp_model = pipeline('text-generation', 
                                                model=self._model, 
                                                tokenizer=self._tokenizer,
                                                device=device)
                        
                        print("Modelo de lenguaje cargado correctamente.")
                    
                    context = self._prepare_model_context(query, chat_data)
                    
                    result = self._nlp_model(context, 
                                            max_length=len(context.split()) + 100,
                                            num_return_sequences=1,
                                            pad_token_id=self._tokenizer.eos_token_id,
                                            do_sample=True,
                                            top_k=50,
                                            top_p=0.95,
                                            temperature=0.8)
                    
                    generated_text = result[0]['generated_text']
                    response_parts = generated_text.split("Respuesta:")
                    
                    if len(response_parts) > 1:
                        response = response_parts[1].strip()
                        
                        if len(response) > 10 and not any(marker in response for marker in ['[', '<', '{']):
                            return response
                except Exception as model_error:
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.error(f"Error al usar el modelo: {model_error}")
            
            basic_rule_response = self._process_query_rules_based(query, chat_data)
            if basic_rule_response:
                return basic_rule_response
            
            return self._generate_generic_response(chat_data)
            
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error general al procesar consulta: {e}")
            return "Lo siento, ocurrió un error al procesar tu consulta. Por favor, intenta nuevamente."

    def _prepare_model_context(self, query, chat_data):
        """
        Prepara un contexto personalizado para el modelo de lenguaje
        basado en la consulta del usuario.
        
        Args:
            query (str): Consulta del usuario
            chat_data (dict): Datos de lectura del usuario
            
        Returns:
            str: Prompt completo para el modelo
        """
        import json
        from decimal import Decimal
        
        class CustomJSONEncoder(json.JSONEncoder):
            def default(self, obj):
                if isinstance(obj, Decimal):
                    return float(obj)
                elif hasattr(obj, 'strftime'):
                    return obj.strftime('%Y-%m-%d')
                return super().default(obj)
        
        context = {
            "usuario": user_nickname if 'user_nickname' in locals() else chat_data['user_profile']['nickName'],
            "estadisticas": {
                "libros_completados": int(chat_data['reading_stats']['completed_books']),
                "libros_leyendo": int(chat_data['reading_stats']['reading_books']),
                "libros_pendientes": int(chat_data['reading_stats']['planned_books']),
                "autor_favorito": chat_data['reading_stats']['favorite_author'],
                "genero_favorito": chat_data['reading_stats']['favorite_genre'],
                "valoracion_media": float(chat_data['reading_stats']['average_rating']),
                "paginas_por_dia": float(chat_data['reading_stats']['avg_pages_per_day']),
                "total_paginas_leidas": int(chat_data['reading_stats']['total_pages_read_sessions'])
            },
            "metas": {
                "mensual": int(chat_data['reading_goals']['monthly']),
                "anual": int(chat_data['reading_goals']['yearly']),
                "libros_completados_este_mes": int(chat_data['reading_goals']['completed_books_this_month']),
                "libros_completados_este_anio": int(chat_data['reading_goals']['completed_books_this_year'])
            }
        }
        
        query_lower = query.lower()
        
        if any(word in query_lower for word in ['libro', 'leí', 'leyendo', 'leer', 'título']):
            current_book = next((book for book in chat_data['user_books'] if book['status'] == 'reading'), None)
            if current_book:
                context["libro_actual"] = {
                    "titulo": current_book['title'],
                    "autor": current_book['authors'],
                    "paginas_leidas": int(current_book['pages_read']),
                    "paginas_totales": int(current_book['total_pages']),
                    "porcentaje": float(current_book['progress_percentage'])
                }
            
            completed_books = [book for book in chat_data['user_books'] 
                                if book['status'] == 'completed' and book['date_ending']]
            if completed_books:
                completed_books.sort(key=lambda x: x['date_ending'], reverse=True)
                context["ultimos_libros"] = [{
                    "titulo": book['title'],
                    "autor": book['authors'],
                    "fecha_fin": book['date_ending'].strftime('%d/%m/%Y') if book['date_ending'] else "desconocida"
                } for book in completed_books[:3]]
        
        if any(word in query_lower for word in ['reseña', 'opinión', 'review', 'valoración', 'rating']):
            rated_books = [book for book in chat_data['user_books'] if book['rating'] is not None]
            if rated_books:
                rated_books.sort(key=lambda x: x['rating'], reverse=True)
                context["libros_valorados"] = [{
                    "titulo": book['title'],
                    "autor": book['authors'],
                    "valoracion": float(book['rating']),
                    "resenia": book['review'] if book['review'] else "Sin reseña"
                } for book in rated_books[:3]]
        
        context_json = json.dumps(context, indent=2, ensure_ascii=False, cls=CustomJSONEncoder)
        
        prompt = f"""
        Eres un asistente de lectura que responde consultas sobre los datos de lectura del usuario.
        
        Información del usuario:
        {context_json}
        
        Pregunta: {query}
        
        Respuesta:
        """
        
        return prompt

    def _analyze_query_advanced(self, query, chat_data):
        """
        Sistema avanzado basado en reglas que analiza la consulta
        y genera una respuesta personalizada.
        """
        import re
        from datetime import datetime, timedelta
        from difflib import SequenceMatcher
        
        import unicodedata
        def normalize_text(text):
            text = text.lower()
            text = ''.join(c for c in unicodedata.normalize('NFD', text) 
                        if unicodedata.category(c) != 'Mn')
            return text
            
        query_normalized = normalize_text(query)
        
        def find_book_by_title(query_text, books):
            for book in books:
                book_title_norm = normalize_text(book['title'])
                if book_title_norm == query_text:
                    return book, 1.0
            
            for book in books:
                book_title_norm = normalize_text(book['title'])
                if book_title_norm in query_text:
                    if len(book_title_norm) > 5 and len(book_title_norm) / len(query_text) > 0.3:
                        return book, 0.9
            
            for book in books:
                book_title_norm = normalize_text(book['title'])
                if query_text in book_title_norm and len(query_text) > 5:
                    return book, 0.8
            
            for book in books:
                book_title_norm = normalize_text(book['title'])
                query_words = set([w for w in query_text.split() if len(w) > 3])
                title_words = set([w for w in book_title_norm.split() if len(w) > 3])
                if query_words and title_words:
                    common_words = query_words.intersection(title_words)
                    if len(common_words) >= 2 or (len(common_words) == 1 and len(title_words) == 1):
                        return book, 0.75
            
            best_match = None
            best_ratio = 0.0
            
            for book in books:
                book_title_norm = normalize_text(book['title'])
                ratio = SequenceMatcher(None, book_title_norm, query_text).ratio()
                
                if ratio > best_ratio and ratio >= 0.6:
                    best_ratio = ratio
                    best_match = book
            
            if best_match:
                return best_match, best_ratio
            
            return None, 0.0
        
        book_number_match = re.search(r'(\d+)[º°]?\s*(?:libro|lectura)|(?:libro|lectura)\s*(?:n[úu]mero\s*)?(\d+|#\d+)', query_normalized)
        if book_number_match:
            book_number = None
            groups = book_number_match.groups()
            for group in groups:
                if group:
                    try:
                        cleaned = re.sub(r'[^\d]', '', group)
                        book_number = int(cleaned)
                        break
                    except:
                        pass
            
            if book_number:
                completed_books = [book for book in chat_data['user_books'] 
                                if book['status'] == 'completed' and book['date_ending']]
                
                if completed_books:
                    completed_books.sort(key=lambda x: x['date_ending'])
                    
                    if 1 <= book_number <= len(completed_books):
                        book = completed_books[book_number - 1]
                        response = f"Tu libro número {book_number} fue \"{book['title']}\" de {book['authors']}"
                        
                        if book['date_ending']:
                            response += f", que terminaste de leer el {book['date_ending'].strftime('%d/%m/%Y')}"
                        
                        if book['rating']:
                            response += f". Le diste una calificación de {book['rating']}/10"
                        
                        return response + "."
                    else:
                        return f"Solo has leído {len(completed_books)} libros, por lo que no tienes un libro número {book_number} registrado."
                else:
                    return "No tienes registros de libros completados en tu historial de lectura."
        
        if re.search(r'(cu[aá]nto|tiempo|tard[eé]|dur[oa]|d[ií]as).*(le[eí]|termin|complet)', query_normalized):
            mentioned_book, match_ratio = find_book_by_title(query_normalized, chat_data['user_books'])
            
            if mentioned_book:
                if mentioned_book['date_start'] and mentioned_book['date_ending']:
                    days_taken = (mentioned_book['date_ending'] - mentioned_book['date_start']).days + 1
                    avg_pages_per_day = mentioned_book['total_pages'] / days_taken
                    
                    return f"Tardaste {days_taken} días en leer \"{mentioned_book['title']}\", desde {mentioned_book['date_start'].strftime('%d/%m/%Y')} hasta {mentioned_book['date_ending'].strftime('%d/%m/%Y')}. En promedio, leíste {avg_pages_per_day:.1f} páginas por día de este libro."
                else:
                    if mentioned_book['status'] == 'completed':
                        return f"Has leído \"{mentioned_book['title']}\", pero no tengo registradas las fechas exactas de inicio y fin de lectura."
                    elif mentioned_book['status'] == 'reading':
                        if mentioned_book['date_start']:
                            days_so_far = (datetime.now().date() - mentioned_book['date_start']).days + 1
                            return f"Llevas {days_so_far} días leyendo \"{mentioned_book['title']}\". Has leído {mentioned_book['pages_read']} de {mentioned_book['total_pages']} páginas ({mentioned_book['progress_percentage']}%)."
                        else:
                            return f"Estás leyendo \"{mentioned_book['title']}\". Has leído {mentioned_book['pages_read']} de {mentioned_book['total_pages']} páginas ({mentioned_book['progress_percentage']}%), pero no tengo registrada la fecha en que comenzaste."
                    else:
                        return f"\"{mentioned_book['title']}\" está en tu lista con estado \"{mentioned_book['status']}\", pero no tengo datos sobre tu tiempo de lectura."
            else:
                completed_with_dates = [book for book in chat_data['user_books'] 
                                    if book['status'] == 'completed' and book['date_start'] and book['date_ending']]
                
                if completed_with_dates:
                    total_days = sum([(book['date_ending'] - book['date_start']).days + 1 for book in completed_with_dates])
                    avg_days_per_book = total_days / len(completed_with_dates)
                    
                    fastest_book = min(completed_with_dates, key=lambda x: (x['date_ending'] - x['date_start']).days + 1)
                    slowest_book = max(completed_with_dates, key=lambda x: (x['date_ending'] - x['date_start']).days + 1)
                    
                    fastest_days = (fastest_book['date_ending'] - fastest_book['date_start']).days + 1
                    slowest_days = (slowest_book['date_ending'] - slowest_book['date_start']).days + 1
                    
                    return f"En promedio tardas {avg_days_per_book:.1f} días en leer un libro. El libro que leíste más rápido fue \"{fastest_book['title']}\" ({fastest_days} días) y el que te tomó más tiempo fue \"{slowest_book['title']}\" ({slowest_days} días)."
                else:
                    return "No tengo suficientes datos con fechas de inicio y fin para calcular tus tiempos de lectura."
        
        if re.search(r'(rese[ñn]a|review|opini[óo]n|piens|parec|valo|calific)', query_normalized):
            mentioned_book, match_ratio = find_book_by_title(query_normalized, chat_data['user_books'])
            
            if mentioned_book:
                if mentioned_book['rating'] and mentioned_book['review']:
                    return f"Tu reseña de \"{mentioned_book['title']}\" tiene una calificación de {mentioned_book['rating']}/10: \"{mentioned_book['review']}\""
                elif mentioned_book['rating']:
                    return f"Le diste a \"{mentioned_book['title']}\" una calificación de {mentioned_book['rating']}/10, pero no escribiste una reseña detallada."
                else:
                    return f"No has escrito ninguna reseña ni calificación para \"{mentioned_book['title']}\"."
            else:
                rated_books = [book for book in chat_data['user_books'] if book['rating'] is not None]
                if rated_books:
                    rated_books.sort(key=lambda x: x['rating'], reverse=True)
                    best_book = rated_books[0]
                    worst_book = rated_books[-1] if len(rated_books) > 1 else None
                    
                    response = f"Has calificado {len(rated_books)} libros. Tu libro mejor valorado es \"{best_book['title']}\" con {best_book['rating']}/10"
                    
                    if worst_book and worst_book['rating'] < best_book['rating']:
                        response += f", y el que menos te gustó fue \"{worst_book['title']}\" con {worst_book['rating']}/10"
                    
                    return response + "."
                else:
                    return "No has calificado ningún libro todavía, por lo que no puedo mostrarte reseñas."
        
        if len(query_normalized.split()) <= 5:
            mentioned_book, match_ratio = find_book_by_title(query_normalized, chat_data['user_books'])
            
            if mentioned_book and match_ratio > 0.7:
                response = f"Sobre \"{mentioned_book['title']}\" de {mentioned_book['authors']}: "
                
                if mentioned_book['status'] == 'completed':
                    response += f"Lo terminaste de leer"
                    if mentioned_book['date_ending']:
                        response += f" el {mentioned_book['date_ending'].strftime('%d/%m/%Y')}"
                    response += "."
                elif mentioned_book['status'] == 'reading':
                    response += f"Lo estás leyendo actualmente. Has leído {mentioned_book['pages_read']} páginas ({mentioned_book['progress_percentage']}%)."
                elif mentioned_book['status'] == 'plan_to_read':
                    response += "Está en tu lista de lecturas pendientes."
                
                if mentioned_book['rating']:
                    response += f" Le diste una calificación de {mentioned_book['rating']}/10."
                    
                if mentioned_book['review']:
                    response += f" Tu reseña: \"{mentioned_book['review']}\""
                
                return response
        
        if re.search(r'(genero|generos|categoria|tipo|estilo).*(libro|pertenece)', query_normalized) and not re.search(r'favorit', query_normalized):
            mentioned_book, match_ratio = find_book_by_title(query_normalized, chat_data['user_books'])
            
            if mentioned_book and 'genres' in mentioned_book and mentioned_book['genres']:
                return f"El libro \"{mentioned_book['title']}\" pertenece a los géneros: {mentioned_book['genres']}."
            elif mentioned_book:
                return f"No tengo información sobre los géneros específicos del libro \"{mentioned_book['title']}\"."
            else:
                return f"Tu género favorito es {chat_data['reading_stats']['favorite_genre']} según tus datos de lectura."
        
        if re.search(r'(autor|escritor).*(mas|más).*(le[íi]do|libro)', query_normalized):
            author_counts = {}
            for book in chat_data['user_books']:
                if book['status'] == 'completed':
                    if book['authors'] in author_counts:
                        author_counts[book['authors']] += 1
                    else:
                        author_counts[book['authors']] = 1
            
            if author_counts:
                top_author = max(author_counts.items(), key=lambda x: x[1])
                return f"El autor del que has leído más libros es {top_author[0]}, con un total de {top_author[1]} libros completados."
            else:
                return "No hay suficientes datos para determinar el autor con más libros leídos."
        
        if re.search(r'(saga|serie|coleccion|trilog).*(favorit|prefer|gust|mejor|más|mas)', query_normalized):
            saga_counts = {}
            for book in chat_data['user_books']:
                if 'sagas' in book and book['sagas'] and book['status'] == 'completed':
                    if book['sagas'] in saga_counts:
                        saga_counts[book['sagas']] += 1
                    else:
                        saga_counts[book['sagas']] = 1
            
            if saga_counts:
                favorite_saga = max(saga_counts.items(), key=lambda x: x[1])
                return f"Tu saga favorita parece ser '{favorite_saga[0]}', de la cual has leído {favorite_saga[1]} libros."
            else:
                return "No puedo determinar tu saga favorita ya que no tienes libros asignados a sagas o series."
        
        if re.search(r'(libro|lectura).*(mas|más).*(larg|extens|pag|págin|grand)', query_normalized):
            completed_books = [book for book in chat_data['user_books'] if book['status'] == 'completed']
            if completed_books:
                completed_books.sort(key=lambda x: x['total_pages'], reverse=True)
                longest_book = completed_books[0]
                return f"El libro más largo que has leído es \"{longest_book['title']}\" de {longest_book['authors']} con {longest_book['total_pages']} páginas."
            else:
                return "No has completado ningún libro todavía, por lo que no puedo determinar cuál es el más largo."
        
        if re.search(r'(libro|lectura).*(mas|más).*(cort|brev|men|poc).*(pag|págin)', query_normalized):
            completed_books = [book for book in chat_data['user_books'] if book['status'] == 'completed']
            if completed_books:
                completed_books.sort(key=lambda x: x['total_pages'])
                shortest_book = completed_books[0]
                return f"El libro más corto que has leído es \"{shortest_book['title']}\" de {shortest_book['authors']} con {shortest_book['total_pages']} páginas."
            else:
                return "No has completado ningún libro todavía, por lo que no puedo determinar cuál es el más corto."
        
        if re.search(r'(racha|streak|dias sin leer|tiempo sin|consecutiv)', query_normalized):
            reading_dates = []
            for progress in chat_data['reading_progress']:
                reading_dates.append(progress['date'])
            
            if reading_dates:
                reading_dates.sort()
                
                current_streak = 1
                max_streak = 1
                max_streak_end = reading_dates[0]
                
                for i in range(1, len(reading_dates)):
                    if reading_dates[i] - reading_dates[i-1] == timedelta(days=1):
                        current_streak += 1
                        if current_streak > max_streak:
                            max_streak = current_streak
                            max_streak_end = reading_dates[i]
                    else:
                        current_streak = 1
                
                max_streak_start = max_streak_end - timedelta(days=max_streak-1)
                
                today = datetime.now().date()
                recent_dates = [date for date in reading_dates if date <= today]
                
                if recent_dates:
                    most_recent = max(recent_dates)
                    days_since = (today - most_recent).days
                    
                    if days_since == 0:
                        current_streak_msg = "Actualmente mantienes una racha activa. Has leído hoy."
                    else:
                        current_streak_msg = f"Han pasado {days_since} días desde tu última sesión de lectura."
                    
                    return f"Tu racha de lectura más larga fue de {max_streak} días consecutivos, desde {max_streak_start.strftime('%d/%m/%Y')} hasta {max_streak_end.strftime('%d/%m/%Y')}. {current_streak_msg}"
                else:
                    return f"Tu racha de lectura más larga fue de {max_streak} días consecutivos, desde {max_streak_start.strftime('%d/%m/%Y')} hasta {max_streak_end.strftime('%d/%m/%Y')}. No tienes ninguna racha activa actualmente."
            else:
                return "No tengo suficientes datos para calcular tus rachas de lectura."
        
        return None

    def _process_query_rules_based(self, query, chat_data):
        """
        Sistema de respaldo basado en reglas para consultas más simples y comunes.
        
        Args:
            query (str): Consulta del usuario
            chat_data (dict): Datos de lectura del usuario
            
        Returns:
            str: Respuesta basada en reglas o None si no se identificó la intención
        """
        import unicodedata
        
        def normalize_text(text):
            text = text.lower()
            text = ''.join(c for c in unicodedata.normalize('NFD', text) 
                        if unicodedata.category(c) != 'Mn')
            return text
            
        query_normalized = normalize_text(query)
        
        # Palabras clave para diferentes tipos de consultas
        keywords = {
            'estadisticas': ['estadisticas', 'estadistica', 'estads', 'resumen', 'datos', 'numeros'],
            'libros_leidos': ['cuantos', 'libros', 'leidos', 'completados', 'terminados', 'finalizados'],
            'autor_favorito': ['autor', 'autores', 'escritor', 'escritores', 'favorito'],
            'genero_favorito': ['genero', 'generos', 'categoria', 'categorias', 'tipo', 'favorito'],
            'libro_favorito': ['libro favorito', 'mejor libro', 'libro preferido', 'mejor valorado'],
            'promedio_paginas': ['paginas', 'pagina', 'dia', 'diarias', 'promedio', 'velocidad'],
            'libro_actual': ['leyendo', 'actual', 'ahora', 'actualmente', 'libro actual'],
            'metas': ['meta', 'metas', 'objetivo', 'objetivos', 'proposito', 'plan'],
            'ultimo_libro': ['ultimo', 'reciente', 'terminado', 'completado', 'acabado'],
            'primer_libro': ['primer', 'primero', 'inicial', 'empezaste', 'comienzo', 'comenzaste']
        }
        
        def has_keywords(text, keyword_list):
            for keyword in keyword_list:
                if keyword in text:
                    return True
            return False
        
        if any(word in query_normalized for word in ['favorito', 'preferido', 'gusta', 'encanta', 'mejor']):
            if 'libro' in query_normalized:
                rated_books = [book for book in chat_data['user_books'] if book['rating'] is not None]
                if rated_books:
                    rated_books.sort(key=lambda x: x['rating'], reverse=True)
                    best_book = rated_books[0]
                    return f"Tu libro favorito es \"{best_book['title']}\" de {best_book['authors']} con una calificación de {best_book['rating']}/10."
                else:
                    return "Aún no has calificado ningún libro, por lo que no puedo determinar tu favorito."
            elif 'autor' in query_normalized:
                return f"Tu autor favorito es {chat_data['reading_stats']['favorite_author']} según tus datos de lectura."
            elif 'genero' in query_normalized:
                return f"Tu género favorito es {chat_data['reading_stats']['favorite_genre']} según tus datos de lectura."
        
        if has_keywords(query_normalized, keywords['estadisticas']):
            stats = chat_data['reading_stats']
            return f"Has leído {stats['completed_books']} libros completados, con un total de {stats['total_pages_read_completed']} páginas. Tu autor favorito es {stats['favorite_author']} y tu género favorito es {stats['favorite_genre']}. Tu puntuación media es {stats['average_rating']}/10."
        
        if has_keywords(query_normalized, keywords['libros_leidos']):
            return f"Has completado {chat_data['reading_stats']['completed_books']} libros hasta ahora."
        
        if has_keywords(query_normalized, keywords['libro_actual']):
            current_book = next((book for book in chat_data['user_books'] if book['status'] == 'reading'), None)
            if current_book:
                return f"Actualmente estás leyendo \"{current_book['title']}\" de {current_book['authors']}. Has leído {current_book['pages_read']} páginas ({current_book['progress_percentage']}%)."
            else:
                return "No parece que estés leyendo ningún libro en este momento."
        
        if has_keywords(query_normalized, keywords['ultimo_libro']):
            completed_books = [book for book in chat_data['user_books'] if book['status'] == 'completed' and book['date_ending']]
            if completed_books:
                completed_books.sort(key=lambda x: x['date_ending'], reverse=True)
                last_book = completed_books[0]
                return f"El último libro que terminaste fue \"{last_book['title']}\" de {last_book['authors']}."
            else:
                return "No hay registros de libros completados recientemente."
        
        if has_keywords(query_normalized, keywords['primer_libro']):
            completed_books = [book for book in chat_data['user_books'] if book['status'] == 'completed' and book['date_ending']]
            if completed_books:
                completed_books.sort(key=lambda x: x['date_ending'])
                first_book = completed_books[0]
                return f"Tu primer libro registrado fue \"{first_book['title']}\" de {first_book['authors']}, que terminaste de leer el {first_book['date_ending'].strftime('%d/%m/%Y')}."
            else:
                return "No hay registros de libros completados en tu historial."
        
        if has_keywords(query_normalized, keywords['promedio_paginas']):
            return f"Tu promedio de lectura es de {chat_data['reading_stats']['avg_pages_per_day']} páginas por día."
        
        if has_keywords(query_normalized, keywords['metas']):
            goals = chat_data['reading_goals']
            return f"Tu meta es leer {goals['monthly']} libros al mes y {goals['yearly']} al año. Has completado {goals['completed_books_this_year']} libros este año y {goals['completed_books_this_month']} este mes."
        
        return None

    def _generate_generic_response(self, chat_data):
        """
        Genera una respuesta genérica cuando no se puede identificar
        la intención de la consulta con ningún método.
        
        Args:
            chat_data (dict): Datos de lectura del usuario
            
        Returns:
            str: Respuesta genérica pero informativa
        """
        import random
        
        suggestions = [
            "cuál es mi libro favorito", 
            "qué estoy leyendo actualmente", 
            "cuántos libros he leído", 
            "cuál es mi autor favorito",
            "cuál ha sido el libro más largo que he leído",
            "cuánto tiempo me tomó leer mi último libro",
            "cuál es mi saga favorita",
            "cuál fue mi primer libro",
            "de qué géneros es el libro que estoy leyendo",
            "qué opiné sobre el último libro que leí"
        ]
        
        random_suggestions = random.sample(suggestions, min(3, len(suggestions)))
        suggestions_text = ", ".join([f"'{s}'" for s in random_suggestions])
        
        current_book = next((book for book in chat_data['user_books'] if book['status'] == 'reading'), None)
        reading_text = f"Actualmente estás leyendo \"{current_book['title']}\"." if current_book else "No estás leyendo ningún libro actualmente."
        
        return f"Hubo un error al entender tu pregunta. Prueba a preguntar: {suggestions_text}."