# Para ver libros

```bash
http://localhost:8080/api/books/
```

- Esta es la ruta de la API para obtener todos los libros con paginación.

- Para obtener libros con numero limitado le damos un numero

```bash
http://localhost:8080/api/books/?page_size=20
```

- o podemos pedirle que nos muestre la pagina 2

```bash
http://localhost:8080/api/books/?page=2
```

- o combinar ambos

```bash
http://localhost:8080/api/books/?page=2&page_size=20
```
- Para buscar por id

```bash
host:8080/api/books/{id}
```


# Para obtener y añadir usuario
```bash
http://localhost:8080/api/users/

POST: Cuerpo: 
{
  "name": "Ejemplo Usuario",
  "last_name1": "Apellido1",
  "last_name2": "Apellido2",
  "birthdate": "1990-01-01",
  "union_date": "2023-01-01",
  "nickname": "ejemplo_user",
  "password": "password123",
  "role_name": "client"
}
```
- Para buscar por nickname
```bash
http://localhost:8080/api/users/{nickname}
```
# Para obtener estadisticas de lecturas

```bash
http://localhost:8080/api/users/{nickname}/stats
```
- Para obtener libros de un usuario (Esta no esta capada, salen todos los libros del usuario)

```bash
http://localhost:8080/api/users/{nickname}/books
```
# Obtener progreso de lecturas

```bash
http://localhost:8080/api/readings/progress/{user_nickname}
```
- Para añadir un progreso de lectura

```bash
POST: http://localhost:8080/api/readings/progress

Cuerpo: 
{
  "nickname": "Usuario",
  "book_title": "Libro",
  "pages_read_list": "30,45,50",
  "dates_list": "2023-12-01,2023-12-02,2023-12-03"
}

```

# Para obtener reseñas de libros

```bash
http://localhost:8080/api/readings/reviews 
```

# Para obtener y añadir Autores
- Esta no esta capada, saldran todos los autores de la base de datos
```bash
http://localhost:8080/api/authors

Post:
Cuerpo: 
{
  "name": "Nombre",
  "last_name1": "Autor",
  "last_name2": "Apellido",
  "description": "Este es un autor de ejemplo para demostrar cómo funciona la API."
}
```
# Para añadir un libro con todas sus dependencias

```bash
Post: Cuerpo:

{
  "title": "Libro de Ejemplo",
  "pages": 300,
  "synopsis": "Este es un libro de ejemplo para la API.",
  "custom_description": "Mi descripción personalizada del libro.",
  "author_name": "NombreAutor",
  "author_last_name1": "apellidoAutor",
  "author_last_name2": "",
  "genre1": "Fantasía",
  "genre2": "Aventura",
  "genre3": "",
  "genre4": "",
  "genre5": "",
  "saga_name": "Saga de Ejemplo",
  "user_nickname": "usuario",
  "status": "reading",
  "date_added": "2023-01-01",
  "date_start": "2023-01-02",
  "date_ending": null,
  "review": "Me está gustando mucho este libro.",
  "rating": 8.5,
  "phrases": "Esta es una frase destacada del libro.",
  "notes": "Estas son mis notas personales sobre el libro."
}