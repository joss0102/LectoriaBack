from flask import Flask, jsonify, request, g
from flask_cors import CORS
from config.settings import API_HOST, API_PORT, DEBUG_MODE, FLASK_WORKERS
import logging
from utils.auth import extract_token_from_header, decode_token
import jwt
from werkzeug.middleware.proxy_fix import ProxyFix
import os
import traceback

# Configurar logging
logging.basicConfig(
    level=logging.INFO if not DEBUG_MODE else logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("app.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("api")

# Inicializar la aplicación Flask con configuración optimizada
app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app)  # Mejora el manejo de proxies

# Configuraciones para mejorar rendimiento
app.config['JSON_SORT_KEYS'] = False  # Evita ordenar las claves JSON (mejora rendimiento)
app.config['PROPAGATE_EXCEPTIONS'] = True  # Mejor control de errores

# Configurar CORS de manera más restrictiva
CORS(app, resources={
    r"/api/*": {
        "origins": os.getenv("ALLOWED_ORIGINS", "*").split(","),
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Authorization", "Content-Type"]
    }
})

# Importar rutas
from api.routes.book_routes import book_bp
from api.routes.user_routes import user_bp
from api.routes.reading_routes import reading_bp
from api.routes.author_routes import author_bp
from api.routes.auth_routes import auth_bp

# Registrar blueprints (rutas)
app.register_blueprint(book_bp, url_prefix='/api/books')
app.register_blueprint(user_bp, url_prefix='/api/users')
app.register_blueprint(reading_bp, url_prefix='/api/readings')
app.register_blueprint(author_bp, url_prefix='/api/authors')
app.register_blueprint(auth_bp, url_prefix='/api/auth')

@app.route('/')
def index():
    return jsonify({
        "message": "Bienvenido a la API de Lectoria",
        "version": "4.0"
    })

# Manejador de errores global
@app.errorhandler(Exception)
def handle_exception(e):
    """Manejador global de excepciones para toda la API"""
    logger.error(f"Error no controlado: {e}")
    logger.error(traceback.format_exc())
    
    if isinstance(e, jwt.PyJWTError):
        logger.warning(f"Error de JWT: {e}")
        return jsonify({"error": "Error de autenticación"}), 401
        
    # Manejar otros tipos de errores conocidos
    if hasattr(e, 'code') and hasattr(e, 'description'):
        return jsonify({"error": e.description}), e.code
        
    # Error interno para todos los demás casos
    return jsonify({"error": "Error interno del servidor"}), 500

# Middleware para verificar tokens JWT en rutas protegidas
@app.before_request
def handle_token_verification():
    public_routes = [
        '/',
        '/api/auth/login',
        '/api/auth/refresh'
    ]
    
    if request.method == 'OPTIONS':
        return None
    
    if request.path in public_routes:
        return None
    
    if request.path.startswith('/api/books') and request.method == 'GET':
        return None
    
    if request.path.startswith('/api/authors') and request.method == 'GET':
        return None
    
    if request.path.startswith('/api/users'):
        if request.method in ['GET', 'POST']:
            return None
    
    # Para todas las demás rutas, verificar el token
    try:
        auth_header = request.headers.get('Authorization')
        token = extract_token_from_header(auth_header)
        
        if not token:
            # No interrumpir la solicitud, solo registrar la falta de token
            logger.warning(f"Solicitud sin token: {request.path}")
            return None
            
        payload = decode_token(token)
        
        # Almacenar información del usuario en el contexto de la solicitud
        g.user_id = payload.get('id')
        g.user_role = payload.get('role')
        g.user_nickname = payload.get('sub')
        
    except jwt.ExpiredSignatureError:
        logger.warning(f"Token expirado en la ruta: {request.path}")
        return jsonify({'error': 'Token expirado'}), 401
        
    except jwt.InvalidTokenError as e:
        logger.warning(f"Token inválido en la ruta: {request.path}, Error: {e}")
        return jsonify({'error': 'Token inválido'}), 401
        
    except Exception as e:
        logger.error(f"Error al verificar token: {e}")
        return jsonify({'error': 'Error de autenticación'}), 401

# Middleware para registrar todas las solicitudes
@app.before_request
def log_request():
    """Registra todas las solicitudes entrantes"""
    if DEBUG_MODE:
        logger.debug(f"Solicitud: {request.method} {request.path}")
        if request.method in ['POST', 'PUT'] and request.is_json:
            # Evitar registro de datos sensibles
            if 'password' in request.json:
                masked_data = dict(request.json)
                masked_data['password'] = '********'
                logger.debug(f"Datos: {masked_data}")
            else:
                logger.debug(f"Datos: {request.json}")

# Middleware para cerrar todas las conexiones activas después de cada solicitud
@app.after_request
def after_request(response):
    """Operaciones de limpieza después de cada solicitud"""
    # Verificar si hay datos en 'g' y limpiarlos
    if hasattr(g, 'user_id'):
        delattr(g, 'user_id')
    if hasattr(g, 'user_role'):
        delattr(g, 'user_role')
    if hasattr(g, 'user_nickname'):
        delattr(g, 'user_nickname')
    
    # Registrar resultado de la solicitud en nivel de depuración
    if DEBUG_MODE and response:
        logger.debug(f"Respuesta: {response.status}")
    
    return response

def start_api():
    """Inicia la API con gunicorn o flask incorporado según FLASK_WORKERS"""
    if FLASK_WORKERS and int(FLASK_WORKERS) > 1:
        from gunicorn.app.wsgiapp import WSGIApplication
        
        class GunicornApp(WSGIApplication):
            def init(self, parser, opts, args):
                # Configuración de gunicorn
                return {
                    'bind': f"{API_HOST}:{API_PORT}",
                    'workers': int(FLASK_WORKERS),
                    'timeout': 120,  # Timeout más alto para manejar consultas largas
                    'worker_class': 'gevent',  # Usar gevent para mejor manejo de conexiones
                }
                
            def load(self):
                return app
                
        # Iniciar con gunicorn
        logger.info(f"Iniciando API lectoria con gunicorn ({FLASK_WORKERS} workers)")
        GunicornApp().run()
    else:
        # Iniciar con el servidor incorporado de Flask
        logger.info("Iniciando API lectoria con Flask incorporado")
        app.run(host=API_HOST, port=int(API_PORT), debug=DEBUG_MODE, threaded=True)

if __name__ == "__main__":
    start_api()