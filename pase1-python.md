# Estructura de Carpetas

- `Python`
```	
myapp/
├── backend/
│   ├── config/
│   │   ├── init.py
│   │   ├── database.py
│   │   └── settings.py
│   ├── models/
│   │   ├── init.py
│   │   ├── book.py
│   │   ├── user.py
│   │   └── reading.py
│   ├── services/
│   │   ├── init.py
│   │   ├── book_service.py
│   │   ├── user_service.py
│   │   └── reading_service.py
│   ├── api/
│   │   ├── init.py
│   │   ├── app.py
│   │   ├── routes/
│   │   │   ├── init.py
│   │   │   ├── book_routes.py
│   │   │   ├── user_routes.py
│   │   │   └── reading_routes.py
│   ├── utils/
│   │   ├── init.py
│   │   └── helpers.py
│   ├── init.py
│   ├── main.py
│   └── requirements.txt
└── frontend/  # Aquí irá tu código Angular más adelante
```
## Explicación de la Estructura

### `backend/`
Contiene todo el código del servidor Python.

### `backend/config/`
Contiene archivos de configuración.
- `database.py`: Configuración y conexión a la base de datos
- `settings.py`: Variables de configuración global

### `backend/models/`
Define la estructura de datos y operaciones directas con la base de datos.
- `book.py`: Operaciones relacionadas con libros
- `user.py`: Operaciones relacionadas con usuarios
- `reading.py`: Operaciones relacionadas con la lectura y progreso

### `backend/services/`
Contiene la lógica de negocio.
- `book_service.py`: Lógica para manejo de libros
- `user_service.py`: Lógica para manejo de usuarios
- `reading_service.py`: Lógica para manejo de lecturas

### `backend/api/`
Contiene la implementación de la API REST.
- `app.py`: Configuración principal de la API
- `routes/`: Endpoints organizados por entidad

### `backend/utils/`
Contiene utilidades y funciones auxiliares.

### `frontend/`
Aquí se ubicará el código de Angular (en una fase posterior).

## Implementación Paso a Paso

### 1. Instalación de Dependencias

Crea el archivo `requirements.txt` en la carpeta `backend/`:

```bash
mysql-connector-python==8.0.31
python-dotenv==1.0.0
Flask==2.3.3
Flask-CORS==4.0.0
```
Para instalar las dependencias, ejecuta:

```bash
pip install -r requirements.txt
```