from flask import Blueprint, jsonify, request
from services.chat_service import ChatService

chat_bp = Blueprint('chat_bp', __name__)
chat_service = ChatService()

@chat_bp.route('/<string:user_nickname>/data', methods=['GET'])
def get_chat_data(user_nickname):
    """
    Obtiene todos los datos necesarios para el chat de un usuario.
    """
    data = chat_service.get_chat_data(user_nickname)
    
    if data:
        return jsonify(data)
    else:
        return jsonify({"error": "No se encontraron datos para el usuario"}), 404

@chat_bp.route('/<string:user_nickname>/reading-progress', methods=['GET'])
def get_reading_progress_paged(user_nickname):
    """
    Obtiene el progreso de lectura del usuario con paginación.
    
    Query params:
    - limit: Número máximo de registros (predeterminado: 50)
    - offset: Desplazamiento para paginación (predeterminado: 0)
    """
    limit = int(request.args.get('limit', 50))
    offset = int(request.args.get('offset', 0))
    
    progress = chat_service.get_reading_progress_paged(user_nickname, limit, offset)
    
    return jsonify(progress)

@chat_bp.route('/<string:user_nickname>/reading-history', methods=['GET'])
def get_reading_history(user_nickname):
    """
    Obtiene el historial de lectura detallado de un usuario.
    
    Query params:
    - book_id: ID del libro para filtrar (opcional)
    - start_date: Fecha de inicio para filtrar (formato YYYY-MM-DD) (opcional)
    - end_date: Fecha de fin para filtrar (formato YYYY-MM-DD) (opcional)
    - limit: Número máximo de registros (predeterminado: 50)
    - offset: Desplazamiento para paginación (predeterminado: 0)
    """
    book_id = request.args.get('book_id', None)
    if book_id:
        book_id = int(book_id)
    
    start_date = request.args.get('start_date', None)
    end_date = request.args.get('end_date', None)
    limit = int(request.args.get('limit', 50))
    offset = int(request.args.get('offset', 0))
    
    history = chat_service.get_reading_history(
        user_nickname, book_id, start_date, end_date, limit, offset
    )
    
    return jsonify(history)

@chat_bp.route('/<string:user_nickname>/daily-stats', methods=['GET'])
def get_daily_reading_stats(user_nickname):
    """
    Obtiene estadísticas de lectura diaria del usuario para los últimos N días.
    
    Query params:
    - days: Número de días a retornar (predeterminado: 30)
    """
    days = int(request.args.get('days', 30))
    
    stats = chat_service.get_daily_reading_stats(user_nickname, days)
    
    return jsonify({"daily_stats": stats})


@chat_bp.route('/query', methods=['POST'])
def process_chat_query():
    """
    Procesa una consulta de chat y devuelve una respuesta.
    
    Espera un JSON con:
    - query: La pregunta o consulta del usuario
    - user: Nickname del usuario que hace la consulta
    """
    data = request.json
    
    if not data or 'query' not in data or 'user' not in data:
        return jsonify({"error": "Se requiere query y user"}), 400
    
    query = data['query']
    user = data['user']
    
    response = chat_service.process_query(query, user)
    
    if response:
        return jsonify({"response": response})
    else:
        return jsonify({"response": "Lo siento, no pude procesar tu consulta."}), 500