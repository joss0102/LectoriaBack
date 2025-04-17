import logging
from config.settings import MAX_PAGE_SIZE, DEFAULT_PAGE_SIZE
from flask import request

logger = logging.getLogger('query')

def sanitize_input(value, default=None, max_length=None):
    """
    Sanitiza un valor de entrada para prevenir inyecciones SQL.
    
    Args:
        value: Valor a sanitizar
        default: Valor por defecto si es None
        max_length: Longitud máxima permitida
        
    Returns:
        Valor sanitizado
    """
    if value is None:
        return default
    
    if not isinstance(value, str):
        value = str(value)
    
    if max_length and len(value) > max_length:
        value = value[:max_length]
    
    # Eliminar caracteres peligrosos
    unsafe_chars = [';', '--', '/*', '*/', 'xp_', 'DROP', 'DELETE', 'UPDATE', 'INSERT', 'SELECT']
    for char in unsafe_chars:
        value = value.replace(char, '')
    
    return value

def get_pagination_params():
    """
    Obtiene y valida parámetros de paginación desde la solicitud.
    
    Returns:
        tuple: (page, page_size)
    """
    try:
        page = int(request.args.get('page', 1))
        page_size = int(request.args.get('page_size', DEFAULT_PAGE_SIZE))
        if page < 1:
            page = 1
        
        if page_size < 1:
            page_size = DEFAULT_PAGE_SIZE
        elif page_size > MAX_PAGE_SIZE:
            page_size = MAX_PAGE_SIZE
            
        return page, page_size
    except ValueError:
        logger.warning("Parámetros de paginación inválidos")
        return 1, DEFAULT_PAGE_SIZE

def build_pagination_response(data, total_count, page, page_size):
    """
    Construye una respuesta con metadatos de paginación.
    
    Args:
        data: Datos a devolver
        total_count: Número total de resultados
        page: Página actual
        page_size: Tamaño de página
        
    Returns:
        dict: Respuesta con metadatos de paginación
    """
    total_pages = (total_count + page_size - 1) // page_size if page_size > 0 else 0
    
    return {
        'data': data,
        'pagination': {
            'page': page,
            'page_size': page_size,
            'total_items': total_count,
            'total_pages': total_pages
        }
    }

def build_conditional_query(base_query, conditions=None, params=None, order_by=None, limit=None, offset=None):
    """
    Construye una consulta SQL con condiciones opcionales.
    
    Args:
        base_query (str): Consulta SQL base
        conditions (list): Lista de condiciones WHERE
        params (list): Lista de parámetros para las condiciones
        order_by (str): Cláusula ORDER BY
        limit (int): Número máximo de resultados
        offset (int): Desplazamiento para paginación
        
    Returns:
        tuple: (query, params)
    """
    query = base_query
    final_params = params or []
    
    if conditions and len(conditions) > 0:
        query += " WHERE " + " AND ".join(conditions)
        
    if order_by:
        query += f" ORDER BY {order_by}"
    
    if limit is not None:
        query += " LIMIT %s"
        final_params.append(limit)
        
        if offset is not None:
            query += " OFFSET %s"
            final_params.append(offset)
    
    return query, final_params