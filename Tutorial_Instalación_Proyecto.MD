# Cómo instalar y configurar el proyecto **Lectoria**

Este documento explica los pasos necesarios para instalar y ejecutar el proyecto **Lectoria**, compuesto por un backend en **Python (Flask)** y un frontend en **Angular**, con una base de datos en **MySQL**.

---

## 1. Backend

- Primero, accede al repositorio del backend:  
  [Repositorio Backend](https://github.com/joss0102/LectoriaBack)

- Clona el repositorio en tu equipo:

```bash
git clone https://github.com/joss0102/LectoriaBack.git
````

- Una vez clonado, encontrarás instrucciones en el archivo [README.md del backend](https://github.com/joss0102/LectoriaBack/blob/main/README.md), pero las detallamos también a continuación:

## 1.1. Configurar la base de datos

- Abre tu gestor de bases de datos MySQL.

- Ejecuta el archivo .sql que se encuentra en la carpeta database del repositorio para crear las tablas necesarias.

- Crea un usuario en MySQL llamado Lectoria en localhost con la contraseña 1234, y asígnale todos los privilegios sobre la base de datos creada.

## 1.2. Configurar el entorno y dependencias

- Accede a la carpeta del backend:

```bash
cd backend
```
- Crea y activa un entorno virtual:
```bash
python -m venv venv         # En macOS: python3 -m venv venv
source venv/Scripts/activate  # En macOS: source venv/bin/activate
```
- Instala las dependencias necesarias:
```bash
pip install -r requirements.txt
pip install --upgrade mysql-connector-python  # Por si acaso está desactualizado
pip install transformers torch
```
## 1.3. Configurar variables de entorno

- El archivo .env ya viene preconfigurado con el usuario y contraseña definidos anteriormente, por lo que no necesitas modificarlo si usas esas credenciales.

## 1.4. Ejecutar el backend
```bash
python main.py
```

- La API estará disponible en: `http://localhost:8080` y Consulta el [README del backend](https://github.com/joss0102/LectoriaBack/blob/main/README.md) para ver los endpoints disponibles y cómo interactuar con ellos.

## 2. Frontend

- Ahora instalaremos la parte visual del proyecto. Accede al repositorio del frontend: [Repositorio Frontend](https://github.com/joss0102/LectoriaFront).

- Clona el repositorio y accede a la carpeta:
```bash
git clone https://github.com/joss0102/LectoriaFront.git
cd LectoriaFront
```
- Instala las dependencias del proyecto:
```bash
npm install
```
- Finalmente, ejecuta el servidor de desarrollo:
```bash
ng serve  # Es importante tener Angular CLI instalado previamente
```

- El proyecto se abrirá automáticamente en tu navegador en la siguiente URL: `http://localhost:4200`


