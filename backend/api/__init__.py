import logging
from utils.cache import setup_cache
from utils.logger import setup_logger
import os

# Configuración de variables de entorno para producción
def setup_environment():
    """
    Configura variables de entorno adicionales antes de iniciar la aplicación.
    Útil para establecer valores iniciales o valores por defecto seguros.
    """
    # Configurar número de hilos si no está definido
    if not os.getenv('FLASK_WORKERS'):
        import multiprocessing
        # Usar número de núcleos disponibles
        cores = multiprocessing.cpu_count()
        os.environ['FLASK_WORKERS'] = str(min(cores * 2 + 1, 8))  # Máximo 8 workers

    # Configurar nivel de log por defecto
    if not os.getenv('LOG_LEVEL'):
        os.environ['LOG_LEVEL'] = 'INFO'

    # Asegurar que hay un secret key seguro
    if not os.getenv('JWT_SECRET_KEY'):
        import secrets
        os.environ['JWT_SECRET_KEY'] = secrets.token_hex(32)
        logging.warning("JWT_SECRET_KEY no definido. Se ha generado uno aleatorio para esta sesión.")

def init_app(app):
    """
    Inicializa componentes de la aplicación como caché, registro, etc.
    
    Args:
        app: Instancia de la aplicación Flask
    """
    # Inicializar sistema de logging
    setup_logger()
    
    # Configurar sistema de caché
    setup_cache(app)
    
    if os.getenv('ENABLE_SENTRY', 'False').lower() == 'true' and os.getenv('SENTRY_DSN'):
        import sentry_sdk
        from sentry_sdk.integrations.flask import FlaskIntegration
        
        sentry_sdk.init(
            dsn=os.getenv('SENTRY_DSN'),
            integrations=[FlaskIntegration()],
            traces_sample_rate=float(os.getenv('SENTRY_TRACES_SAMPLE_RATE', '0.1')),
            environment=os.getenv('ENVIRONMENT', 'production'),
        )
        logging.info("Sistema de monitoreo Sentry inicializado")
    
    logging.info("Inicialización de la aplicación completada")