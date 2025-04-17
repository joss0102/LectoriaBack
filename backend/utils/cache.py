from flask_caching import Cache
from config.settings import ENABLE_CACHE, CACHE_TYPE, CACHE_DEFAULT_TIMEOUT
import logging

logger = logging.getLogger('cache')

# Configuración global de caché
cache_config = {
    'CACHE_TYPE': CACHE_TYPE,
    'CACHE_DEFAULT_TIMEOUT': CACHE_DEFAULT_TIMEOUT,
}

if CACHE_TYPE == 'redis':
    cache_config.update({
        'CACHE_REDIS_HOST': os.getenv('REDIS_HOST', 'localhost'),
        'CACHE_REDIS_PORT': int(os.getenv('REDIS_PORT', 6379)),
        'CACHE_REDIS_PASSWORD': os.getenv('REDIS_PASSWORD', None),
        'CACHE_REDIS_DB': int(os.getenv('REDIS_DB', 0)),
    })

# Instancia global de caché
cache = Cache(config=cache_config)

def setup_cache(app):
    """
    Configura el sistema de caché para la aplicación Flask.
    
    Args:
        app: Instancia de la aplicación Flask
    """
    if not ENABLE_CACHE:
        logger.info("Sistema de caché desactivado")
        return
    
    try:
        cache.init_app(app)
        logger.info(f"Sistema de caché inicializado con tipo: {CACHE_TYPE}")
    except Exception as e:
        logger.error(f"Error al inicializar el sistema de caché: {e}")

def invalidate_cache_for(key_pattern):
    """
    Invalida todas las claves de caché que coincidan con el patrón.
    
    Args:
        key_pattern (str): Patrón de clave a invalidar
    """
    if not ENABLE_CACHE:
        return
    
    try:
        if hasattr(cache, 'delete_memoized'):
            cache.delete_memoized(key_pattern)
            logger.debug(f"Caché invalidada para patrón: {key_pattern}")
    except Exception as e:
        logger.error(f"Error al invalidar caché para {key_pattern}: {e}")

def clear_all_cache():
    """Limpia toda la caché"""
    if not ENABLE_CACHE:
        return
    
    try:
        cache.clear()
        logger.info("Caché completamente limpiada")
    except Exception as e:
        logger.error(f"Error al limpiar toda la caché: {e}")