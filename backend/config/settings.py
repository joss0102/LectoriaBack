import os
from dotenv import load_dotenv
from datetime import timedelta

# Cargar variables de entorno
load_dotenv()

# Configuración de la API
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8080"))
DEBUG_MODE = os.getenv("DEBUG_MODE", "False").lower() == "true"

FLASK_WORKERS = os.getenv("FLASK_WORKERS", "1")

# Configuración de paginación
DEFAULT_PAGE_SIZE = int(os.getenv("DEFAULT_PAGE_SIZE", "10"))
MAX_PAGE_SIZE = int(os.getenv("MAX_PAGE_SIZE", "100"))  # Límite máximo para evitar consultas pesadas

# Configuración de base de datos
DB_POOL_SIZE = int(os.getenv("DB_POOL_SIZE", "10"))
DB_POOL_TIMEOUT = int(os.getenv("DB_POOL_TIMEOUT", "30"))
DB_CONNECT_TIMEOUT = int(os.getenv("DB_CONNECT_TIMEOUT", "30"))
DB_RETRY_ATTEMPTS = int(os.getenv("DB_RETRY_ATTEMPTS", "3"))
DB_RETRY_DELAY = int(os.getenv("DB_RETRY_DELAY", "1"))  # En segundos

# Configuración de caché
ENABLE_CACHE = os.getenv("ENABLE_CACHE", "False").lower() == "true"
CACHE_TYPE = os.getenv("CACHE_TYPE", "simple")  # simple, redis, memcached
CACHE_DEFAULT_TIMEOUT = int(os.getenv("CACHE_DEFAULT_TIMEOUT", "300"))  # 5 minutos

# Configuración JWT
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "8553d920ac5dc5792a6be2915c36588deefcb3d2c0ade5e822b6466c38a8f5b3")
JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=int(os.getenv("JWT_ACCESS_TOKEN_EXPIRES_MINUTES", "60")))
JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=int(os.getenv("JWT_REFRESH_TOKEN_EXPIRES_DAYS", "7")))
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")

# Configuración de seguridad
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*")  # Lista de orígenes separados por comas para CORS
RATE_LIMITING_ENABLED = os.getenv("RATE_LIMITING_ENABLED", "False").lower() == "true"
RATE_LIMIT = os.getenv("RATE_LIMIT", "60 per minute")  # Formato: "número per [second|minute|hour|day]"

# Configuración de logging
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
LOG_FORMAT = os.getenv("LOG_FORMAT", "%(asctime)s - %(name)s - %(levelname)s - %(message)s")
LOG_FILE = os.getenv("LOG_FILE", "app.log")