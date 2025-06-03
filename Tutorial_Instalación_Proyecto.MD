# Como instalarse y configurar el proyecto Lectoria

1. Backend

- Primero de todo ir a este repositorio [Repositorio Backend](https://github.com/joss0102/LectoriaBack).
- Una vez en el repositorio deberemos clonarlo a nuestro equipo, usaremos:
```git
git clone https://github.com/joss0102/LectoriaBack.git
```
- Una vez clonado tendremos unas instrucciones dentro del [README.md](https://github.com/joss0102/LectoriaBack/blob/main/README.md)
- El siguiente paso es ejecutar la base de datos en MySQL que esta en la carpeta database, ejecutaremos ese archivo .sql , posteriormente crearemos un usuario llamado Lectoria en localhost con la contraseña `1234` y le daremos todos los privilegios a ese usuario.
- Una vez configurada la base de datos y el servicio MySQL activo, el siguiente paso es ir a la carpeta backend y seguir estos comandos:
```git
cd backend
python -m venv venv // En macOS: python3 -m venv venv 
source venv/Scripts/activate  // En macOS: source venv/bin/activate
pip install -r requirements.txt
pip install --upgrade mysql-connector-python // por si acaso esta desactualizado.
pip install transformers torch 
```
- El siguiente paso sera configurar el archivo .env ( Aunque ya viene configurado previamente con el usuario que ya hemos creado anteriormente ).
- Finalmente podemos ya ejecutar el backend con: 
```git
python main.py
```
- La API estará disponible en http://localhost:8080 y en el anterior [README.md](https://github.com/joss0102/LectoriaBack/blob/main/README.md) para poder atacar a los endpoints.

