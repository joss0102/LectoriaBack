from flask import Flask, jsonify, request
from flask_cors import CORS
from config.settings import API_HOST, API_PORT, DEBUG_MODE

# Importar rutas
from api.routes.book_routes import book_bp
from api.routes.user_routes import user_bp
from api.routes.reading_routes import reading_bp
from api.routes.author_routes import author_bp
from api.routes.auth_routes import auth_bp

app = Flask(__name__)
CORS(app)

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
        "version": "3.0"
    })

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
    

def start_api():
    app.run(host=API_HOST, port=API_PORT, debug=DEBUG_MODE)

if __name__ == "__main__":
    start_api()