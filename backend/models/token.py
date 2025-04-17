from config.database import DatabaseConnection
import datetime
import logging
import json
from functools import lru_cache

logger = logging.getLogger('token')

class TokenModel:
    """
    Modelo para gestionar tokens revocados (blacklist).
    Permite llevar un registro de tokens que han sido revocados (logout)
    antes de su expiración natural.
    """
    def __init__(self):
        self.db = DatabaseConnection()
        self._ensure_table_exists()
        self._blacklist_cache = {}
        self._cleanup_expired_tokens()
    
    def _ensure_table_exists(self):
        """
        Asegura que la tabla de tokens revocados existe en la base de datos.
        Si no existe, la crea.
        """
        try:
            query = """
            CREATE TABLE IF NOT EXISTS revoked_tokens (
                id INT AUTO_INCREMENT PRIMARY KEY,
                jti VARCHAR(255) NOT NULL,
                token_type VARCHAR(20) NOT NULL,
                user_id INT NOT NULL,
                revoked_at DATETIME NOT NULL,
                expires_at DATETIME NOT NULL,
                INDEX (jti),
                INDEX (user_id),
                INDEX (expires_at)
            )
            """
            self.db.execute_update(query)
            logger.info("Tabla de tokens revocados verificada/creada")
        except Exception as e:
            logger.error(f"Error al crear tabla de tokens revocados: {e}")
    
    def add_token_to_blacklist(self, token_data, user_id):
        """
        Añade un token a la lista negra (blacklist).
        
        Args:
            token_data (dict): Datos del token decodificado
            user_id (int): ID del usuario al que pertenece el token
            
        Returns:
            bool: True si se añadió correctamente, False en caso contrario
        """
        try:
            jti = f"{token_data['sub']}:{token_data['iat']}"
            
            query = """
            INSERT INTO revoked_tokens (jti, token_type, user_id, revoked_at, expires_at)
            VALUES (%s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE revoked_at = VALUES(revoked_at)
            """
            
            expires_at = datetime.datetime.fromtimestamp(token_data['exp'])
            revoked_at = datetime.datetime.utcnow()
            
            params = [
                jti,
                token_data['type'],
                user_id,
                revoked_at,
                expires_at
            ]
            
            self.db.execute_update(query, params)
            
            cache_key = f"{jti}:{token_data['type']}"
            self._blacklist_cache[cache_key] = {
                'expires_at': expires_at,
                'revoked_at': revoked_at
            }
            
            logger.info(f"Token añadido a la blacklist: {jti}")
            return True
        except Exception as e:
            logger.error(f"Error al añadir token a la blacklist: {e}")
            return False
    
    def _load_token_from_db(self, jti, token_type):
        """
        Carga un token de la base de datos y lo añade a la caché
        
        Args:
            jti (str): JTI del token
            token_type (str): Tipo de token
        
        Returns:
            bool: True si el token está revocado, False en caso contrario
        """
        query = """
        SELECT 1 FROM revoked_tokens 
        WHERE jti = %s AND token_type = %s
        """
        
        result = self.db.execute_query(query, [jti, token_type])
        is_revoked = len(result) > 0
        
        cache_key = f"{jti}:{token_type}"
        if is_revoked:
            self._blacklist_cache[cache_key] = {
                'is_revoked': True,
                'cached_at': datetime.datetime.utcnow()
            }
        
        return is_revoked
    
    def is_token_revoked(self, token_data):
        """
        Verifica si un token está en la lista negra (blacklist).
        
        Args:
            token_data (dict): Datos del token decodificado
            
        Returns:
            bool: True si el token está revocado, False en caso contrario
        """
        try:
            jti = f"{token_data['sub']}:{token_data['iat']}"
            token_type = token_data['type']
            cache_key = f"{jti}:{token_type}"
            
            if cache_key in self._blacklist_cache:
                return True
            
            return self._load_token_from_db(jti, token_type)
                
        except Exception as e:
            logger.error(f"Error al verificar si el token está revocado: {e}")
            return False
    
    def _cleanup_expired_tokens(self):
        """
        Limpia los tokens expirados de la lista negra.
        También limpia la caché de memoria para evitar crecimiento descontrolado.
        
        Returns:
            int: Número de tokens eliminados
        """
        try:
            now = datetime.datetime.utcnow()
            for key in list(self._blacklist_cache.keys()):
                token_data = self._blacklist_cache[key]
                if 'expires_at' in token_data and token_data['expires_at'] < now:
                    del self._blacklist_cache[key]
            
            query = """
            DELETE FROM revoked_tokens 
            WHERE expires_at < %s
            """
            
            result = self.db.execute_update(query, [now])
            
            if result > 0:
                logger.info(f"Se eliminaron {result} tokens expirados de la blacklist")
            
            return result
        except Exception as e:
            logger.error(f"Error al limpiar tokens expirados: {e}")
            return 0