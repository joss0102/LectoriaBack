## Instalar dependencias
1. Añadimos las dependencias a `reuirements.txt`
```bash
PyJWT==2.6.0
bcrypt==4.0.1
```
2. Inslamos las dependencias
```bash
pip install -r requirements.txt
```
## Creamos un módulo para autenticación

Crea un archivo `backend/auth/auth.py`

```python
import jwt
import datetime
import bcrypt
from functools import wraps
from flask import request, jsonify
import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Configuración
JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'tu_clave_secreta_aqui')
JWT_ALGORITHM = 'HS256'
JWT_EXPIRATION_DELTA = datetime.timedelta(days=1)  # Token válido por 1 día


def generate_password_hash(password):
    """
    Genera un hash bcrypt para la contraseña.
    """
    if isinstance(password, str):
        password = password.encode('utf-8')
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password, salt).decode('utf-8')


def check_password_hash(password_hash, password):
    """
    Verifica si la contraseña coincide con el hash.
    """
    if isinstance(password, str):
        password = password.encode('utf-8')
    if isinstance(password_hash, str):
        password_hash = password_hash.encode('utf-8')
    return bcrypt.checkpw(password, password_hash)


def generate_token(user_id, nickname, role):
    """
    Genera un token JWT para el usuario.
    """
    payload = {
        'exp': datetime.datetime.utcnow() + JWT_EXPIRATION_DELTA,
        'iat': datetime.datetime.utcnow(),
        'sub': user_id,
        'nickname': nickname,
        'role': role
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def decode_token(token):
    """
    Decodifica un token JWT.
    """
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return {'error': 'Token expirado. Por favor, inicie sesión nuevamente.'}
    except jwt.InvalidTokenError:
        return {'error': 'Token inválido. Por favor, inicie sesión nuevamente.'}


def token_required(f):
    """
    Decorador que verifica si el token JWT es válido.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Buscar el token en los headers
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
        
        if not token:
            return jsonify({'error': 'Token no proporcionado'}), 401
        
        try:
            data = decode_token(token)
            if 'error' in data:
                return jsonify(data), 401
            
            # Añadir la información del usuario al contexto de la solicitud
            request.current_user = {
                'id': data['sub'],
                'nickname': data['nickname'],
                'role': data['role']
            }
        except:
            return jsonify({'error': 'Token inválido'}), 401
        
        return f(*args, **kwargs)
    
    return decorated


def admin_required(f):
    """
    Decorador que verifica si el usuario es administrador.
    """
    @wraps(f)
    @token_required
    def decorated(*args, **kwargs):
        if request.current_user.get('role') != 'admin':
            return jsonify({'error': 'Se requieren permisos de administrador'}), 403
        
        return f(*args, **kwargs)
    
    return decorated
```
## Crear un endpoint para autentificacion

Crea un archivo `backend/api/routes/auth_routes.py`

```python
from flask import Blueprint, request, jsonify
from models.user import UserModel
from datetime import datetime
from auth.auth import generate_token, check_password_hash

auth_bp = Blueprint('auth_bp', __name__)
user_model = UserModel()

@auth_bp.route('/login', methods=['POST'])
def login():
    """
    Autentica a un usuario y devuelve un token JWT.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    nickname = data.get('nickname')
    password = data.get('password')
    
    if not nickname or not password:
        return jsonify({"error": "Se requiere nickname y password"}), 400
    
    # Buscar usuario por nickname
    user = user_model.get_user_by_nickname_with_password(nickname)
    
    if not user:
        return jsonify({"error": "Usuario no encontrado"}), 404
    
    # Verificar contraseña
    if not check_password_hash(user['password'], password):
        return jsonify({"error": "Contraseña incorrecta"}), 401
    
    # Generar token
    token = generate_token(user['id'], user['nickName'], user['role_name'])
    
    return jsonify({
        "message": "Inicio de sesión exitoso",
        "token": token,
        "user": {
            "id": user['id'],
            "nickname": user['nickName'],
            "name": user['name'],
            "role": user['role_name']
        }
    })

@auth_bp.route('/register', methods=['POST'])
def register():
    """
    Registra un nuevo usuario y devuelve un token JWT.
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Datos no proporcionados"}), 400
    
    # Validar campos obligatorios
    required_fields = ['name', 'nickname', 'password']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Campo requerido: {field}"}), 400
    
    # Extraer datos
    name = data.get('name')
    last_name1 = data.get('last_name1', '')
    last_name2 = data.get('last_name2', '')
    birthdate = data.get('birthdate')
    union_date = data.get('union_date', datetime.now().strftime('%Y-%m-%d'))
    nickname = data.get('nickname')
    password = data.get('password')
    role_name = data.get('role_name', 'client')  # Por defecto, role 'client'
    
    # Verificar si el nickname ya existe
    existing_user = user_model.get_user_by_nickname(nickname)
    if existing_user:
        return jsonify({"error": "El nickname ya está en uso"}), 409
    
    # Hashear la contraseña
    hashed_password = generate_password_hash(password)
    
    # Crear usuario
    result = user_model.add_user(name, last_name1, last_name2, birthdate, union_date, nickname, hashed_password, role_name)
    
    if not result:
        return jsonify({"error": "Error al registrar el usuario"}), 500
    
    # Buscar el usuario recién creado para obtener su ID
    new_user = user_model.get_user_by_nickname_with_password(nickname)
    
    # Generar token
    token = generate_token(new_user['id'], new_user['nickName'], new_user['role_name'])
    
    return jsonify({
        "message": "Usuario registrado correctamente",
        "token": token,
        "user": {
            "id": new_user['id'],
            "nickname": new_user['nickName'],
            "name": new_user['name'],
            "role": new_user['role_name']
        }
    }), 201
```
## Actualizamos el modelo de usuario
Modificamos `backend/models/user.py` para añadir un método que también devuelva la contraseña:

```python
def get_user_by_nickname_with_password(self, nickname):
    """
    Obtiene un usuario por su nickname, incluyendo la contraseña.
    
    Args:
        nickname (str): Nickname del usuario
        
    Returns:
        dict: Información del usuario o None si no existe
    """
    query = """
    SELECT u.id, u.name, u.last_name1, u.last_name2, u.nickName, u.password, r.name as role_name 
    FROM user u
    JOIN user_role r ON u.id_role = r.id
    WHERE u.nickName = %s
    """
    results = self.db.execute_query(query, [nickname])
    return results[0] if results else None
```
## Registrar el blueprint de autentificacion
```python
from api.routes.auth_routes import auth_bp

# ...

# Registrar blueprints (rutas)
app.register_blueprint(auth_bp, url_prefix='/api/auth')
```
## Añadimos la clave secreta a tu archivo .env
```bash
JWT_SECRET_KEY=tu_clave_secreta_muy_segura_aqui
```
## Proteger rutas que requieren autentificacion

Ahora puedes usar los decoradores `token_required` y `admin_required` para proteger tus rutas:

```python
from auth.auth import token_required, admin_required

# Ruta que requiere autenticación
@user_bp.route('/profile', methods=['GET'])
@token_required
def get_user_profile():
    """
    Obtiene el perfil del usuario autenticado.
    """
    user_id = request.current_user.get('id')
    user = user_service.get_user_by_id(user_id)
    
    if user:
        return jsonify(user)
    else:
        return jsonify({"error": "Usuario no encontrado"}), 404

# Ruta que requiere permisos de administrador
@user_bp.route('/', methods=['GET'])
@admin_required
def get_all_users():
    """
    Obtiene todos los usuarios (solo administradores).
    """
    users = user_service.get_all_users()
    return jsonify({"data": users})
```
## Ejemplo de como usar los token en el cliente

```javascript
// Ejemplo en JavaScript (podría ser en Angular)
const token = localStorage.getItem('token');
fetch('/api/users/profile', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  }
})
.then(response => response.json())
.then(data => console.log(data));
```