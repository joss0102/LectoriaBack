import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Configuración de la API
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8080"))
DEBUG_MODE = os.getenv("DEBUG_MODE", "True").lower() == "true"

# Configuración de paginación
DEFAULT_PAGE_SIZE = 10