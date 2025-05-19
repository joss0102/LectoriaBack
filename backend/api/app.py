from flask import Flask, jsonify, request, g
from flask_cors import CORS
from config.settings import API_HOST, API_PORT, DEBUG_MODE, FLASK_WORKERS
import logging
from utils.auth import extract_token_from_header, decode_token
import jwt
from werkzeug.middleware.proxy_fix import ProxyFix
import os
import traceback
import time
import types
from utils.cache import setup_cache, cache
from utils.logger import setup_logger
from api.routes.pdf_book_routes import pdf_book_bp
from api.routes.chat_routes import chat_bp


# Configurar un logger básico para diagnóstico
test_logger = logging.getLogger("test")
test_logger.setLevel(logging.DEBUG)

# Handler de consola
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)
test_logger.addHandler(console_handler)

# Handler de archivo para pruebas
test_log_path = os.path.join(os.getcwd(), "debug_test.log")
test_file_handler = logging.FileHandler(test_log_path, mode='w')
test_file_handler.setLevel(logging.DEBUG)
test_logger.addHandler(test_file_handler)



# Forzar DEBUG_MODE para las pruebas
DEBUG_MODE = False

# Configurar logging - Modificado para diagnóstico
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("app_debug.log", mode='w'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("api")

app = Flask(__name__)
app.url_map.strict_slashes = False
app.wsgi_app = ProxyFix(app.wsgi_app)

app.config['JSON_SORT_KEYS'] = False
app.config['PROPAGATE_EXCEPTIONS'] = True

CORS(app, resources={
    r"/*": { 
        "origins": ["http://localhost:4200", "http://127.0.0.1:4200", "*"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Authorization", "Content-Type", "Accept", "Origin", "X-Debug-Info"],
        "expose_headers": ["Content-Length", "Content-Type", "X-Debug-Info"],
        "supports_credentials": True  # Añadido para soportar credenciales
    }
})

setup_cache(app)

@app.before_request
def start_timer():
    g.start_time = time.time()

from api.routes.book_routes import book_bp
from api.routes.user_routes import user_bp
from api.routes.reading_routes import reading_bp
from api.routes.author_routes import author_bp
from api.routes.auth_routes import auth_bp
from api.routes.reading_goals_routes import reading_goals_bp

app.register_blueprint(book_bp, url_prefix='/api/books')
app.register_blueprint(user_bp, url_prefix='/api/users')
app.register_blueprint(reading_bp, url_prefix='/api/readings')
app.register_blueprint(author_bp, url_prefix='/api/authors')
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(reading_goals_bp, url_prefix='/api/reading-goals')
app.register_blueprint(pdf_book_bp, url_prefix='/api/pdf-books') 
app.register_blueprint(chat_bp, url_prefix='/api/chat')

@app.route('/')
def index():
    logger.info("Acceso a ruta principal '/'")
    return jsonify({
        "message": "Bienvenido a la API de Lectoria",
        "version": "5.0"
    })

@app.errorhandler(Exception)
def handle_exception(e):
    """Manejador global de excepciones para toda la API"""
    logger.error(f"Error no controlado: {e}")
    logger.error(traceback.format_exc())
    
    if isinstance(e, jwt.PyJWTError):
        logger.warning(f"Error de JWT: {e}")
        return jsonify({"error": "Error de autenticación"}), 401
        
    if hasattr(e, 'code') and hasattr(e, 'description'):
        return jsonify({"error": e.description}), e.code
        
    return jsonify({"error": "Error interno del servidor"}), 500

@app.before_request
def handle_token_verification():
    public_routes = [
        '/',
        '/api/auth/login',
        '/api/auth/refresh',
        '/api/pdf-books/upload'
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
    
    try:
        auth_header = request.headers.get('Authorization')
        token = extract_token_from_header(auth_header)
        
        if not token:
            logger.warning(f"Solicitud sin token: {request.path}")
            return None
            
        payload = decode_token(token)
        
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

@app.before_request
def log_request():
    """Registra todas las solicitudes entrantes"""
    logger.info(f"Solicitud recibida: {request.method} {request.path}")
    if request.method in ['POST', 'PUT'] and request.is_json:
        if 'password' in request.json:
            masked_data = dict(request.json)
            masked_data['password'] = '********'
            logger.debug(f"Datos de solicitud: {masked_data}")
        else:
            logger.debug(f"Datos de solicitud: {request.json}")

@app.after_request
def after_request(response):
    """Operaciones de limpieza después de cada solicitud"""
    if hasattr(g, 'user_id'):
        delattr(g, 'user_id')
    if hasattr(g, 'user_role'):
        delattr(g, 'user_role')
    if hasattr(g, 'user_nickname'):
        delattr(g, 'user_nickname')
    
    status_code = getattr(response, 'status_code', '?')
    
    return response

def start_api():
    """Inicia la API con gunicorn o flask incorporado según FLASK_WORKERS"""
    
    if FLASK_WORKERS and int(FLASK_WORKERS) > 1:
        from gunicorn.app.wsgiapp import WSGIApplication
        
        class GunicornApp(WSGIApplication):
            def init(self, parser, opts, args):
                return {
                    'bind': f"{API_HOST}:{API_PORT}",
                    'workers': int(FLASK_WORKERS),
                    'timeout': 120,
                    'worker_class': 'gevent',
                }
                
            def load(self):
                return app
                
        GunicornApp().run()
    else:
        app.run(host=API_HOST, port=int(API_PORT), debug=True, threaded=True)

if __name__ == "__main__":
    start_api()