# **Proyecto Lectoria Backend**

# **Descripción**

Esta API proporciona un backend completo para una aplicación de gestión de lecturas. Permite a los usuarios registrar libros, hacer seguimiento de su progreso de lectura, escribir reseñas, y mucho más. La API está diseñada con una arquitectura de tres capas (modelos, servicios y rutas) y utiliza MySQL como base de datos.

# **Características**

- Gestión completa de usuarios (registro, autenticación mediante JWT).
- Manejo de libros (añadir, consultar, filtrar por género/autor).
- Seguimiento de progreso de lectura.
- Sistema de reseñas y calificaciones.
- Vistas optimizadas para consultas complejas.

# **Requisitos**

- Python 3.8 o superior.
- MySQL 8.0 o superior.

# **Dependencias**

- mysql-connector-python==8.0.31
- python-dotenv==1.0.0
- Flask==2.3.3
- Flask-CORS==4.0.0
- PyJWT==2.6.0
- bcrypt==4.0.1

# **Instalación**

1. Clona el repositorio y ve a la carpeta `backend/`

```bash
git clone https://github.com/tuusuario/tfg2-api.git
cd backend
```

2. Cree un entorno virtual e instale las dependencias:

```bash
python -m venv venv
source venv/Scripts/activate
pip install -r requirements.txt
pip install --upgrade mysql-connector-python
pip install transformers torch
```

3. Configure las variables de entorno en el archivo `.env`:

```bash
DB_HOST=localhost
DB_NAME=TFG2
DB_USER=root
DB_PASSWORD=tupassword
DB_PORT=3306
JWT_SECRET_KEY=tu_clave_secreta_muy_segura_aqui
API_PORT=8080
```

4. Configure la base de datos

Ejecute el script SQL proporcionado para crear las tablas, vistas y procedimientos almacenados.

5. Ejecute la API:

```bash
python main.py
```

6. La API estará disponible en `http://localhost:8080`

## **Endpoints principales**

- **Autenticación**

  - **POST** /api/auth/register: Registro de nuevos usuarios.
  - **POST** /api/auth/login: Inicio de sesión y obtención de token JWT.

- **Libros**

  - **GET** /api/books: Obtener todos los libros (con paginación y filtros).
  - **GET** /api/books/{id}: Obtener un libro específico.
  - **POST** /api/books: Añadir un nuevo libro.

- **Usuarios**

  - **GET** /api/users: Obtener todos los usuarios (solo admin).
  - **GET** /api/users/{nickname}: Obtener un usuario específico.
  - **GET** /api/users/{nickname}/stats: Obtener estadísticas de lectura.

- **Lecturas**

  - **GET** /api/readings/progress/{nickname}: Obtener progreso de lectura.
  - **POST** /api/readings/progress: Añadir progreso de lectura.
  - **GET** /api/readings/reviews: Obtener reseñas de libros.

- **Autores**
  - **GET** /api/authors: Obtener todos los autores.
  - **GET** /api/authors/{id}: Obtener un autor específico.
  - **GET** /api/authors/{id}/books: Obtener libros de un autor.
  - **POST** /api/authors: Añadir un nuevo autor.

# **Seguridad**

La API utiliza autenticación JWT para proteger los endpoints que requieren autenticación. Para acceder a estos endpoints, debes incluir el token en los headers de la petición:

```bash
Authorization: Bearer <tu_token_jwt>
```

# **Notas para Desarrolladores**

- La API utiliza paginación para endpoints que pueden devolver muchos resultados.
- Las contraseñas se almacenan hasheadas con bcrypt.
- Las fechas deben seguir el formato YYYY-MM-DD.
- Los ratings deben estar entre 1.0 y 10.0.

✨ Desarrollado por [David Fernández Valbuena](https://github.com/DavidFrontendDev) y [Jose Ayrton Rosell Bonavina](https://github.com/joss0102) ✨
