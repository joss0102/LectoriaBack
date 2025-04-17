import logging
import os
import sys
from logging.handlers import RotatingFileHandler
from config.settings import LOG_LEVEL, LOG_FORMAT, LOG_FILE

def setup_logger():
    """
    Configura el sistema de logging para toda la aplicación.
    Centraliza la configuración de los logs para facilitar la gestión.
    """
    log_dir = os.path.dirname(LOG_FILE)
    if log_dir and not os.path.exists(log_dir):
        os.makedirs(log_dir)
    
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, LOG_LEVEL))
    
    try:
        file_handler = RotatingFileHandler(
            LOG_FILE, 
            maxBytes=10*1024*1024,  # 10MB
            backupCount=5,  # Mantener 5 archivos de backup
            encoding='utf-8'
        )
        file_handler.setFormatter(logging.Formatter(LOG_FORMAT))
        root_logger.addHandler(file_handler)
        
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(logging.Formatter(LOG_FORMAT))
        root_logger.addHandler(console_handler)
        
        configure_specific_loggers()
        
        root_logger.info("Sistema de logging inicializado correctamente")
    except Exception as e:
        print(f"Error al configurar sistema de logging: {e}")
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(logging.Formatter(LOG_FORMAT))
        root_logger.addHandler(handler)
        root_logger.error(f"Error al configurar sistema de logging: {e}")

def configure_specific_loggers():
    """Configura niveles específicos para diferentes componentes"""
    logging.getLogger('werkzeug').setLevel(logging.WARNING)
    logging.getLogger('flask').setLevel(logging.WARNING)
    logging.getLogger('mysql').setLevel(logging.WARNING)
    
    db_logger = logging.getLogger('database')
    db_logger.setLevel(getattr(logging, LOG_LEVEL))
    
    auth_logger = logging.getLogger('auth')
    auth_logger.setLevel(getattr(logging, LOG_LEVEL))

class RequestLogger:
    """Helper para medir el tiempo de respuesta de las peticiones"""
    
    @staticmethod
    def log_request_timing(request, response, time_ms):
        """
        Registra el tiempo de respuesta de una petición HTTP
        
        Args:
            request: Objeto de solicitud Flask
            response: Objeto de respuesta Flask
            time_ms: Tiempo de respuesta en milisegundos
        """
        logger = logging.getLogger('request_timing')
        
        # Registrar solo si es una petición lenta (>500ms)
        if time_ms > 500:
            logger.warning(
                f"Petición lenta: {request.method} {request.path} - "
                f"Tiempo: {time_ms:.2f}ms - Estado: {response.status_code}"
            )
        else:
            logger.debug(
                f"Petición: {request.method} {request.path} - "
                f"Tiempo: {time_ms:.2f}ms - Estado: {response.status_code}"
            )