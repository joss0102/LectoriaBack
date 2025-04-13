import os
from dotenv import load_dotenv
from datetime import timedelta

# Cargar variables de entorno
load_dotenv()

# Configuración de la API
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8080"))
DEBUG_MODE = os.getenv("DEBUG_MODE", "True").lower() == "true"

# Configuración de paginación
DEFAULT_PAGE_SIZE = 10

# Configuración JWT
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "8553d920ac5dc5792a6be2915c36588deefcb3d2c0ade5e822b6466c38a8f5b3")
JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)  # Tokens válidos por 1 hora
JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=7)  # Refresh tokens válidos por 7 días
JWT_ALGORITHM = "HS256"  # Algoritmo para firmar los tokens