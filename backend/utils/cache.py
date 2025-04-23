from flask_caching import Cache
from config.settings import ENABLE_CACHE, CACHE_TYPE, CACHE_DEFAULT_TIMEOUT
import logging
import os
import functools

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
elif CACHE_TYPE == 'memcached':
    cache_config.update({
        'CACHE_MEMCACHED_SERVERS': [os.getenv('MEMCACHED_SERVER', 'localhost:11211')],
    })

# Instancia global de caché - INICIALIZADA PERO NECESITA SETUP_CACHE PARA USARSE
cache = Cache()

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
        # Aplicamos configuración y luego inicializamos con la app
        for key, value in cache_config.items():
            app.config[key] = value
            
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
        elif hasattr(cache, '_cache'):
            # Para algunos backends que usan _cache
            keys = [k for k in cache._cache.keys() if key_pattern in k]
            for key in keys:
                cache.delete(key)
            logger.debug(f"Caché invalidada para {len(keys)} claves con patrón: {key_pattern}")
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

def cached(timeout=None, key_prefix='view', unless=None):
    """
    Decorador simple para cachear resultados de funciones.
    En lugar de usar el memoize de Flask-Cache, usamos un enfoque más simple.
    
    Args:
        timeout (int): Tiempo en segundos que durará el caché (no usado en esta versión simple)
        key_prefix (str): Prefijo para la clave (no usado en esta versión simple)
        unless (callable): Función que determina si no se debe cachear (no usado en esta versión simple)
        
    Returns:
        decorated_function: La función decorada con caché
    """
    def decorator(f):
        # Si el caché no está habilitado, devolvemos la función original
        if not ENABLE_CACHE:
            return f
            
        # Usamos lru_cache de functools como alternativa simple
        @functools.lru_cache(maxsize=128)
        def cached_func(*args, **kwargs):
            return f(*args, **kwargs)
            
        @functools.wraps(f)
        def wrapper(*args, **kwargs):
            # Si hay una condición para no cachear, la verificamos
            if unless and callable(unless) and unless():
                return f(*args, **kwargs)
                
            return cached_func(*args, **kwargs)
            
        # Añadimos método para limpiar caché
        wrapper.clear_cache = cached_func.cache_clear
        return wrapper
        
    return decorator