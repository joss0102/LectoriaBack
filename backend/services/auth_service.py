from models.user import UserModel
from models.token import TokenModel
from utils.auth import generate_access_token, generate_refresh_token, decode_token
import logging

logger = logging.getLogger('auth')

class AuthService:
    """
    Servicio para operaciones relacionadas con autenticación.
    Implementa la lógica de negocio para login, refresh y logout.
    """
    def __init__(self):
        self.user_model = UserModel()
        self.token_model = TokenModel()
    
    def login(self, nickname, password):
        """
        Autentica a un usuario y genera tokens de acceso y refresco.
        
        Args:
            nickname (str): Nickname del usuario
            password (str): Contraseña del usuario
            
        Returns:
            dict: Tokens de acceso y refresco si la autenticación es exitosa, None en caso contrario
        """
        try:
            user = self.user_model.authenticate(nickname, password)
            
            if not user:
                logger.warning(f"Intento de login fallido para usuario: {nickname}")
                return None
                
            # Generar tokens
            access_token = generate_access_token(user)
            refresh_token = generate_refresh_token(user)
            
            logger.info(f"Login exitoso para usuario: {nickname}")
            
            return {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user': {
                    'id': user['id'],
                    'nickname': user['nickName'],
                    'name': user['name'],
                    'last_name1': user['last_name1'],
                    'last_name2': user['last_name2'],
                    'role': user['role_name']
                }
            }
        except Exception as e:
            logger.error(f"Error en login: {e}")
            return None
    
    def refresh(self, refresh_token):
        """
        Genera un nuevo token de acceso a partir de un token de refresco válido.
        
        Args:
            refresh_token (str): Token de refresco
            
        Returns:
            dict: Nuevo token de acceso si el token de refresco es válido, None en caso contrario
            
        Raises:
            Exception: Si hay un problema con el token de refresco
        """
        try:
            token_data = decode_token(refresh_token)
            
            if token_data.get('type') != 'refresh':
                logger.warning(f"Intento de refresh con token no válido: {token_data.get('type')}")
                return None
                
            if self.token_model.is_token_revoked(token_data):
                logger.warning(f"Intento de refresh con token revocado: {token_data.get('sub')}")
                return None
                
            user = self.user_model.get_user_by_nickname(token_data['sub'])
            
            if not user:
                logger.warning(f"Usuario no encontrado en refresh: {token_data.get('sub')}")
                return None
                
            access_token = generate_access_token(user)
            
            logger.info(f"Refresh exitoso para usuario: {user['nickName']}")
            
            return {
                'access_token': access_token,
                'user': {
                    'id': user['id'],
                    'nickname': user['nickName'],
                    'name': user['name'],
                    'last_name1': user['last_name1'],
                    'last_name2': user['last_name2'],
                    'role': user['role_name']
                }
            }
        except Exception as e:
            logger.error(f"Error en refresh: {e}")
            raise
    
    def logout(self, access_token, refresh_token=None):
        """
        Revoca los tokens de un usuario (los añade a la blacklist).
        
        Args:
            access_token (str): Token de acceso a revocar
            refresh_token (str, optional): Token de refresco a revocar. Default is None.
            
        Returns:
            bool: True si se revocaron los tokens correctamente, False en caso contrario
        """
        try:
            access_token_data = decode_token(access_token)
            
            user_id = access_token_data['id']
            self.token_model.add_token_to_blacklist(access_token_data, user_id)
            
            if refresh_token:
                try:
                    refresh_token_data = decode_token(refresh_token)
                    self.token_model.add_token_to_blacklist(refresh_token_data, user_id)
                except Exception as e:
                    logger.warning(f"Error al revocar token de refresco: {e}")
            
            self.token_model._cleanup_expired_tokens()
            
            logger.info(f"Logout exitoso para usuario ID: {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error en logout: {e}")
            return False
    
    def verify_token(self, token):
        """
        Verifica si un token es válido y no está revocado.
        
        Args:
            token (str): Token a verificar
            
        Returns:
            dict: Información del usuario si el token es válido, None en caso contrario
        """
        try:
            token_data = decode_token(token)
            
            if self.token_model.is_token_revoked(token_data):
                logger.warning(f"Token revocado usado: {token_data.get('sub')}")
                return None
                
            user = self.user_model.get_user_by_nickname(token_data['sub'])
            
            if not user:
                logger.warning(f"Usuario no encontrado en verificación: {token_data.get('sub')}")
                return None
                
            return {
                'id': user['id'],
                'nickname': user['nickName'],
                'role': user['role_name']
            }
        except Exception as e:
            logger.error(f"Error en verificación de token: {e}")
            return None