-- Actualización del esquema de base de datos
DROP DATABASE IF EXISTS TFG2;
CREATE DATABASE TFG2;
USE TFG2;

-- Tabla de roles de usuario (definir antes de User)
CREATE TABLE user_role (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- Tabla de usuarios
CREATE TABLE user (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    last_name1 VARCHAR(100),
    last_name2 VARCHAR(100),
    birthdate DATE,
    union_date DATE NOT NULL,
    nickName VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- Almacenar hash de contraseña, no texto plano
    id_role INT NOT NULL,
    FOREIGN KEY (id_role) REFERENCES user_role(id)
);

-- Tabla de libros
CREATE TABLE book (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    pages INT NOT NULL
);

-- Tabla de autores
CREATE TABLE author (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    last_name1 VARCHAR(100),
    last_name2 VARCHAR(100),
    description TEXT
);

-- Tabla de sagas
CREATE TABLE saga (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Tabla de géneros
CREATE TABLE genre (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Tabla de sinopsis (oficial del libro)
CREATE TABLE synopsis (
    id INT AUTO_INCREMENT PRIMARY KEY,
    text TEXT NOT NULL,
    id_book INT UNIQUE,
    FOREIGN KEY (id_book) REFERENCES book(id) ON DELETE CASCADE
);

-- NUEVA TABLA: Descripción personalizada del libro por usuario
CREATE TABLE user_book_description (
    id_user INT,
    id_book INT,
    custom_description TEXT NOT NULL,
    PRIMARY KEY (id_user, id_book),
    FOREIGN KEY (id_user) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (id_book) REFERENCES book(id) ON DELETE CASCADE
);

-- NUEVA TABLA: Estados de lectura
CREATE TABLE reading_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255)
);

-- Relaciones muchos a muchos
CREATE TABLE book_has_author (
    id_book INT,
    id_author INT,
    PRIMARY KEY (id_book, id_author),
    FOREIGN KEY (id_book) REFERENCES book(id) ON DELETE CASCADE,
    FOREIGN KEY (id_author) REFERENCES author(id) ON DELETE CASCADE
);

CREATE TABLE book_has_saga (
    id_book INT,
    id_saga INT,
    PRIMARY KEY (id_book, id_saga),
    FOREIGN KEY (id_book) REFERENCES book(id) ON DELETE CASCADE,
    FOREIGN KEY (id_saga) REFERENCES saga(id) ON DELETE CASCADE
);

CREATE TABLE book_has_genre (
    id_book INT,
    id_genre INT,
    PRIMARY KEY (id_book, id_genre),
    FOREIGN KEY (id_book) REFERENCES book(id) ON DELETE CASCADE,
    FOREIGN KEY (id_genre) REFERENCES genre(id) ON DELETE CASCADE
);

-- Relación usuario-libro (lecturas) - Actualizada para usar la tabla reading_status
CREATE TABLE user_has_book (
    id_user INT,
    id_book INT,
    id_status INT NOT NULL,
    date_added DATE NOT NULL,
    date_start DATE, -- Puede ser NULL si aún no ha comenzado
    date_ending DATE, -- Puede ser NULL si no ha terminado
    PRIMARY KEY (id_user, id_book),
    FOREIGN KEY (id_user) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (id_book) REFERENCES book(id) ON DELETE CASCADE,
    FOREIGN KEY (id_status) REFERENCES reading_status(id)
);

-- Tabla de reseñas
CREATE TABLE review (
    id INT AUTO_INCREMENT PRIMARY KEY,
    text TEXT NOT NULL,
    rating DECIMAL(5,2) CHECK (rating BETWEEN 1 AND 10), -- Cambiado el límite superior a 10
    date_created DATE NOT NULL, -- Añadida fecha de creación
    id_book INT NOT NULL,
    id_user INT NOT NULL,
    FOREIGN KEY (id_book) REFERENCES book(id) ON DELETE CASCADE,
    FOREIGN KEY (id_user) REFERENCES user(id) ON DELETE CASCADE
);

-- Tabla de frases destacadas
CREATE TABLE phrase (
    id INT AUTO_INCREMENT PRIMARY KEY,
    text TEXT NOT NULL,
    id_book INT NOT NULL,
    id_user INT NOT NULL,
    date_added DATE NOT NULL, -- Añadida fecha de adición
    FOREIGN KEY (id_book) REFERENCES book(id) ON DELETE CASCADE,
    FOREIGN KEY (id_user) REFERENCES user(id) ON DELETE CASCADE
);

-- Tabla de progreso de lectura
CREATE TABLE reading_progress (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    pages INT NOT NULL, 
    id_book INT NOT NULL,
    id_user INT NOT NULL,
    FOREIGN KEY (id_book) REFERENCES book(id) ON DELETE CASCADE,
    FOREIGN KEY (id_user) REFERENCES user(id) ON DELETE CASCADE,
    INDEX idx_user_book_date (id_user, id_book, date) -- Índice para consultas de progreso
);

-- Tabla de notas personales sobre libros
CREATE TABLE book_note (
    id INT AUTO_INCREMENT PRIMARY KEY,
    text TEXT NOT NULL,
    id_book INT NOT NULL,
    id_user INT NOT NULL,
    date_created DATE NOT NULL, -- Añadida fecha de creación
    date_modified DATE, -- Añadida fecha de modificación
    FOREIGN KEY (id_book) REFERENCES book(id) ON DELETE CASCADE,
    FOREIGN KEY (id_user) REFERENCES user(id) ON DELETE CASCADE
);

-- Insertar estados de lectura predeterminados
INSERT INTO reading_status (name, description) VALUES 
('reading', 'El usuario está actualmente leyendo este libro'),
('completed', 'El usuario ha terminado de leer este libro'),
('dropped', 'El usuario ha abandonado la lectura de este libro'),
('on_hold', 'El usuario ha pausado temporalmente la lectura'),
('plan_to_read', 'El usuario planea leer este libro en el futuro');
/*
-- Crear índices adicionales para mejorar el rendimiento
CREATE INDEX idx_book_title ON book(title);
CREATE INDEX idx_user_nickname ON user(nickName);
CREATE INDEX idx_author_name ON author(name, last_name1, last_name2);
CREATE INDEX idx_genre_name ON genre(name);
CREATE INDEX idx_saga_name ON saga(name);
*/