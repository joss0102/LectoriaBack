from config.database import DatabaseConnection
import datetime

class TokenModel:
    """
    Modelo para gestionar tokens revocados (blacklist).
    Permite llevar un registro de tokens que han sido revocados (logout)
    antes de su expiración natural.
    """
    def __init__(self):
        self.db = DatabaseConnection()
        self._ensure_table_exists()
    
    def _ensure_table_exists(self):
        """
        Asegura que la tabla de tokens revocados existe en la base de datos.
        Si no existe, la crea.
        """
        query = """
        CREATE TABLE IF NOT EXISTS revoked_tokens (
            id INT AUTO_INCREMENT PRIMARY KEY,
            jti VARCHAR(255) NOT NULL,
            token_type VARCHAR(20) NOT NULL,
            user_id INT NOT NULL,
            revoked_at DATETIME NOT NULL,
            expires_at DATETIME NOT NULL,
            INDEX (jti),
            INDEX (user_id)
        )
        """
        self.db.execute_update(query)
    
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
            """
            
            params = [
                jti,
                token_data['type'],
                user_id,
                datetime.datetime.utcnow(),
                datetime.datetime.fromtimestamp(token_data['exp'])
            ]
            
            self.db.execute_update(query, params)
            return True
        except Exception as e:
            print(f"Error al añadir token a la blacklist: {e}")
            return False
    
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
            
            query = """
            SELECT 1 FROM revoked_tokens 
            WHERE jti = %s AND token_type = %s
            """
            
            result = self.db.execute_query(query, [jti, token_data['type']])
            
            return len(result) > 0
        except Exception as e:
            print(f"Error al verificar si el token está revocado: {e}")
            return False
    
    def clean_expired_tokens(self):
        """
        Limpia los tokens expirados de la lista negra.
        
        Returns:
            int: Número de tokens eliminados
        """
        try:
            query = """
            DELETE FROM revoked_tokens 
            WHERE expires_at < %s
            """
            
            result = self.db.execute_update(query, [datetime.datetime.utcnow()])
            
            return result
        except Exception as e:
            print(f"Error al limpiar tokens expirados: {e}")
            return 0