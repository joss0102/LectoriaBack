from flask import Blueprint, jsonify, request
from services.reading_goals_service import ReadingGoalsService

reading_goals_bp = Blueprint('reading_goals_bp', __name__)
reading_goals_service = ReadingGoalsService()

@reading_goals_bp.route('/<string:user_nickname>', methods=['GET'])
def get_reading_goals(user_nickname):
    """
    Obtiene las metas de lectura de un usuario.
    """
    goals = reading_goals_service.get_reading_goals(user_nickname)
    
    if goals:
        return jsonify(goals)
    else:
        return jsonify({"error": "No se encontraron metas de lectura"}), 404

@reading_goals_bp.route('/<string:user_nickname>', methods=['PUT'])
def update_reading_goals(user_nickname):
    """
    Actualiza las metas de lectura de un usuario.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    result = reading_goals_service.update_reading_goals(user_nickname, data)
    
    if result:
        return jsonify({"message": "Metas de lectura actualizadas correctamente", "data": result})
    else:
        return jsonify({"error": "Error al actualizar las metas de lectura"}), 500