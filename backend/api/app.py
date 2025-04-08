from flask import Flask, jsonify
from flask_cors import CORS
from config.settings import API_HOST, API_PORT, DEBUG_MODE

# Importar rutas
from api.routes.book_routes import book_bp
from api.routes.user_routes import user_bp
from api.routes.reading_routes import reading_bp
from api.routes.author_routes import author_bp

app = Flask(__name__)
CORS(app)  # Habilitar CORS para toda la aplicación

# Registrar blueprints (rutas)
app.register_blueprint(book_bp, url_prefix='/api/books')
app.register_blueprint(user_bp, url_prefix='/api/users')
app.register_blueprint(reading_bp, url_prefix='/api/readings')
app.register_blueprint(author_bp, url_prefix='/api/authors')

@app.route('/')
def index():
    return jsonify({
        "message": "Bienvenido a la API de TFG2",
        "version": "1.0"
    })

def start_api():
    app.run(host=API_HOST, port=API_PORT, debug=DEBUG_MODE)

if __name__ == "__main__":
    start_api()