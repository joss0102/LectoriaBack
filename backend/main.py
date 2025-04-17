from api.app import start_api
import os
import sys
import traceback
from utils.logger import setup_logger
import logging

def main():
    """
    Función principal para iniciar la aplicación.
    Maneja excepciones globales y configuración inicial.
    """
    try:
        # Configurar el sistema de logging
        setup_logger()
        logger = logging.getLogger('main')
        
        # Registrar información de inicio
        logger.info("Iniciando la API Lectoria v4.0")
        logger.info(f"Python version: {sys.version}")
        logger.info(f"Current directory: {os.getcwd()}")
        
        # Verificar variables de entorno
        required_envs = ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD']
        for env in required_envs:
            if not os.getenv(env):
                logger.warning(f"La variable de entorno {env} no está configurada. Usando valor por defecto.")
        
        # Iniciar la API
        start_api()
        
    except Exception as e:
        # En caso de error fatal, asegurar que se registre adecuadamente
        try:
            logger = logging.getLogger('main')
            logger.critical(f"Error fatal al iniciar la aplicación: {e}")
            logger.critical(traceback.format_exc())
        except:
            # Si el logger falla, usar print como último recurso
            print(f"ERROR CRÍTICO AL INICIAR: {e}")
            print(traceback.format_exc())
        
        sys.exit(1)

if __name__ == "__main__":
    main()