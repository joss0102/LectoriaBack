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
    Procedimiento para añadir un libro, su información y sus relaciones
    Mejorado con:
    - Mejor manejo de errores
    - Validaciones adicionales
    - Soporte para campos NULL (date_start, date_ending)
    - Uso de la nueva tabla reading_status
    - Soporte para descripciones personalizadas
*/
DROP PROCEDURE IF EXISTS add_book_full;
DELIMITER $$

CREATE PROCEDURE add_book_full(
    IN p_title VARCHAR(255),      
    IN p_pages INT,               
    IN p_synopsis TEXT,
    IN p_custom_description TEXT, -- Descripción personalizada del usuario (puede ser diferente de la sinopsis oficial)           
    IN p_author_name VARCHAR(255),            
    IN p_author_last_name1 VARCHAR(255),             
    IN p_author_last_name2 VARCHAR(255),             
    IN p_genre1 VARCHAR(255),   -- Primer género
    IN p_genre2 VARCHAR(255),   -- Segundo género
    IN p_genre3 VARCHAR(255),   -- Tercer género
    IN p_genre4 VARCHAR(255),   -- Cuarto género
    IN p_genre5 VARCHAR(255),   -- Quinto género
    IN p_saga_name VARCHAR(255),  
    IN p_user_nickname VARCHAR(100), 
    IN p_status VARCHAR(50), -- Ahora usamos la tabla reading_status
    IN p_date_added DATE,         
    IN p_date_start DATE,         
    IN p_date_ending DATE,        
    IN p_review TEXT,             
    IN p_rating DECIMAL(4,2),              
    IN p_phrases TEXT,            
    IN p_notes TEXT               
)
BEGIN
    DECLARE genre_id_1 INT;
    DECLARE genre_id_2 INT;
    DECLARE genre_id_3 INT;
    DECLARE genre_id_4 INT;
    DECLARE genre_id_5 INT;
    DECLARE new_book_id INT;
    DECLARE saga_id INT;
    DECLARE author_id INT;
    DECLARE user_id INT;
    DECLARE status_id INT;
    DECLARE error_code VARCHAR(100);
    DECLARE error_message VARCHAR(255);
    
    -- Declarar handler para errores con mensajes más informativos
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            error_code = RETURNED_SQLSTATE,
            error_message = MESSAGE_TEXT;
        
        ROLLBACK;
        SELECT CONCAT('Error al agregar el libro "', p_title, '": Código ', error_code, ' - ', error_message) AS mensaje;
    END;
    
    -- Iniciar transacción para garantizar la integridad de los datos
    START TRANSACTION;
    
    -- Validaciones iniciales
    IF p_title IS NULL OR TRIM(p_title) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El título del libro no puede estar vacío';
    END IF;
    
    IF p_pages IS NULL OR p_pages <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El número de páginas debe ser mayor que cero';
    END IF;
    
    IF p_author_name IS NULL OR TRIM(p_author_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre del autor no puede estar vacío';
    END IF;
    
    IF p_user_nickname IS NULL OR TRIM(p_user_nickname) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nickname del usuario no puede estar vacío';
    END IF;
    
    IF p_date_added IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de adición no puede ser nula';
    END IF;
    
    -- Si el estado es 'completed', la fecha de finalización no debería ser NULL
    IF p_status = 'completed' AND p_date_ending IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Si el estado es "completed", la fecha de finalización es obligatoria';
    END IF;
    
    -- Verificación de coherencia de fechas
    IF p_date_start IS NOT NULL AND p_date_ending IS NOT NULL AND p_date_start > p_date_ending THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de inicio no puede ser posterior a la fecha de finalización';
    END IF;
    
    -- Obtener el ID del estado de lectura
    SELECT id INTO status_id FROM reading_status WHERE name = p_status LIMIT 1;
    IF status_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de lectura no válido. Utilice: reading, completed, dropped, on_hold, plan_to_read';
    END IF;
    
    -- 1. Verificar si el libro ya existe
    SELECT id INTO new_book_id FROM book WHERE title = p_title LIMIT 1;
    
    -- Si no existe, crearlo
    IF new_book_id IS NULL THEN
        INSERT INTO book (title, pages) VALUES (p_title, p_pages);
        SET new_book_id = LAST_INSERT_ID();
        
        -- 2. Insertar la sinopsis oficial solo si es un libro nuevo
        IF p_synopsis IS NOT NULL AND TRIM(p_synopsis) <> '' THEN
            INSERT INTO synopsis (text, id_book) VALUES (p_synopsis, new_book_id);
        END IF;

        -- 3. Manejar la saga
        IF p_saga_name IS NOT NULL AND TRIM(p_saga_name) <> '' THEN
            SELECT id INTO saga_id FROM saga WHERE name = p_saga_name LIMIT 1;
            IF saga_id IS NULL THEN
                INSERT INTO saga (name) VALUES (p_saga_name);
                SET saga_id = LAST_INSERT_ID();
            END IF;
            INSERT INTO book_has_saga (id_book, id_saga) VALUES (new_book_id, saga_id);
        END IF;

        -- 4. Manejar autor
        SELECT id INTO author_id FROM author 
        WHERE name = p_author_name 
        AND (last_name1 = p_author_last_name1 OR (last_name1 IS NULL AND p_author_last_name1 IS NULL))
        AND (last_name2 = p_author_last_name2 OR (last_name2 IS NULL AND p_author_last_name2 IS NULL))
        LIMIT 1;
        
        IF author_id IS NULL THEN
            INSERT INTO author (name, last_name1, last_name2) 
            VALUES (p_author_name, p_author_last_name1, p_author_last_name2);
            SET author_id = LAST_INSERT_ID();
        END IF;
        INSERT INTO book_has_author (id_book, id_author) VALUES (new_book_id, author_id);

        -- 5. Manejar géneros solo si es un libro nuevo
        -- Género 1
        IF p_genre1 IS NOT NULL AND TRIM(p_genre1) <> '' THEN
            SELECT id INTO genre_id_1 FROM genre WHERE name = p_genre1 LIMIT 1;
            IF genre_id_1 IS NULL THEN
                INSERT INTO genre (name) VALUES (p_genre1);
                SET genre_id_1 = LAST_INSERT_ID();
            END IF;
            INSERT INTO book_has_genre (id_book, id_genre) VALUES (new_book_id, genre_id_1);
        END IF;

        -- Género 2
        IF p_genre2 IS NOT NULL AND TRIM(p_genre2) <> '' THEN
            SELECT id INTO genre_id_2 FROM genre WHERE name = p_genre2 LIMIT 1;
            IF genre_id_2 IS NULL THEN
                INSERT INTO genre (name) VALUES (p_genre2);
                SET genre_id_2 = LAST_INSERT_ID();
            END IF;
            INSERT INTO book_has_genre (id_book, id_genre) VALUES (new_book_id, genre_id_2);
        END IF;

        -- Género 3
        IF p_genre3 IS NOT NULL AND TRIM(p_genre3) <> '' THEN
            SELECT id INTO genre_id_3 FROM genre WHERE name = p_genre3 LIMIT 1;
            IF genre_id_3 IS NULL THEN
                INSERT INTO genre (name) VALUES (p_genre3);
                SET genre_id_3 = LAST_INSERT_ID();
            END IF;
            INSERT INTO book_has_genre (id_book, id_genre) VALUES (new_book_id, genre_id_3);
        END IF;

        -- Género 4
        IF p_genre4 IS NOT NULL AND TRIM(p_genre4) <> '' THEN
            SELECT id INTO genre_id_4 FROM genre WHERE name = p_genre4 LIMIT 1;
            IF genre_id_4 IS NULL THEN
                INSERT INTO genre (name) VALUES (p_genre4);
                SET genre_id_4 = LAST_INSERT_ID();
            END IF;
            INSERT INTO book_has_genre (id_book, id_genre) VALUES (new_book_id, genre_id_4);
        END IF;

        -- Género 5
        IF p_genre5 IS NOT NULL AND TRIM(p_genre5) <> '' THEN
            SELECT id INTO genre_id_5 FROM genre WHERE name = p_genre5 LIMIT 1;
            IF genre_id_5 IS NULL THEN
                INSERT INTO genre (name) VALUES (p_genre5);
                SET genre_id_5 = LAST_INSERT_ID();
            END IF;
            INSERT INTO book_has_genre (id_book, id_genre) VALUES (new_book_id, genre_id_5);
        END IF;
    END IF;

    -- 6. Manejar usuario (siempre se ejecuta, tanto para libro nuevo como existente)
    SELECT id INTO user_id FROM user WHERE nickName = p_user_nickname LIMIT 1;
    IF user_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario especificado no existe. Debe crearlo primero.';
    END IF;

    -- 7. Añadir descripción personalizada si se proporciona
    IF p_custom_description IS NOT NULL AND TRIM(p_custom_description) <> '' THEN
        INSERT INTO user_book_description (id_user, id_book, custom_description) 
        VALUES (user_id, new_book_id, p_custom_description)
        ON DUPLICATE KEY UPDATE 
            custom_description = VALUES(custom_description);
    END IF;

    -- 8. Insertar en user_has_book (siempre se ejecuta)
    INSERT INTO user_has_book (id_user, id_book, id_status, date_added, date_start, date_ending) 
    VALUES (user_id, new_book_id, status_id, p_date_added, p_date_start, p_date_ending)
    ON DUPLICATE KEY UPDATE 
        id_status = VALUES(id_status),
        date_start = VALUES(date_start),
        date_ending = VALUES(date_ending);

    -- 9. Insertar review (solo si no existe ya para este usuario y libro)
    IF p_review IS NOT NULL AND TRIM(p_review) <> '' THEN
        -- Validar el rating
        IF p_rating < 1 OR p_rating > 10 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El rating debe estar entre 1 y 10';
        END IF;
        
        INSERT INTO review (text, rating, date_created, id_book, id_user) 
        VALUES (p_review, p_rating, CURDATE(), new_book_id, user_id)
        ON DUPLICATE KEY UPDATE 
            text = VALUES(text),
            rating = VALUES(rating),
            date_created = CURDATE();
    END IF;

    -- 10. Insertar frases destacadas
    IF p_phrases IS NOT NULL AND TRIM(p_phrases) <> '' THEN
        INSERT INTO phrase (text, id_book, id_user, date_added) 
        VALUES (p_phrases, new_book_id, user_id, CURDATE())
        ON DUPLICATE KEY UPDATE text = VALUES(text), date_added = CURDATE();
    END IF;

    -- 11. Insertar notas
    IF p_notes IS NOT NULL AND TRIM(p_notes) <> '' THEN
        INSERT INTO book_note (text, id_book, id_user, date_created, date_modified) 
        VALUES (p_notes, new_book_id, user_id, CURDATE(), NULL)
        ON DUPLICATE KEY UPDATE 
            text = VALUES(text), 
            date_modified = CURDATE();
    END IF;

    -- 12. Actualizar automáticamente el estado basado en el progreso de lectura
    -- Si hay registros de progreso que sumen las páginas totales, marcar como completado
    IF (SELECT SUM(pages) FROM reading_progress 
        WHERE id_book = new_book_id AND id_user = user_id) >= 
       (SELECT pages FROM book WHERE id = new_book_id) THEN
       
        -- Obtener el ID del estado 'completed'
        SELECT id INTO status_id FROM reading_status WHERE name = 'completed';
        
        -- Actualizar el estado y la fecha de finalización si no estaba establecida
        UPDATE user_has_book 
        SET id_status = status_id,
            date_ending = COALESCE(date_ending, CURDATE())
        WHERE id_user = user_id AND id_book = new_book_id;
    END IF;

   
    COMMIT;

END $$

DELIMITER ;
/*
    Procedimiento para almacenar progreso de lecturas
    Mejorado con:
    - Mejor manejo de errores
    - Validaciones adicionales
    - Actualización automática del estado de lectura
*/
DROP PROCEDURE IF EXISTS add_reading_progress_full;
DELIMITER //

CREATE PROCEDURE add_reading_progress_full(
    IN p_nickname VARCHAR(100),       -- Nickname del usuario
    IN p_book_title VARCHAR(255),     -- Título del libro
    IN p_pages_read_list TEXT,        -- Lista de páginas leídas separadas por comas
    IN p_dates_list TEXT              -- Lista de fechas correspondientes separadas por comas
)
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_book_id INT;
    DECLARE v_total_pages INT;
    DECLARE v_total_pages_read INT DEFAULT 0;
    DECLARE v_pages_count INT DEFAULT 0;
    DECLARE v_dates_count INT DEFAULT 0;
    DECLARE v_pages_item VARCHAR(20);
    DECLARE v_date_item VARCHAR(20);
    DECLARE v_delimiter_pos INT;
    DECLARE v_remaining_pages TEXT;
    DECLARE v_remaining_dates TEXT;
    DECLARE v_status_id INT;
    DECLARE v_completed_status_id INT;
    DECLARE v_reading_status_id INT;
    DECLARE error_code VARCHAR(100);
    DECLARE error_message VARCHAR(255);
    
    -- Declarar handler para errores con mensajes más informativos
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            error_code = RETURNED_SQLSTATE,
            error_message = MESSAGE_TEXT;
        
        ROLLBACK;
        SELECT CONCAT('Error al añadir progreso de lectura: Código ', error_code, ' - ', error_message) AS mensaje;
    END;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validaciones iniciales
    IF p_nickname IS NULL OR TRIM(p_nickname) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nickname del usuario no puede estar vacío';
    END IF;
    
    IF p_book_title IS NULL OR TRIM(p_book_title) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El título del libro no puede estar vacío';
    END IF;
    
    IF p_pages_read_list IS NULL OR TRIM(p_pages_read_list) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista de páginas leídas no puede estar vacía';
    END IF;
    
    IF p_dates_list IS NULL OR TRIM(p_dates_list) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista de fechas no puede estar vacía';
    END IF;
    
    -- Obtener el ID del usuario
    SELECT id INTO v_user_id FROM user WHERE nickName = p_nickname;
    IF v_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El usuario no existe.';
    END IF;

    -- Obtener el ID del libro y el número total de páginas
    SELECT id, pages INTO v_book_id, v_total_pages FROM book WHERE title = p_book_title;
    IF v_book_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El libro no existe.';
    END IF;
    
    -- Verificar si el usuario tiene este libro asignado
    IF NOT EXISTS (SELECT 1 FROM user_has_book WHERE id_user = v_user_id AND id_book = v_book_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El usuario no tiene este libro en su colección. Añada el libro primero.';
    END IF;

    -- Obtener IDs de estados
    SELECT id INTO v_completed_status_id FROM reading_status WHERE name = 'completed';
    SELECT id INTO v_reading_status_id FROM reading_status WHERE name = 'reading';
    
    -- Inicializar las variables para el bucle
    SET v_remaining_pages = p_pages_read_list;
    SET v_remaining_dates = p_dates_list;

    -- Procesar cada par página-fecha
    WHILE LENGTH(v_remaining_pages) > 0 AND LENGTH(v_remaining_dates) > 0 DO
        -- Extraer el próximo valor de páginas
        SET v_delimiter_pos = LOCATE(',', v_remaining_pages);
        IF v_delimiter_pos = 0 THEN
            SET v_pages_item = v_remaining_pages;
            SET v_remaining_pages = '';
        ELSE
            SET v_pages_item = LEFT(v_remaining_pages, v_delimiter_pos - 1);
            SET v_remaining_pages = SUBSTRING(v_remaining_pages, v_delimiter_pos + 1);
        END IF;
        
        -- Extraer el próximo valor de fecha
        SET v_delimiter_pos = LOCATE(',', v_remaining_dates);
        IF v_delimiter_pos = 0 THEN
            SET v_date_item = v_remaining_dates;
            SET v_remaining_dates = '';
        ELSE
            SET v_date_item = LEFT(v_remaining_dates, v_delimiter_pos - 1);
            SET v_remaining_dates = SUBSTRING(v_remaining_dates, v_delimiter_pos + 1);
        END IF;
        

        
        -- Validar que la fecha no sea futura
        IF v_date_item > CURDATE() THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede registrar progreso de lectura con fecha futura';
        END IF;
        
        -- Validar número de páginas
        IF NOT v_pages_item REGEXP '^[0-9]+' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de páginas inválido. Debe ser un número entero';
        END IF;
        
        IF CAST(v_pages_item AS UNSIGNED) > v_total_pages THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El número de páginas leídas no puede ser mayor que el total de páginas del libro';
        END IF;
        
        -- Verificar que ambos valores no sean NULL
        IF v_pages_item != 'null' AND v_date_item != 'null' THEN
            -- Insertar el progreso de lectura
            INSERT INTO reading_progress (date, pages, id_book, id_user)
            VALUES (v_date_item, v_pages_item, v_book_id, v_user_id);
            
            -- Acumular el total de páginas leídas para este libro
            SET v_total_pages_read = v_total_pages_read + CAST(v_pages_item AS UNSIGNED);
        END IF;
    END WHILE;
    
    -- Calcular el total de páginas leídas para este libro (incluye registros anteriores)
    SELECT SUM(pages) INTO v_total_pages_read FROM reading_progress 
    WHERE id_user = v_user_id AND id_book = v_book_id;
    
    -- Actualizar el estado de lectura y las fechas basado en el progreso
    -- Si el usuario ha leído todo el libro
    IF v_total_pages_read >= v_total_pages THEN
        -- Actualizar a "completed" y establecer fecha de finalización si no existe
        UPDATE user_has_book 
        SET id_status = v_completed_status_id,
            date_ending = COALESCE(date_ending, CURDATE())
        WHERE id_user = v_user_id AND id_book = v_book_id;
    ELSE
        -- Si el usuario ha leído algo pero no todo, asegurarse de que esté en "reading"
        -- y que tenga fecha de inicio
        UPDATE user_has_book 
        SET id_status = v_reading_status_id,
            date_start = COALESCE(date_start, CURDATE())
        WHERE id_user = v_user_id AND id_book = v_book_id AND id_status != v_completed_status_id;
    END IF;
    
    -- Confirmamos la transacción
    COMMIT;
    

END //

DELIMITER ;
/*
    Procedimiento para añadir un usuario con su información
    Mejorado con:
    - Mejor manejo de errores
    - Validaciones adicionales
    - Hashing de contraseña
*/

DROP PROCEDURE IF EXISTS add_user_full;
DELIMITER $$

CREATE PROCEDURE add_user_full(
    IN p_name VARCHAR(100),        -- Nombre del usuario
    IN p_last_name1 VARCHAR(100),  -- Primer apellido
    IN p_last_name2 VARCHAR(100),  -- Segundo apellido
    IN p_birthdate DATE,           -- Fecha de nacimiento
    IN p_union_date DATE,          -- Fecha de registro en la plataforma
    IN p_nickName VARCHAR(100),    -- Nombre de usuario único
    IN p_password VARCHAR(255),    -- Contraseña (se almacenará hasheada)
    IN p_role_name VARCHAR(50)     -- Nombre del rol (admin, usuario, etc.)
)
BEGIN
    DECLARE role_id, user_id INT;
    DECLARE hashed_password VARCHAR(255);
    DECLARE error_code VARCHAR(100);
    DECLARE error_message VARCHAR(255);
    
    -- Declarar handler para errores con mensajes más informativos
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            error_code = RETURNED_SQLSTATE,
            error_message = MESSAGE_TEXT;
        
        ROLLBACK;
        SELECT CONCAT('Error al agregar el usuario "', p_nickName, '": Código ', error_code, ' - ', error_message) AS mensaje;
    END;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validaciones iniciales
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre del usuario no puede estar vacío';
    END IF;
    
    IF p_nickName IS NULL OR TRIM(p_nickName) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nickname del usuario no puede estar vacío';
    END IF;
    
    IF p_password IS NULL OR TRIM(p_password) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contraseña no puede estar vacía';
    END IF;
    
    IF p_union_date IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de registro no puede ser nula';
    END IF;
    
    IF p_role_name IS NULL OR TRIM(p_role_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El rol del usuario no puede estar vacío';
    END IF;
    
    -- Verificar si el nickname ya existe
    IF EXISTS (SELECT 1 FROM user WHERE nickName = p_nickName) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nickname ya está en uso. Por favor, elija otro.';
    END IF;
    
    -- Verificación de fecha de nacimiento
    IF p_birthdate IS NOT NULL AND p_birthdate > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de nacimiento no puede ser futura';
    END IF;
    
    -- Hasheamos la contraseña (usando SHA-256 como ejemplo, idealmente usar funciones más seguras)
    SET hashed_password = SHA2(p_password, 256);
    
    -- 1. Buscar si el rol ya existe en `user_role`
    SELECT id INTO role_id FROM user_role WHERE name = p_role_name LIMIT 1;

    -- 2. Si el rol no existe, crearlo
    IF role_id IS NULL THEN
        INSERT INTO user_role (name) VALUES (p_role_name);
        SET role_id = LAST_INSERT_ID();
    END IF;

    -- 3. Insertar el usuario en `user` con la contraseña hasheada
    INSERT INTO user (name, last_name1, last_name2, birthdate, union_date, nickName, password, id_role)
    VALUES (p_name, p_last_name1, p_last_name2, p_birthdate, p_union_date, p_nickName, hashed_password, role_id);

    -- 4. Obtener el ID del nuevo usuario
    SET user_id = LAST_INSERT_ID();
    
    -- Confirmamos la transacción
    COMMIT;
    
END $$

DELIMITER ;
/*
    Procedimiento para añadir un usuario con su información
    Mejorado con:
    - Mejor manejo de errores
    - Validaciones adicionales
    - Hashing de contraseña
*/

DROP PROCEDURE IF EXISTS add_user_full;
DELIMITER $$

CREATE PROCEDURE add_user_full(
    IN p_name VARCHAR(100),        -- Nombre del usuario
    IN p_last_name1 VARCHAR(100),  -- Primer apellido
    IN p_last_name2 VARCHAR(100),  -- Segundo apellido
    IN p_birthdate DATE,           -- Fecha de nacimiento
    IN p_union_date DATE,          -- Fecha de registro en la plataforma
    IN p_nickName VARCHAR(100),    -- Nombre de usuario único
    IN p_password VARCHAR(255),    -- Contraseña (se almacenará hasheada)
    IN p_role_name VARCHAR(50)     -- Nombre del rol (admin, usuario, etc.)
)
BEGIN
    DECLARE role_id, user_id INT;
    DECLARE hashed_password VARCHAR(255);
    DECLARE error_code VARCHAR(100);
    DECLARE error_message VARCHAR(255);
    
    -- Declarar handler para errores con mensajes más informativos
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            error_code = RETURNED_SQLSTATE,
            error_message = MESSAGE_TEXT;
        
        ROLLBACK;
        SELECT CONCAT('Error al agregar el usuario "', p_nickName, '": Código ', error_code, ' - ', error_message) AS mensaje;
    END;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validaciones iniciales
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre del usuario no puede estar vacío';
    END IF;
    
    IF p_nickName IS NULL OR TRIM(p_nickName) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nickname del usuario no puede estar vacío';
    END IF;
    
    IF p_password IS NULL OR TRIM(p_password) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contraseña no puede estar vacía';
    END IF;
    
    IF p_union_date IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de registro no puede ser nula';
    END IF;
    
    IF p_role_name IS NULL OR TRIM(p_role_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El rol del usuario no puede estar vacío';
    END IF;
    
    -- Verificar si el nickname ya existe
    IF EXISTS (SELECT 1 FROM user WHERE nickName = p_nickName) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nickname ya está en uso. Por favor, elija otro.';
    END IF;
    
    -- Verificación de fecha de nacimiento
    IF p_birthdate IS NOT NULL AND p_birthdate > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de nacimiento no puede ser futura';
    END IF;
    
    -- Hasheamos la contraseña (usando SHA-256 como ejemplo, idealmente usar funciones más seguras)
    SET hashed_password = SHA2(p_password, 256);
    
    -- 1. Buscar si el rol ya existe en `user_role`
    SELECT id INTO role_id FROM user_role WHERE name = p_role_name LIMIT 1;

    -- 2. Si el rol no existe, crearlo
    IF role_id IS NULL THEN
        INSERT INTO user_role (name) VALUES (p_role_name);
        SET role_id = LAST_INSERT_ID();
    END IF;

    -- 3. Insertar el usuario en `user` con la contraseña hasheada
    INSERT INTO user (name, last_name1, last_name2, birthdate, union_date, nickName, password, id_role)
    VALUES (p_name, p_last_name1, p_last_name2, p_birthdate, p_union_date, p_nickName, hashed_password, role_id);

    -- 4. Obtener el ID del nuevo usuario
    SET user_id = LAST_INSERT_ID();
    
    -- Confirmamos la transacción
    COMMIT;
    
END $$

DELIMITER ;
/*
    Procedimiento para añadir un autor con su información
*/
DROP PROCEDURE IF EXISTS add_author_full;
DELIMITER $$

CREATE PROCEDURE add_author_full(
    IN p_name VARCHAR(100),        -- Nombre del autor
    IN p_last_name1 VARCHAR(100),  -- Primer apellido
    IN p_last_name2 VARCHAR(100),  -- Segundo apellido
    IN p_description TEXT          -- Descripción o biografía del autor
)
BEGIN
    DECLARE author_id INT;
    DECLARE error_code VARCHAR(100);
    DECLARE error_message VARCHAR(255);
    
    -- Declarar handler para errores con mensajes más informativos
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            error_code = RETURNED_SQLSTATE,
            error_message = MESSAGE_TEXT;
        
        ROLLBACK;
        SELECT CONCAT('Error al agregar el autor "', p_name, '": Código ', error_code, ' - ', error_message) AS mensaje;
    END;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validaciones iniciales
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre del autor no puede estar vacío';
    END IF;
    
    -- Verificar si el autor ya existe
    SELECT id INTO author_id FROM author 
    WHERE name = p_name 
    AND (last_name1 = p_last_name1 OR (last_name1 IS NULL AND p_last_name1 IS NULL))
    AND (last_name2 = p_last_name2 OR (last_name2 IS NULL AND p_last_name2 IS NULL))
    LIMIT 1;
    
    IF author_id IS NOT NULL THEN
        -- Si el autor existe, actualizamos su descripción
        UPDATE author 
        SET description = p_description
        WHERE id = author_id;
        
        SELECT CONCAT('Autor "', 
                     p_name, ' ', 
                     COALESCE(p_last_name1, ''), ' ', 
                     COALESCE(p_last_name2, ''),
                     '" actualizado correctamente con ID ', author_id) AS mensaje;
    ELSE
        -- Si el autor no existe, lo creamos
        INSERT INTO author (name, last_name1, last_name2, description) 
        VALUES (p_name, p_last_name1, p_last_name2, p_description);
        
        SET author_id = LAST_INSERT_ID();
        
    END IF;
    
    -- Confirmamos la transacción
    COMMIT;
END $$

DELIMITER ;
-- Vista 1: Vista de información completa de libros
-- Combina libro, sinopsis, autores, géneros y saga
CREATE OR REPLACE VIEW vw_book_complete_info AS
SELECT 
    b.id AS book_id,
    b.title AS book_title,
    b.pages AS book_pages,
    s.text AS synopsis,
    GROUP_CONCAT(DISTINCT CONCAT(a.name, ' ', COALESCE(a.last_name1, ''), ' ', COALESCE(a.last_name2, '')) SEPARATOR ', ') AS authors,
    GROUP_CONCAT(DISTINCT g.name SEPARATOR ', ') AS genres,
    GROUP_CONCAT(DISTINCT sg.name SEPARATOR ', ') AS sagas
FROM 
    book b
LEFT JOIN 
    synopsis s ON b.id = s.id_book
LEFT JOIN 
    book_has_author bha ON b.id = bha.id_book
LEFT JOIN 
    author a ON bha.id_author = a.id
LEFT JOIN 
    book_has_genre bhg ON b.id = bhg.id_book
LEFT JOIN 
    genre g ON bhg.id_genre = g.id
LEFT JOIN 
    book_has_saga bhs ON b.id = bhs.id_book
LEFT JOIN 
    saga sg ON bhs.id_saga = sg.id
GROUP BY 
    b.id, b.title, b.pages, s.text;

-- Vista 2: Vista de información de lectura de usuarios
-- Combina usuario, libro, estado de lectura, fechas y progreso
CREATE OR REPLACE VIEW vw_user_reading_info AS
SELECT 
    u.id AS user_id,
    u.name AS user_name,
    u.last_name1 AS user_last_name1,
    u.last_name2 AS user_last_name2,
    u.nickName AS user_nickname,
    b.id AS book_id,
    b.title AS book_title,
    b.pages AS total_pages,
    rs.name AS reading_status,
    rs.description AS status_description,
    uhb.date_added,
    uhb.date_start,
    uhb.date_ending,
    COALESCE(SUM(rp.pages), 0) AS pages_read,
    CASE 
        WHEN b.pages > 0 THEN ROUND((COALESCE(SUM(rp.pages), 0) / b.pages) * 100, 2)
        ELSE 0
    END AS progress_percentage,
    ubd.custom_description
FROM 
    user u
JOIN 
    user_has_book uhb ON u.id = uhb.id_user
JOIN 
    book b ON uhb.id_book = b.id
JOIN 
    reading_status rs ON uhb.id_status = rs.id
LEFT JOIN 
    reading_progress rp ON u.id = rp.id_user AND b.id = rp.id_book
LEFT JOIN 
    user_book_description ubd ON u.id = ubd.id_user AND b.id = ubd.id_book
GROUP BY 
    u.id, u.name, u.last_name1, u.last_name2, u.nickName, 
    b.id, b.title, b.pages, rs.name, rs.description, 
    uhb.date_added, uhb.date_start, uhb.date_ending, ubd.custom_description;

-- Vista 3: Vista de reseñas de libros
-- Combina información de libros con sus reseñas, calificaciones y usuario que las escribió
CREATE OR REPLACE VIEW vw_book_reviews AS
SELECT 
    r.id AS review_id,
    b.id AS book_id,
    b.title AS book_title,
    u.id AS user_id,
    u.nickName AS user_nickname,
    CONCAT(u.name, ' ', COALESCE(u.last_name1, ''), ' ', COALESCE(u.last_name2, '')) AS user_full_name,
    r.text AS review_text,
    r.rating,
    r.date_created AS review_date,
    GROUP_CONCAT(DISTINCT CONCAT(a.name, ' ', COALESCE(a.last_name1, ''), ' ', COALESCE(a.last_name2, '')) SEPARATOR ', ') AS authors,
    GROUP_CONCAT(DISTINCT g.name SEPARATOR ', ') AS genres
FROM 
    review r
JOIN 
    book b ON r.id_book = b.id
JOIN 
    user u ON r.id_user = u.id
LEFT JOIN 
    book_has_author bha ON b.id = bha.id_book
LEFT JOIN 
    author a ON bha.id_author = a.id
LEFT JOIN 
    book_has_genre bhg ON b.id = bhg.id_book
LEFT JOIN 
    genre g ON bhg.id_genre = g.id
GROUP BY 
    r.id, b.id, b.title, u.id, u.nickName, user_full_name, r.text, r.rating, r.date_created;

-- Vista 4: Vista de progreso de lectura detallado
-- Muestra el progreso de lectura por usuario y libro con datos temporales
CREATE OR REPLACE VIEW vw_reading_progress_detailed AS
SELECT 
    u.id AS user_id,
    u.nickName AS user_nickname,
    b.id AS book_id,
    b.title AS book_title,
    b.pages AS total_pages,
    rp.id AS progress_id,
    rp.date AS reading_date,
    rp.pages AS pages_read_session,
    (SELECT SUM(pages) FROM reading_progress 
     WHERE id_user = u.id AND id_book = b.id AND date <= rp.date) AS cumulative_pages_read,
    CASE 
        WHEN b.pages > 0 THEN ROUND(((SELECT SUM(pages) FROM reading_progress 
                                    WHERE id_user = u.id AND id_book = b.id AND date <= rp.date) / b.pages) * 100, 2)
        ELSE 0
    END AS cumulative_progress_percentage,
    rs.name AS current_reading_status
FROM 
    reading_progress rp
JOIN 
    user u ON rp.id_user = u.id
JOIN 
    book b ON rp.id_book = b.id
JOIN 
    user_has_book uhb ON u.id = uhb.id_user AND b.id = uhb.id_book
JOIN 
    reading_status rs ON uhb.id_status = rs.id
ORDER BY 
    u.id, b.id, rp.date;

-- Vista 5: Vista de estadísticas de lectura
-- Proporciona estadísticas agregadas de lectura por usuario
CREATE OR REPLACE VIEW vw_user_reading_stats AS
SELECT 
    u.id AS user_id,
    u.nickName AS user_nickname,
    CONCAT(u.name, ' ', COALESCE(u.last_name1, ''), ' ', COALESCE(u.last_name2, '')) AS user_full_name,
    COUNT(DISTINCT uhb.id_book) AS total_books,
    SUM(CASE WHEN rs.name = 'completed' THEN 1 ELSE 0 END) AS completed_books,
    SUM(CASE WHEN rs.name = 'reading' THEN 1 ELSE 0 END) AS reading_books,
    SUM(CASE WHEN rs.name = 'plan_to_read' THEN 1 ELSE 0 END) AS planned_books,
    SUM(CASE WHEN rs.name = 'dropped' THEN 1 ELSE 0 END) AS dropped_books,
    SUM(CASE WHEN rs.name = 'on_hold' THEN 1 ELSE 0 END) AS on_hold_books,
    SUM(b.pages) AS total_pages_all_books,
    SUM(CASE WHEN rs.name = 'completed' THEN b.pages ELSE 0 END) AS total_pages_read_completed,
    COALESCE(
        (SELECT SUM(rp.pages) FROM reading_progress rp WHERE rp.id_user = u.id), 
        0
    ) AS total_pages_read_sessions,
    ROUND(AVG(r.rating), 2) AS average_rating,
    -- Género más leído (basado en libros completados)
    (SELECT g.name 
     FROM book_has_genre bhg
     JOIN genre g ON bhg.id_genre = g.id
     JOIN user_has_book uhb2 ON bhg.id_book = uhb2.id_book
     WHERE uhb2.id_user = u.id AND uhb2.id_status = (SELECT id FROM reading_status WHERE name = 'completed')
     GROUP BY g.id
     ORDER BY COUNT(*) DESC
     LIMIT 1) AS favorite_genre,
    -- Autor más leído (basado en libros completados)
    (SELECT CONCAT(a.name, ' ', COALESCE(a.last_name1, ''), ' ', COALESCE(a.last_name2, ''))
     FROM book_has_author bha
     JOIN author a ON bha.id_author = a.id
     JOIN user_has_book uhb3 ON bha.id_book = uhb3.id_book
     WHERE uhb3.id_user = u.id AND uhb3.id_status = (SELECT id FROM reading_status WHERE name = 'completed')
     GROUP BY a.id
     ORDER BY COUNT(*) DESC
     LIMIT 1) AS favorite_author,
    -- Tiempo promedio de lectura por libro (en días)
    COALESCE(
        AVG(CASE 
            WHEN uhb.date_start IS NOT NULL AND uhb.date_ending IS NOT NULL 
            THEN DATEDIFF(uhb.date_ending, uhb.date_start)
            ELSE NULL
        END), 
        0
    ) AS avg_reading_days_per_book,
    -- Promedio de páginas leídas por día (basado en libros completados con fechas)
    CASE 
        WHEN SUM(CASE WHEN uhb.date_start IS NOT NULL AND uhb.date_ending IS NOT NULL THEN 1 ELSE 0 END) > 0
        THEN ROUND(
            SUM(CASE WHEN uhb.date_start IS NOT NULL AND uhb.date_ending IS NOT NULL THEN b.pages ELSE 0 END) /
            SUM(CASE WHEN uhb.date_start IS NOT NULL AND uhb.date_ending IS NOT NULL THEN DATEDIFF(uhb.date_ending, uhb.date_start) ELSE 0 END)
        , 2)
        ELSE 0
    END AS avg_pages_per_day
FROM 
    user u
LEFT JOIN 
    user_has_book uhb ON u.id = uhb.id_user
LEFT JOIN 
    book b ON uhb.id_book = b.id
LEFT JOIN 
    reading_status rs ON uhb.id_status = rs.id
LEFT JOIN 
    review r ON u.id = r.id_user AND b.id = r.id_book
GROUP BY 
    u.id, u.nickName, user_full_name;
-- Rebecca Yarros
CALL add_author_full(
    'Rebecca', 'Yarros', '', 
    'Rebecca Yarros es una autora bestseller de novelas románticas para jóvenes adultos. Conocida por su narrativa emocional e intensa, ha escrito series populares como la trilogía Empíreo y La última carta. Esposa de un militar, su escritura a menudo explora temas de resiliencia, amor y crecimiento personal.'
);

-- Sarah J. Maas
CALL add_author_full(
    'Sarah', 'J.', 'Maas', 
    'Sarah J. Maas es una autora bestseller de The New York Times, reconocida por sus novelas de fantasía épica y para jóvenes adultos. Creó las inmensamente populares series Trono de Cristal y Una Corte de Rosas y Espinas. Su escritura se caracteriza por protagonistas femeninas fuertes, una construcción de mundo intrincada y tramas románticas complejas.'
);

-- Lauren Roberts
CALL add_author_full(
    'Lauren', 'Roberts', '', 
    'Lauren Roberts es una autora de fantasía para jóvenes adultos conocida por su serie Powerless. Su escritura se enfoca en mundos distópicos y personajes que navegan estructuras sociales complejas. Ha ganado rápidamente popularidad por su enfoque innovador de la narrativa fantástica y su desarrollo de personajes cautivador.'
);

-- Jennifer L. Armentrout
CALL add_author_full(
    'Jennifer', 'L.', 'Armentrout', 
    'Jennifer L. Armentrout es una autora prolífica y bestseller de ficción para jóvenes adultos, nuevos adultos y adultos en múltiples géneros, incluyendo romance paranormal, contemporáneo y de fantasía. Es conocida por sus series Lux, De Sangre y Cenizas, y su capacidad para crear narrativas apasionantes con personajes complejos.'
);

-- Brandon Sanderson
CALL add_author_full(
    'Brandon', 'Sanderson', '', 
    'Brandon Sanderson es un reconocido autor de fantasía y ciencia ficción conocido por sus sistemas de magia intrincados y su construcción épica de mundos. Completó la serie Rueda del Tiempo de Robert Jordan y es famoso por la trilogía Nacidos de la Bruma, El Archivo de las Tormentas, y su enfoque único de la escritura de fantasía que enfatiza reglas mágicas lógicas y sistemáticas.'
);

-- Holly Black
CALL add_author_full(
    'Holly', 'Black', '', 
    'Holly Black es una aclamada autora de fantasía para jóvenes adultos conocida por sus oscuros y complejos cuentos de hadas. Co-creó las Crónicas Spiderwick y escribió la popular trilogía Habitantes del Aire. Su escritura a menudo explora temas complejos de poder, identidad y ambigüedad moral en entornos mágicos.'
);

-- Alba Zamora
CALL add_author_full(
    'Alba', 'Zamora', '', 
    'Alba Zamora es una autora emergente en el género de fantasía romántica para jóvenes adultos. Su serie Crónicas de Hiraia explora temas de amor prohibido y destino personal dentro de mundos fantásticos ricamente imaginados. Es conocida por crear narrativas emocionalmente cautivadoras que mezclan romance y elementos mágicos.'
);

-- H. D. Carlton
CALL add_author_full(
    'H.', 'D.', 'Carlton', 
    'H. D. Carlton es una autora de romance contemporáneo conocida por escribir novelas románticas oscuras e intensas. Su trabajo a menudo explora la profundidad psicológica y las dinámicas de relaciones complejas, desafiando los límites del romance tradicional.'
);

-- Tahereh Mafi
CALL add_author_full(
    'Tahereh', 'Mafi', '', 
    'Tahereh Mafi es una autora bestseller conocida por su serie Shatter Me, una innovadora novela distópica que combina elementos de ciencia ficción y romance. Su estilo de escritura distintivo se caracteriza por un uso poético del lenguaje y narrativas que exploran la transformación personal y la resistencia.'
);

-- Stephanie Garber
CALL add_author_full(
    'Stephanie', 'Garber', '', 
    'Stephanie Garber es una autora de fantasía para jóvenes adultos conocida por su serie Caraval. Su escritura se destaca por crear mundos mágicos inmersivos con elementos de juego, ilusión y misterio, explorando temas de destino, libertad y los límites entre la realidad y la fantasía.'
);

-- Jay Kristoff
CALL add_author_full(
    'Jay', 'Kristoff', '', 
    'Jay Kristoff es un autor australiano de ciencia ficción y fantasía conocido por sus novelas oscuras y originales. Sus obras, como El Imperio del Vampiro, combinan elementos de horror y fantasía oscura, destacándose por su narrativa innovadora y mundos complejos.'
);

-- C. S. Pacat
CALL add_author_full(
    'C.', 'S.', 'Pecat', 
    'C. S. Pacat es una autora conocida por su trilogía El Príncipe Cautivo, que combina elementos de fantasía y romance. Su trabajo se caracteriza por explorar dinámicas de poder, política y relaciones románticas complejas en mundos de fantasía elaborados.'
);

-- Miriam Mosquera
CALL add_author_full(
    'Miriam', 'Mosquera', '', 
    'Miriam Mosquera es una autora de fantasía oscura que explora temas de mitología, espiritualidad y relaciones complejas. Su trabajo se centra en mundos donde los límites entre el bien y el mal se desdibujan, presentando narrativas que desafían las percepciones tradicionales.'
);

-- Emily McIntire
CALL add_author_full(
    'Emily', 'McIntire', '', 
    'Emily McIntire es una autora de romance contemporáneo y reinterpretaciones oscuras de cuentos clásicos. Su trabajo se caracteriza por transformar narrativas familiares en historias para adultos que exploran la psicología de los personajes y las dinámicas de poder.'
);

-- Carissa Broadbent
CALL add_author_full(
    'Carissa', 'Broadbent', '', 
    'Carissa Broadbent es una autora emergente de fantasía romántica conocida por crear mundos complejos con sistemas de magia únicos. Su trabajo combina elementos de fantasía oscura y romance, explorando temas de poder, transformación y conexiones más allá de lo convencional.'
);

-- Rina Kent
CALL add_author_full(
    'Rina', 'Kent', '', 
    'Rina Kent es una autora de romance contemporáneo y new adult conocida por sus novelas intensas y psicológicamente complejas. Su trabajo se enfoca en relaciones con dinámicas de poder desafiantes y personajes con profundidades emocionales complejas.'
);

-- Amber V. Nicole
CALL add_author_full(
    'Amber', 'V.', 'Nicole', 
    'Amber V. Nicole es una autora de fantasía oscura y romance que se destaca por crear mundos mitológicos complejos. Su trabajo explora temas de dioses, monstruos y las complejas relaciones entre seres sobrenaturales, presentando narrativas que desafían las expectativas del género.'
);

-- Harley Laroux
CALL add_author_full(
    'Harley', 'Laroux', '', 
    'Harley Laroux es una autora de romance oscuro conocida por crear narrativas intensas que exploran los límites entre el amor, el poder y la oscuridad. Su trabajo se caracteriza por relaciones complejas que desafían las nociones tradicionales de romance y consentimiento.'
);
CALL add_user_full(
    'Jose Ayrton',        -- Nombre del usuario
    'Rosell',             -- Primer apellido
    'Bonavina',           -- Segundo apellido
    '2000-08-06',         -- Fecha de nacimiento
    '2024-03-30',         -- Fecha de registro en la plataforma
    'joss0102',           -- Nombre de usuario único (nickname)
    '1234',               -- Contraseña (ahora se hasheará automáticamente)
    'admin'               -- Rol del usuario (si no existe, se crea)
);
CALL add_user_full(
    'David',  -- Nombre del usuario
    'Fernandez',       -- Primer apellido
    'Valbuena',     -- Segundo apellido
    '2003-08-06',   -- Fecha de nacimiento
    '2024-03-30',   -- Fecha de registro en la plataforma
    'DavidFdz',     -- Nombre de usuario único (nickname)
    '1234',         -- Contraseña (debería almacenarse encriptada)
    'admin'         -- Rol del usuario (si no existe, se crea)
);
CALL add_user_full(
    'Dumi',  -- Nombre del usuario
    'Tomas',       -- Primer apellido
    '',     -- Segundo apellido
    '2002-09-14',   -- Fecha de nacimiento
    '2024-03-30',   -- Fecha de registro en la plataforma
    'dumitxmss',     -- Nombre de usuario único (nickname)
    '1234',         -- Contraseña (debería almacenarse encriptada)
    'client'         -- Rol del usuario (si no existe, se crea)
);
CALL add_user_full(
    'Isabel',  -- Nombre del usuario
    'Isidro',       -- Primer apellido
    'Fernandez',     -- Segundo apellido
    '2002-04-18',   -- Fecha de nacimiento
    '2024-03-30',   -- Fecha de registro en la plataforma
    'issafeez',     -- Nombre de usuario único (nickname)
    '1234',         -- Contraseña (debería almacenarse encriptada)
    'client'         -- Rol del usuario (si no existe, se crea)
);
CALL add_user_full(
    'Helio',  -- Nombre del usuario
    'Rebato',       -- Primer apellido
    'Gamez',     -- Segundo apellido
    '2002-07-25',   -- Fecha de nacimiento
    '2024-03-30',   -- Fecha de registro en la plataforma
    'heliiovk_',     -- Nombre de usuario único (nickname)
    '1234',         -- Contraseña (debería almacenarse encriptada)
    'client'         -- Rol del usuario (si no existe, se crea)
);
/*
    Ejemplo de añadir un libro

CALL add_book_full(
'',                -- Título del libro
000,               -- Número de páginas del libro
'',                -- Sinopsis oficial del libro
'',                -- Descripción personalizada del usuario (NUEVO PARÁMETRO)
'', '', '',        -- Nombre y apellidos del autor
'','','', '', '', -- Géneros del libro, hasta un máximo de 5
'',                -- Nombre de la saga a la que pertenece
'',                -- Nickname del usuario que añade el libro
'',                -- Estado de lectura ('reading', 'completed', 'dropped', 'on_hold', 'plan_to_read')
'',                -- Fecha en que se agrega el libro a la colección
'',                -- Fecha cuando el usuario comenzó a leer el libro (puede ser NULL)
'',                -- Fecha cuando terminó el libro (puede ser NULL)
'',                -- Reseña del libro
0.0,               -- Puntuación del libro (ahora entre 1 y 10)
'',                -- Frase destacada del libro
''                 -- Notas personales sobre el libro
);
*/
/*
    Inserción de todos los libros adaptados al nuevo formato del procedimiento
    con el parámetro adicional de descripción personalizada
*/

CALL add_book_full(
    'Alas de sangre',730, -- Título, páginas
    'En un mundo al borde de la guerra, Violet Sorrengail, una joven que debería haber ingresado en el Cuerpo de Escribas, es obligada a unirse a los jinetes de dragones, una élite de guerreros que montan dragones. Violet debe sobrevivir al brutal entrenamiento y a las traiciones mientras descubre secretos que podrían cambiar el curso de la guerra.',
    'Me encantó la evolución de Violet y su relación con los otros reclutas. La construcción del mundo de los dragones es fascinante y los giros argumentales me mantuvieron en vilo.', -- NUEVA descripción personalizada
    'Rebecca','Yarros','', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía épica','','','', -- géneros
    'Empíreo','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2023-12-22','2024-01-03', -- fecha agregación, fechaInicio, fechaFin
    'Una historia emocionante con personajes complejos y una trama llena de giros inesperados. La evolución de Violet es fascinante.', -- reseña
    8.57, -- puntuación
    'A veces, la fuerza no viene de los músculos, sino de la voluntad de seguir adelante cuando todo parece perdido.', -- frase
    'Releer capítulo 12 - la escena del primer vuelo es impresionante' -- Notas
);

CALL add_book_full(
    'Trono de cristal',489, -- Título, páginas
    'En las tenebrosas minas de sal de Endovier, una muchacha de dieciocho años cumple cadena perpetua. Es una asesina profesional, la mejor en lo suyo, pero ha cometido un error fatal. La han capturado. El joven capitán Westfall le ofrece un trato: la libertad a cambio de un enorme sacrificio.',
    'Una protagonista fuerte e ingeniosa. Lo que más me gustó fue el equilibrio entre las intrigas de palacio y los elementos de fantasía que van creciendo en importancia conforme avanza la historia.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía heroica','','','', -- géneros
    'Trono de cristal','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2023-12-29','2024-01-05', -- fecha agregación, fechaInicio, fechaFin
    'Un inicio prometedor para la saga, con una protagonista fuerte y un mundo lleno de intrigas.', -- reseña
    7.50, -- puntuación
    'La mayor debilidad de una persona no es la que todo el mundo ve, sino la que ella misma oculta incluso a sí misma.', -- frase
    'Celaena es increíblemente sarcástica - tomar notas de sus diálogos' -- Notas
);

CALL add_book_full(
    'Corona de medianoche',500, -- Título, páginas
    'Celaena Sardothien, la asesina más temida de Adarlan, ha sobrevivido a las pruebas del Rey de los Asesinos, pero a un alto costo. Ahora, debe decidir cuánto está dispuesta a sacrificar por su gente y por aquellos a quienes ama.',
    'Me sorprendió positivamente cómo este libro expande el universo y profundiza en los personajes. La trama de la competición está bien ejecutada y hay momentos muy tensos.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía heroica','','','', -- géneros
    'Trono de cristal','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-01-03','2024-01-10', -- fecha agregación, fechaInicio, fechaFin
    'La evolución de Celaena como personaje es magistral, con giros argumentales que mantienen en vilo.', -- reseña
    7.71, -- puntuación
    'Incluso en la oscuridad, puede nacer la luz más brillante.', -- frase
    'Analizar el desarrollo del personaje de Chaol en esta entrega' -- Notas
);

CALL add_book_full(
    'Heredera de fuego',664, -- Título, páginas
    'Celaena ha sobrevivido a pruebas mortales, pero ahora se enfrenta a su destino. Mientras el reino se desmorona, deberá elegir entre su legado y su corazón, entre la venganza y la redención.',
    'El punto de inflexión de la saga. La introducción de nuevos personajes como Rowan y Manon añade nuevas dimensiones a la historia. La evolución de Celaena/Aelin es perfecta.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía heroica','','','', -- géneros
    'Trono de cristal','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-01-08','2024-01-13', -- fecha agregación, fechaInicio, fechaFin
    'El punto de inflexión de la saga donde todo cobra mayor profundidad y complejidad.', -- reseña
    9.29, -- puntuación
    'El fuego que te quema es el mismo que te hace brillar.', -- frase
    'El capítulo 42 contiene una de las mejores escenas de acción de la saga' -- Notas
);

CALL add_book_full(
    'Reina de sombras',730, -- Título, páginas
    'Celaena Sardothien ha aceptado su identidad como Aelin Galathynius, reina de Terrasen. Pero antes de reclamar su trono, debe liberar a su pueblo de la tiranía del rey de Adarlan.',
    'El desarrollo de Aelin como líder es fascinante. Las escenas de acción son espectaculares y la forma en que se entrelazan las diferentes tramas es magistral. La química entre Aelin y Rowan es electrizante.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía heroica','','','', -- géneros
    'Una corte de rosas y espinas','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-01-10','2024-01-16', -- fecha agregación, fechaInicio, fechaFin
    'Intenso, emocionante y lleno de momentos épicos. La transformación de Aelin es impresionante.', -- reseña
    10.00, -- puntuación (ajustada a 10.00)
    'No eres dueña de tu destino, pero sí de cómo lo enfrentas.', -- frase
    'Subrayar todos los diálogos entre Aelin y Rowan - química perfecta' -- Notas
);

CALL add_book_full(
    'Una corte de rosas y espinas',456, -- Título, páginas
    'Feyre, una cazadora, mata a un lobo en el bosque y una bestia monstruosa exige una compensación. Arrastrada a un reino mágico, descubre que su captor no es una bestia, sino Tamlin, un Alto Señor del mundo de las hadas. Mientras Feyre habita en su corte, una antigua y siniestra sombra crece sobre el reino, y deberá luchar para salvar a Tamlin y su pueblo.',
    'Una reinvención fascinante de La Bella y la Bestia. El mundo feérico está construido de manera original y los personajes tienen profundidad. El giro final de la trama me dejó sin palabras.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía oscura','','','', -- géneros
    'Una corte de rosas y espinas','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-01-14','2024-01-19', -- fecha agregación, fechaInicio, fechaFin
    'Hermosa adaptación de La Bella y la Bestia con un giro oscuro y sensual. La evolución de Feyre es fascinante.', -- reseña
    7.79, -- puntuación
    'No dejes que el miedo a perder te impida jugar el juego.', -- frase
    'Releer la escena del baile bajo la máscara - simbolismo impresionante' -- Notas
);

CALL add_book_full(
    'Una corte de niebla y furia',592, -- Título, páginas
    'Feyre ha superado la prueba de Amarantha, pero a un alto costo. Ahora debe aprender a vivir con sus decisiones y descubrir su lugar en el mundo de las hadas mientras una guerra se avecina.',
    'El mejor libro de la saga. La forma en que Maas desarrolla la relación entre Feyre y Rhysand es magistral. La Corte de la Noche es simplemente fascinante y la expansión del mundo es perfecta.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía oscura','','','', -- géneros
    'Una corte de rosas y espinas','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-01-16','2024-01-23', -- fecha agregación, fechaInicio, fechaFin
    'Mejor que el primero en todos los aspectos. Rhysand se convierte en uno de los mejores personajes de la saga.', -- reseña
    10.00, -- puntuación (ajustada a 10.00)
    'A las estrellas que escuchan, y a los sueños que están ansiosos por ser respondidos.', -- frase
    'Analizar el desarrollo del personaje de Rhysand - arco magistral' -- Notas
);

CALL add_book_full(
    'Una corte de alas y ruina',800, -- Título, páginas
    'La guerra se acerca y Feyre debe unir a los Alta Corte y al mortal mundo para enfrentarse al Rey Hybern. Mientras tanto, descubre secretos sobre su propia familia y poder.',
    'Una conclusión épica para la trilogía principal. Las batallas son impresionantes y el desarrollo de todos los personajes secundarios es notable. El Círculo Íntimo se ha convertido en uno de mis grupos de personajes favoritos.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía épica','','','', -- géneros
    'Una corte de rosas y espinas','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-01-20','2024-01-23', -- fecha agregación, fechaInicio, fechaFin
    'Conclusión emocionante de la trilogía original, con batallas épicas y momentos emocionales intensos.', -- reseña
    9.14, -- puntuación
    'Sólo puedes ser valiente cuando has tenido miedo.', -- frase
    'El discurso de Feyre en el capítulo 67 es inspirador - memorizar' -- Notas
);

CALL add_book_full(
    'Una corte de hielo y estrellas',240, -- Título, páginas
    'Una historia navideña ambientada en el mundo de ACOTAR, donde Feyre y Rhysand organizan una celebración invernal en la Corte de la Noche.',
    'Una historia ligera pero encantadora que muestra momentos cotidianos del Círculo Íntimo. Ideal para fans que quieren más interacciones entre los personajes favoritos sin grandes amenazas.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Romance','Fantasía','','','', -- géneros
    'Trono de cristal','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-01-23','2024-01-29', -- fecha agregación, fechaInicio, fechaFin
    'Historia corta y dulce para los fans de la saga, aunque menos sustancial que los libros principales.', -- reseña
    5.00, -- puntuación
    'La familia no es sólo sangre, sino aquellos por los que estarías dispuesto a sangrar.', -- frase
    'Lectura ligera para disfrutar en invierno' -- Notas
);

CALL add_book_full(
    'Imperio de tormentas',752, -- Título, páginas
    'Aelin Galathynius se enfrenta a su destino final mientras prepara a su reino para la batalla contra Erawan. Mientras tanto, Manon Blackbeak debe tomar decisiones que cambiarán el curso de la guerra.',
    'Uno de mis favoritos de la saga. Las escenas de batalla son épicas y el desarrollo de Manon es especialmente notable. Este libro me hizo llorar varias veces.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Fantasía épica','Romantasy','','','', -- géneros
    'Trono de cristal','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-01-24','2024-01-29', -- fecha agregación, fechaInicio, fechaFin
    'Uno de los mejores libros de la saga, con acción incesante y momentos emocionales devastadores.', -- reseña
    10.00, -- puntuación (ajustada a 10.00)
    'Tú no cedas. Tú no retrocedas. Hay que ser esa chispa que enciende el fuego de la revolución.', -- frase
    'El capítulo 89 es uno de los más impactantes de toda la saga - preparar pañuelos' -- Notas
);

CALL add_book_full(
    'Torre del alba',760, -- Título, páginas
    'Aelin Galathynius ha sido capturada por la Reina Maeve y su destino pende de un hilo. Mientras tanto, sus aliados se dispersan por el mundo tratando de reunir fuerzas para la batalla final contra Erawan.',
    'Este libro utiliza múltiples perspectivas de manera magistral. El sufrimiento de Aelin es desgarrador y la forma en que sus aliados luchan por encontrarla es emocionante. Manon sigue robándose cada escena.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Fantasía épica','Romantasy','','','', -- géneros
    'Trono de cristal','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-01-24','2024-02-06', -- fechas: agregación, inicio, fin
    'Intenso y emocional, aunque el ritmo es más lento que en libros anteriores. Los capítulos de Manon son los mejores.', -- reseña
    7.86, -- puntuación
    'Incluso en la oscuridad más profunda, no olvides quién eres.', -- frase destacada
    'Analizar los paralelismos entre Aelin y Elena' -- Notas
);

CALL add_book_full(
    'Reino de cenizas',966, -- Título, páginas
    'La batalla final ha llegado. Aelin y sus aliados deben unirse para enfrentarse a Erawan y Maeve en un conflicto que decidirá el destino de su mundo.',
    'Una conclusión épica para una de las mejores sagas de fantasía. Las batallas son impresionantes, los momentos emocionales son profundos y el cierre de todos los arcos argumentales es satisfactorio. El epílogo es perfecto.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Fantasía épica','Romantasy','','','', -- géneros
    'Trono de cristal','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-01-30','2024-02-11', -- fechas: agregación, inicio, fin
    'Conclusión épica y satisfactoria para la saga. Sarah J. Maas demuestra por qué es la reina del Romantasy.', -- reseña
    10.00, -- puntuación (ajustada a 10.00)
    'La luz siempre encontrará la manera de abrirse paso, incluso en los lugares más oscuros.', -- frase destacada
    'El epílogo es perfecto - leer con música épica de fondo' -- Notas
);

CALL add_book_full(
    'Una corte de llamas plateadas',816, -- Título, páginas
    'Nesta Archeron, ahora sumida en la autodestrucción, es llevada a la Casa del Viento por Cassian y Azriel. Allí deberá enfrentar sus demonios mientras una nueva amenaza surge en las montañas.',
    'Una historia de redención poderosa. El desarrollo de Nesta desde un personaje difícil de querer hasta una heroína compleja es brillante. Su romance con Cassian tiene la tensión perfecta y las escenas de entrenamiento son adictivas.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía oscura','','','', -- géneros
    'Una corte de rosas y espinas','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-02-08','2024-02-20', -- fechas: agregación, inicio, fin
    'Historia de redención poderosa. Nesta se convierte en uno de los personajes más complejos del universo ACOTAR.', -- reseña
    8.43, -- puntuación
    'No eres nada hasta que decides serlo todo.', -- frase destacada
    'Subrayar todas las escenas de entrenamiento - crecimiento impresionante' -- Notas
);

CALL add_book_full(
    'Casa de tierra y sangre',792, -- Título, páginas
    'Bryce Quinlan, una medio-hada que trabaja en una galería de arte, investiga una serie de asesinatos junto al cazador de recompensas Hunt Athalar en la vibrante ciudad de Lunathion.',
    'Una vuelta de tuerca a la fantasía urbana con toques de misterio y noir. Bryce es una protagonista diferente a las anteriores de SJM, con un enfoque más moderno. El worldbuilding es impresionante y los personajes secundarios son memorables.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Fantasía urbana','Romantasy','','','', -- géneros
    'Ciudad medialuna','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-02-12','2024-02-25', -- fechas: agregación, inicio, fin
    'Fascinante mezcla de fantasía y elementos urbanos. Bryce es una protagonista refrescante y carismática.', -- reseña
    9.29, -- puntuación
    'A través del amor, todos son inmortales.', -- frase destacada
    'El sistema de magia es único - hacer diagramas para entenderlo mejor' -- Notas
);

CALL add_book_full(
    'Alas de hierro',885, -- Título, páginas
    'Violet Sorrengail continúa su entrenamiento como jinete de dragones mientras la guerra se intensifica. Los secretos sobre su familia y el conflicto comienzan a revelarse.',
    'Aún mejor que el primero. La evolución de Violet es perfecta y su relación con Xaden se profundiza de manera natural. Los giros argumentales son impactantes y el cliffhanger final es devastador. No podía dejar de leerlo.', -- NUEVA descripción personalizada
    'Rebecca','Yarros','', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía épica','','','', -- géneros
    'Empíreo','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-02-22','2024-03-01', -- fechas: agregación, inicio, fin
    'Segundo libro aún mejor que el primero. La evolución de Violet y Xaden es magistral. Cliffhanger devastador.', -- reseña
    10.00, -- puntuación (ajustada a 10.00)
    'Elige tu propio camino, incluso si tienes que arrastrarte por él.', -- frase destacada
    'El capítulo final cambia TODO - releer antes del próximo libro' -- Notas
);

CALL add_book_full(
    'Casa de cielo y aliento',826, -- Título, páginas
    'Bryce Quinlan y Hunt Athalar intentan recuperar la normalidad después de los eventos traumáticos, pero nuevas amenazas emergen en la ciudad de Lunathion mientras descubren secretos sobre su mundo y sus propias conexiones.',
    'Una secuela que expande el universo de manera magistral. La evolución de la relación entre Bryce y Hunt es conmovedora, y los nuevos elementos mitológicos añaden capas a la historia. Las conexiones con otros universos de Maas son fascinantes.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Fantasía urbana','Romantasy','','','', -- géneros
    'Ciudad medialuna','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-02-25','2024-03-07', -- fechas: agregación, inicio, fin
    'Expande magistralmente el mundo creado en el primer libro. La evolución de la relación Bryce-Hunt es conmovedora.', -- reseña
    8.71, -- puntuación
    'A veces las cosas rotas son las más fuertes, porque han tenido que aprender a sostenerse solas.', -- frase destacada
    'El cameo de personajes de ACOTAR es brillante - analizar conexiones' -- Notas
);

CALL add_book_full(
    'Casa de llama y sombra',849, -- Título, páginas
    'Bryce se encuentra en un mundo desconocido mientras sus amigos en Lunathion luchan por sobrevivir a las consecuencias de sus acciones. Todos deberán enfrentar desafíos inimaginables para reunirse nuevamente.',
    'El mejor libro de la saga hasta ahora. Las conexiones entre los diferentes universos de Maas son brillantes y las revelaciones sobre los orígenes de los mundos son fascinantes. El final es electrizante y abre posibilidades infinitas.', -- NUEVA descripción personalizada
    'Sarah','J.','Maas', -- Autor, apellido1, apellido2
    'Fantasía urbana','Romantasy','','','', -- géneros
    'Ciudad medialuna','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-03-03','2024-03-09', -- fechas: agregación, inicio, fin
    'El mejor libro de la saga hasta ahora. Conexiones inesperadas con otros universos de Maas. Final electrizante.', -- reseña
    10.00, -- puntuación (ajustada a 10.00)
    'El amor no es una debilidad, es el arma más poderosa que tenemos.', -- frase destacada
    'Hacer mapa de conexiones entre los diferentes universos de SJM' -- Notas
);

CALL add_book_full(
    'Powerless',591, -- Título, páginas
    'En un mundo donde algunos nacen con poderes y otros no, Paedyn Gray, una Ordinaria, se ve obligada a competir en los Juegos Purging para demostrar su valía, mientras oculta su verdadera naturaleza.',
    'Una mezcla interesante de Los Juegos del Hambre con elementos de X-Men. La premisa es original y la protagonista es carismática. La química entre los personajes principales es palpable desde el principio y los giros argumentales mantienen el interés.', -- NUEVA descripción personalizada
    'Lauren','Roberts','', -- Autor, apellido1, apellido2
    'Romance','Fantasía distópica','','','', -- géneros
    'Powerless','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-03-07','2024-03-12', -- fechas: agregación, inicio, fin
    'Mezcla interesante de "Los Juegos del Hambre" y fantasía. La química entre los protagonistas es eléctrica.', -- reseña
    8.17, -- puntuación
    'Ser ordinario en un mundo extraordinario es el poder más peligroso de todos.', -- frase destacada
    'Comparar con otros libros de competiciones/torneos' -- Notas
);

-- Continuamos con el resto de los libros siguiendo el mismo patrón
CALL add_book_full(
    'De sangre y cenizas',663, -- Título, páginas
    'Poppy está destinada a ser la Doncella, guardada para los dioses hasta el día de su Ascensión. Pero cuando es asignada a su nuevo guardián, Hawke, comienza a cuestionar todo lo que le han enseñado.',
    'Una protagonista que evoluciona desde la sumisión a la fuerza de forma natural. El giro en la trama a mitad del libro es impactante y cambia completamente la dirección de la historia. El romance es adictivo y el worldbuilding detallado.', -- NUEVA descripción personalizada
    'Jennifer','L.','Armentrout', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía oscura','','','', -- géneros
    'De sangre y cenizas','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-03-10','2024-03-15', -- fechas: agregación, inicio, fin
    'Adictivo desde la primera página. Poppy es una protagonista que evoluciona de manera fascinante.', -- reseña
    10.00, -- puntuación (ajustada a 10.00)
    'La libertad siempre vale el precio, sin importar cuán alto sea.', -- frase destacada
    'Analizar paralelismos con mitología griega' -- Notas
);

CALL add_book_full(
    'Un reino de carne y fuego',793, -- Título, páginas
    'Poppy ha descubierto la verdad sobre su destino y ahora debe navegar por un mundo de mentiras y traiciones mientras su relación con Casteel se profundiza y los peligros aumentan.',
    'Un segundo libro que supera al primero. La evolución de Poppy hacia su verdadero potencial es fascinante y su química con Casteel se profundiza. El worldbuilding se expande de manera natural y los nuevos personajes son carismáticos.', -- NUEVA descripción personalizada
    'Jennifer','L.','Armentrout', -- Autor, apellido1, apellido2
    'Romantasy','Fantasía oscura','','','', -- géneros
    'De sangre y cenizas','joss0102','completed', -- saga, usuario, estado
    '2025-03-30','2024-03-12','2024-03-19', -- fechas: agregación, inicio, fin
    'Segundo libro que supera al primero. Más acción, más romance y revelaciones impactantes.', -- reseña
    8.86, -- puntuación
    'En la oscuridad es donde encontramos nuestra verdadera fuerza.', -- frase destacada
    'Las escenas de batalla son cinematográficas - visualizar bien' -- Notas
);

CALL add_book_full(
    'Una corona de huesos dorados',784,
    'Poppy y Casteel enfrentan nuevas amenazas mientras intentan unificar a su pueblo contra el verdadero enemigo. Los secretos del pasado resurgen y las alianzas se ponen a prueba.',
    'El libro más intenso de la saga hasta ahora. La evolución de Poppy como líder es impresionante y las revelaciones sobre su pasado cambian todo. La relación con Casteel continúa desarrollándose de manera natural y los personajes secundarios brillan.', -- NUEVA descripción personalizada
    'Jennifer','L.','Armentrout',
    'Romantasy','Fantasía oscura','','','',
    'De sangre y cenizas','joss0102','completed',
    '2025-03-30','2024-03-16','2024-03-24',
    'El libro más intenso de la saga hasta ahora. La evolución de Poppy como líder es impresionante.',
    10.00, -- puntuación (ajustada a 10.00)
    'Una reina no nace, se forja en el fuego de la adversidad.',
    'Analizar el discurso de Poppy en el capítulo 32 - poderosa declaración de principios'
);

CALL add_book_full(
    'Una sombra en las brasas',811,
    'Mientras la guerra se intensifica, Poppy debe viajar a tierras desconocidas para encontrar aliados inesperados. Misterios ancestrales salen a la luz, cambiando todo lo que creían saber.',
    'Este libro expande el mundo de manera magistral. La mitología se profundiza y los nuevos personajes añaden dimensiones interesantes. Las revelaciones sobre los dioses y los Atlantianos son fascinantes y cambian completamente la perspectiva de la saga.', -- NUEVA descripción personalizada
    'Jennifer','L.','Armentrout',
    'Romantasy','Fantasía oscura','','','',
    'De sangre y cenizas','joss0102','completed',
    '2025-03-30','2024-03-20','2024-04-02',
    'Expande el mundo de manera magistral. La mitología de este universo sigue sorprendiendo.',
    9.29,
    'La esperanza es como una brasa: parece apagada, pero puede iniciar el incendio más grande.',
    'El nuevo personaje introducido en el capítulo 15 será clave - tomar notas'
);

CALL add_book_full(
    'La guerra de las dos reinas',911,
    'El conflicto entre Poppy y la Reina Isbeth llega a su punto culminante en una batalla épica que decidirá el destino de los reinos. Las pérdidas serán inevitables.',
    'Confrontación épica que justifica toda la construcción previa. Las escenas de batalla están magníficamente escritas y el desarrollo de los poderes de Poppy alcanza nuevas alturas. Los momentos emocionales son devastadores y las pérdidas se sienten reales.', -- NUEVA descripción personalizada
    'Jennifer','L.','Armentrout',
    'Romantasy','Fantasía épica','','','',
    'De sangre y cenizas','joss0102','completed',
    '2025-03-30','2024-03-25','2024-04-06',
    'Confrontación épica que justifica toda la saga. Escenas de batalla magistralmente escritas.',
    9.64,
    'En la guerra no hay vencedores, sólo sobrevivientes.',
    'El capítulo 78 es devastador - prepararse emocionalmente para releer'
);

CALL add_book_full(
    'Una luz en la llama',877,
    'Después de los eventos traumáticos de la guerra, Poppy y Casteel deben reconstruir su relación y su reino, mientras una nueva amenaza surge en el horizonte.',
    'Un libro de reconstrucción emocional que muestra las secuelas psicológicas de la guerra. La vulnerabilidad de los personajes es conmovedora y la forma en que enfrentan sus traumas es realista. Una nueva etapa para la saga que profundiza en aspectos más íntimos.', -- NUEVA descripción personalizada
    'Jennifer','L.','Armentrout',
    'Romantasy','Fantasía oscura','','','',
    'De sangre y cenizas','joss0102','completed',
    '2025-03-30','2024-04-03','2024-04-07',
    'Hermoso libro de reconstrucción emocional. La vulnerabilidad de los personajes es conmovedora.',
    10.00, -- puntuación (ajustada a 10.00)
    'La luz más brillante a menudo nace de la oscuridad más profunda.',
    'Analizar el desarrollo de la relación principal en esta nueva etapa'
);

CALL add_book_full(
    'Un alma de ceniza y sangre',771,
    'Poppy y Casteel enfrentan su desafío más personal mientras luchan por mantener la paz recién ganada. Secretos familiares salen a la luz, cambiando todo lo que creían saber sobre sus orígenes.',
    'Conclusión satisfactoria para esta etapa de la saga. Las revelaciones sobre los orígenes de Poppy y Casteel recontextualizan toda la historia. Los momentos íntimos entre la pareja son emotivos y el camino queda abierto para más aventuras.', -- NUEVA descripción personalizada
    'Jennifer','L.','Armentrout',
    'Romantasy','Fantasía oscura','','','',
    'De sangre y cenizas','joss0102','completed',
    '2025-03-30','2024-04-07','2024-04-10',
    'Conclusión satisfactoria para esta etapa de la saga. Deja el camino abierto para más historias.',
    7.57,
    'El amor no borra el pasado, pero da fuerza para enfrentar el futuro.',
    'La revelación final cambia toda la perspectiva de la saga - releer con esta nueva información'
);

CALL add_book_full(
    'Un fuego en la carne',755,
    'La historia continúa explorando las consecuencias de las revelaciones finales, con los personajes enfrentando nuevos desafíos personales y políticos en un mundo cambiante.',
    'Una nueva entrega que mantiene la calidad de la saga. Los personajes secundarios ganan protagonismo y se desarrollan de manera satisfactoria. Los nuevos poderes que se manifiestan abren posibilidades interesantes para futuras tramas.', -- NUEVA descripción personalizada
    'Jennifer','L.','Armentrout',
    'Romantasy','Fantasía oscura','','','',
    'De sangre y cenizas','joss0102','completed',
    '2025-03-30','2024-04-08','2024-04-15',
    'Nueva entrega que mantiene la calidad de la saga, con giros inesperados y desarrollo de personajes secundarios.',
    9.21,
    'El fuego que nos consume es el mismo que nos fortalece.',
    'Prestar atención a los nuevos poderes que se manifiestan - importante para próximos libros'
);

CALL add_book_full(
    'El imperio final',841,
    'En un mundo donde el sol rojo brilla sin descanso y las cenizas caen como nieve, un joven ladrón descubre que posee poderes únicos que podrían cambiar el destino de su opresivo mundo.',
    'El sistema de magia de la alomancia es uno de los más innovadores y bien construidos que he leído. Sanderson crea un mundo distópico fascinante con reglas coherentes. El ritmo es algo lento al principio pero la recompensa vale la pena.', -- NUEVA descripción personalizada
    'Brandon','Sanderson','',
    'Fantasía épica','Fantasía de magia dura','','','',
    'Nacidos de la bruma','joss0102','completed',
    '2025-03-30','2024-04-10','2024-04-23',
    'Sistema de magia innovador y construcción de mundo excepcional, aunque el ritmo es lento al principio.',
    6.36,
    'La supervivencia no es suficiente. Para vivir, debemos encontrar algo por lo que valga la pena morir.',
    'Hacer diagramas del sistema de alomancia para entenderlo mejor'
);

CALL add_book_full(
    'El pozo de la ascensión',766,
    'Después de derrocar al Lord Legislador, Vin y Elend deben gobernar un imperio fracturado mientras nuevas amenazas emergen de las sombras.',
    'Un segundo libro que profundiza en los dilemas políticos y morales. La evolución de Vin y Elend como líderes es fascinante, y los nuevos aspectos del sistema de magia que se revelan expanden el mundo de manera lógica. Los giros finales son impactantes.', -- NUEVA descripción personalizada
    'Brandon','Sanderson','',
    'Fantasía épica','Fantasía política','','','',
    'Nacidos de la bruma','joss0102','dropped',
    '2025-03-30','2024-04-17','2024-04-25',
    'Segundo libro que profundiza en los dilemas políticos y personajes. Plot twists magistrales.',
    5.57,
    'Un líder debe ver lo que es, no lo que desea que sea.',
    'Analizar las diferencias entre los sistemas de magia de este mundo'
);

CALL add_book_full(
    'El príncipe cruel',460,
    'Jude, una mortal criada en la Corte Feérica, debe aprender a sobrevivir en un mundo de engaños y peligros, donde su mayor enemigo podría ser el irresistible príncipe Cardan.',
    'Una protagonista fascinante que utiliza su ingenio para sobrevivir en un mundo donde está en desventaja. La Corte Feérica es oscura y peligrosa, y las intrigas políticas están bien desarrolladas. La relación con Cardan es complicada y adictiva.', -- NUEVA descripción personalizada
    'Holly','Black','',
    'Fantasía oscura','Romance','','','',
    'Habitantes del aire','joss0102','completed',
    '2025-03-30','2024-04-24','2024-04-29',
    'Protagonista femenina inteligente y estratégica. Mundo feérico oscuro y fascinante.',
    8.86,
    'Si no puedo ser mejor que ellos, seré mucho peor.',
    'Tomar notas de las estrategias políticas de Jude'
);

CALL add_book_full(
    'El rey malvado',376,
    'Jude se encuentra atrapada en un juego peligroso de poder y traición, donde debe decidir entre su ambición y su corazón, mientras el reino se balancea al borde de la guerra.',
    'Conclusión perfecta para la historia de Jude y Cardan. Los giros políticos son inesperados y la evolución de ambos personajes principales es notable. La forma en que se resuelven los conflictos es satisfactoria sin ser predecible.', -- NUEVA descripción personalizada
    'Holly','Black','',
    'Fantasía oscura','Romance','','','',
    'Habitantes del aire','joss0102','completed',
    '2025-03-30','2024-04-28','2024-08-21',
    'Conclusión satisfactoria con giros inesperados. La evolución de Cardan es particularmente notable.',
    7.93,
    'El poder es mucho más fácil de adquirir que de mantener.',
    'Analizar el arco de redención del personaje principal'
);

CALL add_book_full(
    'Destino Prohibido',340,
    'Una historia de amor prohibido entre dos almas destinadas a estar juntas pero separadas por las circunstancias. La química entre los protagonistas es palpable desde el primer encuentro.',
    'Una historia de amor con suficiente conflicto para mantener el interés. El mundo fantástico está bien construido y los personajes secundarios añaden profundidad. La química entre los protagonistas es creíble desde el primer momento.', -- NUEVA descripción personalizada
    'Alba','Zamora','',
    'Romance','Fantasía','','','',
    'Crónicas de Hiraia','joss0102','completed',
    '2025-03-30','2024-08-19','2024-08-22',
    'Encantadora historia de amor con suficiente conflicto para mantener el interés. Los personajes secundarios añaden profundidad al mundo.',
    8.57,
    'El corazón no entiende de prohibiciones cuando encuentra su verdadero destino.',
    'Analizar la construcción del mundo fantástico - prometedor para la saga'
);

CALL add_book_full(
    'Promesas cautivas',325,
    'Las consecuencias del amor prohibido se hacen presentes mientras los protagonistas luchan por mantener sus promesas en un mundo que se opone a su unión.',
    'Segunda parte que mantiene la magia del primero. La tensión emocional está bien lograda y los obstáculos que enfrentan los protagonistas son creíbles. La evolución de su relación es natural y emotiva.', -- NUEVA descripción personalizada
    'Alba','Zamora','',
    'Romance','Fantasía','','','',
    'Crónicas de Hiraia','joss0102','completed',
    '2025-03-30','2024-08-22','2024-08-29',
    'Segunda parte que mantiene la magia del primero. La tensión emocional está bien lograda.',
    8.71,
    'Una promesa hecha con el corazón es más fuerte que cualquier cadena.',
    'Comparar evolución de los personajes con el primer libro'
);

CALL add_book_full(
    'Nunca te dejaré',585,
    'Una historia oscura de obsesión y amor peligroso que explora los límites de la posesión y el consentimiento en una relación tóxica pero fascinante.',
    'Intenso y perturbador, pero imposible de soltar. Explora temas oscuros de obsesión y los límites borrosos del consentimiento. La química entre los personajes es electrizante y la narrativa te mantiene en tensión constante.', -- NUEVA descripción personalizada
    'H.','D.','Carlton',
    'Romance oscuro','Suspense','','','',
    'Hunting Adeline','joss0102','completed',
    '2025-03-30','2024-08-23','2024-09-04',
    'Intenso y perturbador, pero imposible de soltar. La química entre los personajes es electrizante.',
    9.21,
    'Perteneces a mí, incluso cuando luchas contra ello.',
    'Contenido sensible: revisar advertencias antes de releer'
);

CALL add_book_full(
    'Te encontraré',662,
    'La persecución continúa en esta segunda parte, donde los roles se invierten y la cazadora se convierte en la presa, en un juego psicológico de atracción y peligro.',
    'Una continuación que mantiene la intensidad del primero. Los roles invertidos añaden una dimensión interesante a la dinámica entre los protagonistas. Los giros argumentales son impredecibles y el ritmo no decae en ningún momento.', -- NUEVA descripción personalizada
    'H.','D.','Carlton',
    'Romance oscuro','Thriller','','','',
    'Hunting Adeline','joss0102','completed',
    '2025-03-30','2024-09-01','2024-09-06',
    'Conclusión satisfactoria que mantiene la tensión hasta el final. Los giros argumentales son impredecibles.',
    8.36,
    'Incluso en la oscuridad más profunda, encontraré el camino hacia ti.',
    'Analizar la evolución psicológica de los personajes'
);

CALL add_book_full(
    'Destrózame',348,
    'En un mundo distópico, Juliette posee un toque mortal y ha sido recluida toda su vida, hasta que un día es liberada por un misterioso soldado que parece inmune a su poder.',
    'El estilo de escritura poético y experimental hace que esta historia destaque. Juliette es una protagonista compleja con un poder fascinante. La construcción del mundo distópico es inquietante y la evolución de la protagonista es notable.', -- NUEVA descripción personalizada
    'Tahereh','Mafi','',
    'Distopía','Romance','','','',
    'Shatter Me','joss0102','completed',
    '2025-03-30','2024-09-05','2024-09-07',
    'Estilo de escritura único y poético. La voz narrativa de Juliette es fresca y conmovedora.',
    8.93,
    'Mi toque es letal, pero mi corazón solo quiere amar.',
    'Prestar atención al uso de metáforas y tachones en el texto'
);

CALL add_book_full(
    'Uneme (Destrúyeme 1.5)',114,
    'Una historia corta desde la perspectiva de Warner que revela sus pensamientos y sentimientos durante los eventos del primer libro, dando profundidad a este complejo personaje.',
    'Una perspectiva fascinante que humaniza al aparente villano. Ver los eventos a través de los ojos de Warner añade capas a la historia principal y recontextualiza muchas de sus acciones. Imprescindible para entender completamente al personaje.', -- NUEVA descripción personalizada
    'Tahereh','Mafi','',
    'Distopía','Romance','','','',
    'Shatter Me','joss0102','completed',
    '2025-03-30','2024-09-07','2024-09-09',
    'Fascinante ver la perspectiva de Warner. Humaniza al "villano" y añade capas a la historia.',
    8.00,
    'No sabía que podía amarla hasta que supe que no debía.',
    'Releer después del primer libro para mejor contexto'
);

CALL add_book_full(
    'Reckless',432,
    'Paedyn Gray enfrenta nuevas amenazas mientras navega por las consecuencias de los Juegos Purging. Los secretos salen a la luz y las lealtades son puestas a prueba.',
    'Secuela que supera al original. La evolución de Paedyn es excelente y los nuevos giros en la trama mantienen el interés. La acción está bien equilibrada con el desarrollo de personajes y las revelaciones sobre el sistema de poderes son fascinantes.', -- NUEVA descripción personalizada
    'Lauren','Roberts','',
    'Romance','Fantasía distópica','','','',
    'Powerless','joss0102','completed',
    '2025-03-30','2024-09-08','2024-09-11',
    'Secuela que supera al original. Más acción, más giros y desarrollo de personajes excelente.',
    8.57,
    'Ser temerario no es falta de miedo, sino valor para actuar a pesar de él.',
    'Comparar evolución de Paedyn con el primer libro'
);

CALL add_book_full(
    'Liberame',471,
    'Juliette ha tomado el control de su poder y de su vida, pero el mundo fuera de los muros de la Sector 45 es más peligroso de lo que imaginaba.',
    'La evolución de Juliette desde una chica asustada a una mujer que toma el control de su vida es impresionante. La acción y el romance están perfectamente equilibrados, y las nuevas amenazas mantienen la tensión narrativa. El estilo poético sigue siendo cautivador.', -- NUEVA descripción personalizada
    'Tahereh','Mafi','',
    'Distopía','Ciencia ficción','','','',
    'Shatter Me','joss0102','completed',
    '2025-03-30','2024-09-10','2024-09-12',
    'La evolución de Juliette es impresionante. La acción y el romance están perfectamente equilibrados.',
    10.00, -- puntuación (ajustada a 10.00)
    'No soy un arma. No soy un monstruo. Soy libre.',
    'El discurso de Juliette en el capítulo 25 es inspirador'
);

CALL add_book_full(
    'Uneme (Fracturame 2.5)',74,
    'Breve historia que explora momentos clave entre Warner y Juliette, dando mayor profundidad a su compleja relación durante los eventos del segundo libro.',
    'Pequeña joya para los fans de la pareja. Las escenas íntimas y emotivas están bien logradas y añaden contexto importante a la evolución de su relación. La perspectiva de Warner siempre es fascinante y compleja.', -- NUEVA descripción personalizada
    'Tahereh','Mafi','',
    'Distopía','Romance','','','',
    'Shatter Me','joss0102','completed',
    '2025-03-30','2024-09-12','2024-09-15',
    'Pequeña joya para fans de la pareja. Escenas íntimas y emotivas bien logradas.',
    7.50,
    'En sus ojos encontré el reflejo de la persona que quería ser.',
    'Leer justo después de LiberaME para continuidad'
);

CALL add_book_full(
    'Enciendeme',439,
    'Juliette debe unir fuerzas con aliados inesperados para enfrentar la creciente amenaza del Restablecimiento, mientras descubre la verdadera extensión de sus poderes.',
    'Tercera parte llena de acción y revelaciones. El desarrollo del mundo y del sistema de poderes es excelente. Las alianzas inesperadas añaden dinamismo a la trama y la evolución de Juliette alcanza nuevas dimensiones fascinantes.', -- NUEVA descripción personalizada
    'Tahereh','Mafi','',
    'Distopía','Ciencia ficción','','','',
    'Shatter Me','joss0102','completed',
    '2025-03-30','2024-09-12','2024-09-19',
    'Tercera parte llena de acción y revelaciones. El desarrollo del mundo es excelente.',
    8.93,
    'No somos lo que nos hicieron, somos lo que elegimos ser.',
    'Prestar atención a los nuevos poderes que aparecen'
);

CALL add_book_full(
    'Caraval',416,
    'Scarlett Dragna siempre ha soñado con asistir a Caraval, el espectáculo itinerante donde la audiencia participa en el show. Cuando finalmente recibe una invitación, su hermana Tella es secuestrada por el maestro del espectáculo, y Scarlett debe encontrar a su hermana antes de que termine el juego.',
    'Un mundo mágico y atmosférico con giros inesperados. La ambientación de Caraval es fascinante y te sumerge completamente en este espectáculo mágico. Las reglas del juego mantienen la tensión y nunca sabes qué es real y qué es parte del espectáculo.', -- NUEVA descripción personalizada
    'Stephanie','Garber','',
    'Fantasía','Romance','','','',
    'Caraval','joss0102','completed',
    '2025-03-30','2024-09-17','2024-09-27',
    'Mundo mágico y atmosférico con giros inesperados. La ambientación de Caraval es fascinante.',
    9.43,
    'Recuerda, todo en Caraval es un juego. No creas todo lo que ves.',
    'Prestar atención a las pistas ocultas a lo largo de la historia'
);

CALL add_book_full(
    'El imperio del vampiro',1059,
    'En un mundo donde el sol ha muerto y los vampiros gobiernan, Gabriel de León, el último miembro de una orden de cazadores de vampiros, es capturado y obligado a contar su historia a la reina vampira.',
    'Narrativa cruda y poderosa que combina perfectamente fantasía oscura con elementos de horror. La construcción del mundo post-apocalíptico dominado por vampiros es inquietante y fascinante. Los personajes son complejos y la narrativa no rehúye los aspectos más oscuros.', -- NUEVA descripción personalizada
    'Jay','Kristoff','',
    'Fantasía oscura','Horror','','','',
    'El imperio del vampiro','joss0102','completed',
    '2025-03-30','2024-09-20','2024-09-28',
    'Narrativa cruda y poderosa. Combina perfectamente fantasía oscura con elementos de horror.',
    10.00, -- puntuación (ajustada a 10.00)
    'La esperanza es el primer paso en el camino a la decepción.',
    'Contenido gráfico: revisar advertencias antes de releer'
);

CALL add_book_full(
    'El príncipe cautivo',254,
    'Un príncipe es capturado por una reina guerrera y debe aprender a navegar por la corte de su captora mientras planea su escape, pero lo que comienza como odio podría convertirse en algo más.',
    'Química electrizante entre los protagonistas. La dinámica de enemigos a amantes está bien ejecutada y la tensión política añade capas a la historia. El worldbuilding es sólido y los personajes tienen profundidad psicológica.', -- NUEVA descripción personalizada
    'C.','S.','Pacat',
    'Romance','Fantasía','','','',
    'El príncipe cautivo','joss0102','completed',
    '2025-03-30','2024-09-28','2024-09-29',
    'Química electrizante entre los protagonistas. Dinámica de enemigos a amantes bien ejecutada.',
    7.93,
    'El cautiverio no es solo de cuerpos, sino también de corazones.',
    'Analizar la evolución de la relación principal'
);

CALL add_book_full(
    'El juego del príncipe',344,
    'El príncipe continúa su juego peligroso en la corte, donde las líneas entre aliados y enemigos se difuminan y cada movimiento podría ser su último.',
    'Intriga política bien desarrollada. La tensión sexual entre los protagonistas aumenta de manera satisfactoria mientras navegan por las traiciones y alianzas de la corte. Las estrategias políticas son fascinantes y la evolución de la relación principal es creíble.', -- NUEVA descripción personalizada
    'C.','S.','Pacat',
    'Romance','Fantasía','','','',
    'El príncipe cautivo','joss0102','completed',
    '2025-03-30','2024-09-28','2024-09-30',
    'Intriga política bien desarrollada. La tensión sexual aumenta de manera satisfactoria.',
    7.86,
    'En el juego del poder, cada gesto es un movimiento calculado.',
    'Tomar notas de las estrategias políticas empleadas'
);

CALL add_book_full(
    'La rebelión del rey',305,
    'La conclusión de la trilogía donde las lealtades son puestas a prueba y el príncipe debe decidir entre su deber y su corazón en una batalla final por el poder.',
    'Final satisfactorio con giros inesperados. La evolución de los personajes llega a su culminación natural y la resolución de los conflictos políticos y personales está bien equilibrada. El epílogo cierra perfectamente la historia.', -- NUEVA descripción personalizada
    'C.','S.','Pacat',
    'Romance','Fantasía','','','',
    'El príncipe cautivo','joss0102','completed',
    '2025-03-30','2024-09-30','2024-10-02',
    'Final satisfactorio con giros inesperados. La evolución de los personajes es notable.',
    10.00, -- puntuación (ajustada a 10.00)
    'A veces, rebelarse es la única forma de ser fiel a uno mismo.',
    'El epílogo es perfecto - leer con atención'
);

CALL add_book_full(
    'Todos los ángeles del infierno',412,
    'Una historia oscura de ángeles caídos y demonios donde los límites entre el bien y el mal se difuminan, y el amor puede ser la mayor condena o la salvación.',
    'Mundo rico y personajes complejos. La mitología angelical está bien desarrollada y la forma en que explora las líneas difusas entre lo correcto y lo incorrecto es fascinante. La simbología religiosa está integrada de manera inteligente en la trama.', -- NUEVA descripción personalizada
    'Miriam','Mosquera','',
    'Fantasía oscura','Romance','','','',
    'La caída del cielo','joss0102','completed',
    '2025-03-30','2024-09-30','2024-10-03',
    'Mundo rico y personajes complejos. La mitología angelical está bien desarrollada.',
    9.43,
    'Incluso los ángeles más puros esconden un infierno interior.',
    'Analizar la simbología religiosa en la historia'
);

CALL add_book_full(
    'Hooked',348,
    'Una reinterpretación oscura de Peter Pan donde James Garber es un empresario despiadado y Wendy Darling una ladrona que roba su reloj, iniciando un juego peligroso de atracción y venganza.',
    'Versión adulta y retorcida del clásico cuento. La química entre los protagonistas es eléctrica y los guiños al material original son inteligentes. Un thriller romántico oscuro con giros inesperados que mantienen el interés.', -- NUEVA descripción personalizada
    'Emily','McIntire','',
    'Romance oscuro','Reimaginación','','','',
    'Historia de Nunca Jamás','joss0102','completed',
    '2025-03-30','2024-10-04','2024-10-09',
    'Mejor que el primero. La profundidad psicológica del Capitán Garfio es fascinante.',
    10.00, -- puntuación (ajustada a 10.00)
    'Las cicatrices más profundas no son las que se ven, sino las que llevamos dentro.',
    'El monólogo interno del Capitán es brillante - analizar'
);

CALL add_book_full(
    'La serpiente y las alas de la noche',495,
    'En un mundo de vampiros y dioses oscuros, una humana se ve atrapada en un torneo mortal donde su mayor enemigo podría ser su única salvación.',
    'Sistema de magia único y personajes complejos. La tensión romántica está bien construida y el sistema de vampirismo es original. El torneo mantiene la tensión narrativa y los giros políticos añaden complejidad.', -- NUEVA descripción personalizada
    'Carissa','Broadbent','',
    'Fantasía oscura','Romance','','','',
    'Crowns of Nyaxia','joss0102','completed',
    '2025-03-30','2024-10-06','2024-10-11',
    'Sistema de magia único y personajes complejos. La tensión romántica está bien construida.',
    9.14,
    'No rezo a los dioses. Soy lo que los dioses temen.',
    'El sistema de vampirismo es original - tomar notas'
);

CALL add_book_full(
    'God of Malice',560,
    'Killian es el dios de la malicia en una universidad donde los hijos de las familias mafiosas juegan a ser dioses. Glyndon es la única que parece inmune a su encanto, convirtiéndose en su obsesión.',
    'Química tóxica pero adictiva entre los protagonistas. La dinámica de poder es intrigante y el ambiente universitario con elementos de mafia resulta original. La evolución de la relación desde el antagonismo es fascinante.', -- NUEVA descripción personalizada
    'Rina','Kent','',
    'Romance oscuro','Bully romance','','','',
    'Legado de dioses','joss0102','completed',
    '2025-03-30','2024-10-17','2024-10-21',
    'Química tóxica pero adictiva entre los protagonistas. La dinámica de poder es intrigante.',
    7.43,
    'No soy un salvador. Soy el villano de tu historia.',
    'Contenido sensible: revisar advertencias'
);

CALL add_book_full(
    'El libro de Azrael',735,
    'En un mundo donde dioses y monstruos libran una guerra eterna, una asesina mortal se alía con el enemigo más peligroso para evitar el fin del mundo.',
    'Mundo complejo y personajes fascinantes. La química entre los protagonistas es electrizante y la mitología creada es sorprendentemente original. La evolución de la relación desde enemigos mortales a aliados y más allá es creíble.', -- NUEVA descripción personalizada
    'Amber','V.','Nicole',
    'Fantasía oscura','Romance','','','',
    'Dioses y monstruos','joss0102','completed',
    '2025-03-30','2024-10-17','2024-10-20',
    'Mundo complejo y personajes fascinantes. La química entre los protagonistas es electrizante.',
    10.00, -- puntuación (ajustada a 10.00)
    'Los monstruos más peligrosos no son los que muestran sus garras, sino los que esconden sonrisas.',
    'Analizar la mitología creada - muy original'
);

CALL add_book_full(
    'Trono de monstruos',444,
    'Segunda parte de la saga donde las alianzas se prueban y los secretos salen a la luz, mientras el mundo se balancea al borde de la destrucción total.',
    'Secuela que supera al original. Más acción, más giros y mayor desarrollo de personajes. La evolución de los protagonistas es consistente y las nuevas amenazas elevan la tensión. La mitología se expande de forma coherente.', -- NUEVA descripción personalizada
    'Amber','V.','Nicole',
    'Fantasía oscura','Romance','','','',
    'Dioses y monstruos','joss0102','completed',
    '2025-03-30','2024-10-20','2024-10-22',
    'Secuela que supera al original. Más acción, más giros y mayor desarrollo de personajes.',
    10.00, -- puntuación (ajustada a 10.00)
    'Para gobernar un trono de monstruos, primero debes convertirte en uno.',
    'Comparar evolución de los personajes principales'
);

CALL add_book_full(
    'Reconstruyeme',347,
    'Juliette Ferrars ha regresado con un nuevo propósito y un ejército de aliados inesperados, lista para enfrentarse al Restablecimiento de una vez por todas.',
    'Evolución notable de la protagonista. La narrativa poética sigue siendo impactante y el desarrollo de los personajes secundarios añade profundidad a la historia. La trama política se vuelve más compleja y fascinante.', -- NUEVA descripción personalizada
    'Tahereh','Mafi','',
    'Distopía','Ciencia ficción','','','',
    'Shatter Me','joss0102','completed',
    '2025-03-30','2024-10-22','2024-10-23',
    'Evolución notable de la protagonista. La narrativa poética sigue siendo impactante.',
    8.86,
    'No estoy rota, solo reconstruida de manera diferente.',
    'Prestar atención al desarrollo de los personajes secundarios'
);

CALL add_book_full(
    'Desafíame',283,
    'La batalla final se acerca y Juliette debe tomar decisiones imposibles que determinarán el futuro de su mundo y de todos los que ama.',
    'Conclusión emocionante de la saga principal. Satisfactoria evolución de todos los personajes y resolución de los conflictos principales. El epílogo cierra perfectamente los arcos narrativos iniciados en el primer libro.', -- NUEVA descripción personalizada
    'Tahereh','Mafi','',
    'Distopía','Ciencia ficción','','','',
    'Shatter Me','joss0102','completed',
    '2025-03-30','2024-10-23','2024-10-24',
    'Conclusión emocionante de la saga principal. Satisfactoria evolución de todos los personajes.',
    10.00, -- puntuación (ajustada a 10.00)
    'Desafiarte a ti mismo es el acto más valiente de todos.',
    'El epílogo es perfecto - leer con atención'
);

CALL add_book_full(
    'Encuentrame (Ocultame 4.5)',76,
    'Una historia corta que sigue a Warner mientras busca a Juliette después de los eventos de "OcultaME", revelando sus pensamientos más íntimos y su determinación inquebrantable.',
    'Perspectiva conmovedora de Warner. Añade profundidad a su personaje y a su relación con Juliette. Ver su vulnerabilidad y determinación desde su punto de vista enriquece enormemente la historia principal.', -- NUEVA descripción personalizada
    'Tahereh','Mafi','',
    'Distopía','Romance','','','',
    'Shatter Me','joss0102','completed',
    '2025-03-30','2024-10-24','2024-10-24',
    'Perspectiva conmovedora de Warner. Añade profundidad a su personaje y a su relación con Juliette.',
    7.86,
    'Cruzaría mil mundos destruidos solo para encontrarte en uno.',
    'Leer después de OcultaME para mejor contexto'
);

CALL add_book_full(
    'Encuentrame (Muestrame 5.5)',80,
    'Una historia corta desde la perspectiva de Warner que revela sus pensamientos más íntimos mientras busca a Juliette después de los eventos de "MuestraME".',
    'Conmovedora mirada al interior de Warner. Añade profundidad emocional a su personaje y muestra su evolución a lo largo de la saga. Su dedicación y amor por Juliette son palpables en cada página.', -- NUEVA descripción personalizada
    'Tahereh','Mafi','',
    'Distopía','Romance','','','',
    'Shatter Me','joss0102','completed',
    '2025-03-30','2024-10-24','2024-10-24',
    'Conmovedora mirada al interior de Warner. Añade profundidad emocional a su personaje.',
    8.14,
    'Encontrarte no fue un destino, fue mi elección constante.',
    'Leer después de MuestraME para mejor contexto'
);

CALL add_book_full(
    'Una perdición de ruina y furia',558,
    'Raine se ve atrapada en un juego peligroso con el Príncipe de la Perdición, donde la línea entre el odio y la atracción se difumina cada vez más.',
    'Química explosiva entre los protagonistas. Mundo construido de manera fascinante con una mitología original. La dinámica entre los personajes principales evoluciona de forma creíble y la tensión romántica es adictiva.', -- NUEVA descripción personalizada
    'Jennifer','L.','Armentrout',
    'Fantasía oscura','Romance','','','',
    'Una perdición de ruina y furia','joss0102','completed',
    '2025-03-30','2024-10-29','2024-11-01',
    'Química explosiva entre los protagonistas. Mundo construido de manera fascinante.',
    9.21,
    'La ruina no es el fin, sino el principio de algo más poderoso.',
    'Analizar la mitología del mundo creado'
);

CALL add_book_full(
    'Mi alma es tuya',416,
    'En un pacto demoníaco, un alma humana es ofrecida como sacrificio, pero lo que comienza como un contrato se convierte en una conexión inesperada.',
    'Historia intensa con personajes complejos. La dinámica de poder está bien lograda y la evolución desde un contrato frío a una conexión emocional es creíble. Los elementos sobrenaturales están bien integrados en la trama.', -- NUEVA descripción personalizada
    'Harley','Laroux','',
    'Romance oscuro','Fantasía','','','',
    'Alma','joss0102','completed',
    '2025-03-30','2024-11-01','2024-11-06',
    'Historia intensa con personajes complejos. La dinámica de poder está bien lograda.',
    7.93,
    'No me ofreciste tu alma, me entregaste tu corazón sin saberlo.',
    'Contenido sensible: revisar advertencias'
);


CALL add_book_full(
    'Scarred',401,
    'Segunda parte de la saga oscura de Nunca Jamás, centrada en el Capitán Garfio y su obsesión por una mujer que podría ser su perdición o su redención.',
    'Mejor que el primero. La profundidad psicológica del Capitán Garfio es fascinante y su monólogo interno revela capas de complejidad inesperadas. La reinterpretación del personaje clásico es original y convincente.', -- NUEVA descripción personalizada
    'Emily','McIntire','',
    'Romance oscuro','Reimaginación','','','',
    'Historia de Nunca Jamás',
    'joss0102','completed',
    '2025-03-30','2024-10-03','2024-10-05',
    'Versión adulta y retorcida del clásico cuento. La química entre los protagonistas es eléctrica.',
    8.71,
    'Todos crecen, excepto aquellos que eligen perderse en el juego.',
    'Comparar con el Peter Pan original - diferencias interesantes'
);
-- First batch of book inserts with custom descriptions

-- Alas de sangre
CALL add_book_full(
    'Alas de sangre', 730, 
    'En un mundo al borde de la guerra, Violet Sorrengail, una joven que debería haber ingresado en el Cuerpo de Escribas, es obligada a unirse a los jinetes de dragones, una élite de guerreros que montan dragones. Violet debe sobrevivir al brutal entrenamiento y a las traiciones mientras descubre secretos que podrían cambiar el curso de la guerra.',
    'Una fascinante exploración de la resiliencia y la transformación personal, donde Violet debe desafiar sus propios límites y expectativas para sobrevivir en un mundo brutalmente competitivo de jinetes de dragones. La novela combina elementos de fantasía épica con un intenso desarrollo de personajes.',
    'Rebecca', 'Yarros', '', 
    'Romantasy', 'Fantasía épica', '', '', '', 
    'Empíreo', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-03-22', '2024-04-03', 
    'Una historia emocionante con personajes complejos y una trama llena de giros inesperados. La evolución de Violet es fascinante.', 
    8.00, 
    'A veces, la fuerza no viene de los músculos, sino de la voluntad de seguir adelante cuando todo parece perdido.', 
    'Releer capítulo 12 - la escena del primer vuelo es impresionante'
);

-- Trono de cristal
CALL add_book_full(
    'Trono de cristal', 489, 
    'En las tenebrosas minas de sal de Endovier, una muchacha de dieciocho años cumple cadena perpetua. Es una asesina profesional, la mejor en lo suyo, pero ha cometido un error fatal. La han capturado. El joven capitán Westfall le ofrece un trato: la libertad a cambio de un enorme sacrificio.',
    'Una obra maestra de la fantasía que desafía los arquetipos tradicionales, presentando a una protagonista compleja y moralmente ambigua. La novela explora temas de libertad, redención y el peso de la identidad en un mundo de intrigas políticas y magia ancestral.',
    'Sarah', 'J.', 'Maas', 
    'Romantasy', 'Fantasía heroica', '', '', '', 
    'Trono de cristal', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-03-22', '2024-04-03', 
    'Un inicio prometedor para la saga, con una protagonista fuerte y un mundo lleno de intrigas.', 
    7.00, 
    'La mayor debilidad de una persona no es la que todo el mundo ve, sino la que ella misma oculta incluso a sí misma.', 
    'Celaena es increíblemente sarcástica - tomar notas de sus diálogos'
);

-- Corona de medianoche
CALL add_book_full(
    'Corona de medianoche', 500, 
    'Celaena Sardothien, la asesina más temida de Adarlan, ha sobrevivido a las pruebas del Rey de los Asesinos, pero a un alto costo. Ahora, debe decidir cuánto está dispuesta a sacrificar por su gente y por aquellos a quienes ama.',
    'Un viaje profundo de desarrollo personal y conflicto moral, donde la protagonista se enfrenta a las consecuencias de sus acciones pasadas y los dilemas éticos de su profesión. La novela profundiza en la complejidad de la lealtad, el sacrificio y la búsqueda de un propósito más allá de la muerte.',
    'Sarah', 'J.', 'Maas', 
    'Romantasy', 'Fantasía heroica', '', '', '', 
    'Trono de cristal', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-06-03', '2024-06-10', 
    'La evolución de Celaena como personaje es magistral, con giros argumentales que mantienen en vilo.', 
    7.00, 
    'Incluso en la oscuridad, puede nacer la luz más brillante.', 
    'Analizar el desarrollo del personaje de Chaol en esta entrega'
);

-- Heredera de fuego
CALL add_book_full(
    'Heredera de fuego', 664, 
    'Celaena ha sobrevivido a pruebas mortales, pero ahora se enfrenta a su destino. Mientras el reino se desmorona, deberá elegir entre su legado y su corazón, entre la venganza y la redención.',
    'Un punto de inflexión extraordinario en la saga que explora la transformación personal más profunda. La novela desafía las nociones de destino y elección, presentando a una protagonista que debe reconciliar sus múltiples identidades y encontrar su verdadero propósito en medio del caos y la destrucción.',
    'Sarah', 'J.', 'Maas', 
    'Romantasy', 'Fantasía heroica', '', '', '', 
    'Trono de cristal', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-06-08', '2024-06-13', 
    'El punto de inflexión de la saga donde todo cobra mayor profundidad y complejidad.', 
    9.00, 
    'El fuego que te quema es el mismo que te hace brillar.', 
    'El capítulo 42 contiene una de las mejores escenas de acción de la saga'
);

-- Reina de sombras
CALL add_book_full(
    'Reina de sombras', 730, 
    'Celaena Sardothien ha aceptado su identidad como Aelin Galathynius, reina de Terrasen. Pero antes de reclamar su trono, debe liberar a su pueblo de la tiranía del rey de Adarlan.',
    'Una narración épica de empoderamiento y liderazgo, donde la protagonista transforma su identidad de asesina a reina, enfrentando no solo desafíos externos, sino también internos. La novela examina el peso de la responsabilidad, el poder de la autodeterminación y el significado de liderar con compasión y estrategia.',
    'Sarah', 'J.', 'Maas', 
    'Romantasy', 'Fantasía heroica', '', '', '', 
    'Trono de cristal', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-06-10', '2024-06-16', 
    'Intenso, emocionante y lleno de momentos épicos. La transformación de Aelin es impresionante.', 
    10.00, 
    'No eres dueña de tu destino, pero sí de cómo lo enfrentas.', 
    'Subrayar todos los diálogos entre Aelin y Rowan - química perfecta'
);

-- Una corte de rosas y espinas
CALL add_book_full(
    'Una corte de rosas y espinas', 456, 
    'Feyre, una cazadora, mata a un lobo en el bosque y una bestia monstruosa exige una compensación. Arrastrada a un reino mágico, descubre que su captor no es una bestia, sino Tamlin, un Alto Señor del mundo de las hadas. Mientras Feyre habita en su corte, una antigua y siniestra sombra crece sobre el reino, y deberá luchar para salvar a Tamlin y su pueblo.',
    'Una reinterpretación moderna y oscura del clásico cuento de La Bella y la Bestia, que profundiza en los temas de transformación personal, sacrificio y el poder del amor para trascender las apariencias. La novela explora la evolución de Feyre desde una cazadora de supervivencia hasta una heroína compleja, desafiando las expectativas de género y poder.',
    'Sarah', 'J.', 'Maas', 
    'Romantasy', 'Fantasía oscura', '', '', '', 
    'Una corte de rosas y espinas', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-06-14', '2024-06-19', 
    'Hermosa adaptación de La Bella y la Bestia con un giro oscuro y sensual. La evolución de Feyre es fascinante.', 
    7.00, 
    'No dejes que el miedo a perder te impida jugar el juego.', 
    'Releer la escena del baile bajo la máscara - simbolismo impresionante'
);

-- Una corte de niebla y furia
CALL add_book_full(
    'Una corte de niebla y furia', 592, 
    'Feyre ha superado la prueba de Amarantha, pero a un alto costo. Ahora debe aprender a vivir con sus decisiones y descubrir su lugar en el mundo de las hadas mientras una guerra se avecina.',
    'Una exploración magistral de la recuperación, el empoderamiento y la superación del trauma. La novela desafía las estructuras de poder existentes, presentando una protagonista que se reconstruye a sí misma y encuentra su verdadera fuerza en la vulnerabilidad y la resistencia.',
    'Sarah', 'J.', 'Maas', 
    'Romantasy', 'Fantasía oscura', '', '', '', 
    'Una corte de rosas y espinas', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-06-16', '2024-06-23', 
    'Mejor que el primero en todos los aspectos. Rhysand se convierte en uno de los mejores personajes de la saga.', 
    10.00, 
    'A las estrellas que escuchan, y a los sueños que están ansiosos por ser respondidos.', 
    'Analizar el desarrollo del personaje de Rhysand - arco magistral'
);
-- Continuation of book inserts with custom descriptions

-- Una corte de alas y ruina
CALL add_book_full(
    'Una corte de alas y ruina', 800, 
    'La guerra se acerca y Feyre debe unir a los Alta Corte y al mortal mundo para enfrentarse al Rey Hybern. Mientras tanto, descubre secretos sobre su propia familia y poder.',
    'Una épica exploración de la unidad, el liderazgo y el sacrificio colectivo. La novela profundiza en la complejidad de las alianzas políticas, los costos de la guerra y la transformación de una heroína de víctima a estratega, presentando un análisis matizado de poder, resistencia y esperanza.',
    'Sarah', 'J.', 'Maas', 
    'Romantasy', 'Fantasía épica', '', '', '', 
    'Una corte de rosas y espinas', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-06-20', '2024-06-23', 
    'Conclusión emocionante de la trilogía original, con batallas épicas y momentos emocionales intensos.', 
    9.00, 
    'Sólo puedes ser valiente cuando has tenido miedo.', 
    'El discurso de Feyre en el capítulo 67 es inspirador - memorizar'
);

-- Una corte de hielo y estrellas
CALL add_book_full(
    'Una corte de hielo y estrellas', 240, 
    'Una historia navideña ambientada en el mundo de ACOTAR, donde Feyre y Rhysand organizan una celebración invernal en la Corte de la Noche.',
    'Un breve pero emotivo interludio que profundiza en la intimidad y el desarrollo de los personajes más allá de las grandes batallas. La novela ofrece una mirada íntima a la construcción de la familia, la comunidad y la paz después de la guerra, destacando que la verdadera fortaleza reside en los momentos de conexión y celebración.',
    'Sarah', 'J.', 'Maas', 
    'Romance', 'Fantasía', '', '', '', 
    'Trono de cristal', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-06-23', '2024-06-29', 
    'Historia corta y dulce para los fans de la saga, aunque menos sustancial que los libros principales.', 
    5.00, 
    'La familia no es sólo sangre, sino aquellos por los que estarías dispuesto a sangrar.', 
    'Lectura ligera para disfrutar en invierno'
);

-- Imperio de tormentas
CALL add_book_full(
    'Imperio de tormentas', 752, 
    'Aelin Galathynius se enfrenta a su destino final mientras prepara a su reino para la batalla contra Erawan. Mientras tanto, Manon Blackbeak debe tomar decisiones que cambiarán el curso de la guerra.',
    'Una narrativa compleja que explora los límites de la lealtad, el sacrificio y la redención. La novela entrelaza múltiples hilos narrativos, presentando personajes que deben elegir entre sus lealtades personales y el bien mayor, en un mundo al borde del colapso.',
    'Sarah', 'J.', 'Maas', 
    'Fantasía épica', 'Romantasy', '', '', '', 
    'Trono de cristal', 'dumitxmss', 'reading', 
    '2025-03-30', '2024-06-24', null, 
    null, 
    null, 
    null, 
    null
);
-- Continuation of book inserts with custom descriptions

-- Torre del alba (continued)
CALL add_book_full(
    'Torre del alba', 760, 
    'Aelin Galathynius ha sido capturada por la Reina Maeve y su destino pende de un hilo. Mientras tanto, sus aliados se dispersan por el mundo tratando de reunir fuerzas para la batalla final contra Erawan.',
    'Un punto álgido de tensión narrativa que explora los límites de la resistencia humana y la esperanza. La novela profundiza en el concepto de sacrificio, mostrando cómo los personajes encuentran su verdadera fortaleza en los momentos más oscuros y desesperados.',
    'Sarah', 'J.', 'Maas', 
    'Fantasía épica', 'Romantasy', '', '', '', 
    'Trono de cristal', 'dumitxmss', 'reading', 
    '2025-03-30', '2024-06-24', null, 
    null, 
    null, 
    null, 
    null
);

-- Alas de hierro
CALL add_book_full(
    'Alas de hierro', 885, 
    'Violet Sorrengail continúa su entrenamiento como jinete de dragones mientras la guerra se intensifica. Los secretos sobre su familia y el conflicto comienzan a revelarse.',
    'Una profunda exploración de la superación personal y el poder de la determinación. La novela desafía las expectativas de género y capacidad, mostrando cómo la verdadera fuerza proviene de la voluntad interior, la adaptabilidad y el coraje de seguir adelante incluso cuando todo parece imposible.',
    'Rebecca', 'Yarros', '', 
    'Romantasy', 'Fantasía épica', '', '', '', 
    'Empíreo', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-05-02', '2024-05-03', 
    'Segundo libro aún mejor que el primero. La evolución de Violet y Xaden es magistral. Cliffhanger devastador.', 
    10.00, 
    'Elige tu propio camino, incluso si tienes que arrastrarte por él.', 
    'El capítulo final cambia TODO - releer antes del próximo libro'
);

-- Powerless
CALL add_book_full(
    'Powerless', 591, 
    'En un mundo donde algunos nacen con poderes y otros no, Paedyn Gray, una Ordinaria, se ve obligada a competir en los Juegos Purging para demostrar su valía, mientras oculta su verdadera naturaleza.',
    'Una narrativa innovadora que desafía los tropos de los libros de poderes, centrándose en la lucha de una protagonista sin habilidades especiales en un mundo que valora el poder extraordinario. La novela explora temas de supervivencia, identidad y el verdadero significado de la fortaleza más allá de los dones sobrenaturales.',
    'Lauren', 'Roberts', '', 
    'Romance', 'Fantasía distópica', '', '', '', 
    'Powerless', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-07-07', '2024-07-12', 
    'Mezcla interesante de "Los Juegos del Hambre" y fantasía. La química entre los protagonistas es eléctrica.', 
    8.00, 
    'Ser ordinario en un mundo extraordinario es el poder más peligroso de todos.', 
    'Comparar con otros libros de competiciones/torneos'
);

-- Reckless
CALL add_book_full(
    'Reckless', 432, 
    'Paedyn Gray enfrenta nuevas amenazas mientras navega por las consecuencias de los Juegos Purging. Los secretos salen a la luz y las lealtades son puestas a prueba.',
    'Una exploración fascinante de la evolución personal en un mundo de conflicto y revelaciones. La novela profundiza en cómo las experiencias transforman a los individuos, desafiando las nociones preconcebidas de poder, lealtad y supervivencia.',
    'Lauren', 'Roberts', '', 
    'Romance', 'Fantasía distópica', '', '', '', 
    'Powerless', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-07-13', '2024-07-16', 
    'Secuela que supera al original. Más acción, más giros y desarrollo de personajes excelente.', 
    8.00, 
    'Ser temerario no es falta de miedo, sino valor para actuar a pesar de él.', 
    'Comparar evolución de Paedyn con el primer libro'
);

-- Destino Prohibido
CALL add_book_full(
    'Destino Prohibido', 340, 
    'Una historia de amor prohibido entre dos almas destinadas a estar juntas pero separadas por las circunstancias. La química entre los protagonistas es palpable desde el primer encuentro.',
    'Una narrativa romántica que explora los límites del amor más allá de las convenciones sociales. La novela desafía las nociones de destino y libre albedrío, presentando una historia de conexión profunda que trasciende las barreras impuestas por la sociedad y las circunstancias.',
    'Alba', 'Zamora', '', 
    'Romance', 'Fantasía', '', '', '', 
    'Crónicas de Hiraia', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-09-19', '2024-09-22', 
    'Encantadora historia de amor con suficiente conflicto para mantener el interés. Los personajes secundarios añaden profundidad al mundo.', 
    8.00, 
    'El corazón no entiende de prohibiciones cuando encuentra su verdadero destino.', 
    'Analizar la construcción del mundo fantástico - prometedor para la saga'
);

-- Promesas cautivas
CALL add_book_full(
    'Promesas cautivas', 325, 
    'Las consecuencias del amor prohibido se hacen presentes mientras los protagonistas luchan por mantener sus promesas en un mundo que se opone a su unión.',
    'Una continuación que profundiza en los temas de compromiso, resistencia y amor desafiante. La novela explora cómo las promesas personales pueden ser más fuertes que las restricciones sociales, presentando una narrativa de resistencia y conexión emocional.',
    'Alba', 'Zamora', '', 
    'Romance', 'Fantasía', '', '', '', 
    'Crónicas de Hiraia', 'dumitxmss', 'completed', 
    '2025-03-30', '2024-09-22', '2024-09-29', 
    'Segunda parte que mantiene la magia del primero. La tensión emocional está bien lograda.', 
    8.00, 
    'Una promesa hecha con el corazón es más fuerte que cualquier cadena.', 
    'Comparar evolución de los personajes con el primer libro'
);
-- Continuation of book inserts with custom descriptions

-- Nunca te dejaré
CALL add_book_full(
    'Nunca te dejaré', 585, 
    'Una historia oscura de obsesión y amor peligroso que explora los límites de la posesión y el consentimiento en una relación tóxica pero fascinante.',
    'Una exploración psicológicamente compleja de los límites entre amor, obsesión y poder. La novela desafía las nociones convencionales de relaciones románticas, presentando una narrativa que examina los aspectos más oscuros de la conexión humana y la vulnerabilidad.',
    'H.', 'D.', 'Carlton', 
    'Romance oscuro', 'Suspense', '', '', '', 
    'Hunting Adeline', 'issafeez', 'completed', 
    '2025-03-30', '2024-08-23', '2024-09-04', 
    'Intenso y perturbador, pero imposible de soltar. La química entre los personajes es electrizante.', 
    9.21, 
    'Perteneces a mí, incluso cuando luchas contra ello.', 
    'Contenido sensible: revisar advertencias antes de releer'
);

-- Te encontraré
CALL add_book_full(
    'Te encontraré', 662, 
    'La persecución continúa en esta segunda parte, donde los roles se invierten y la cazadora se convierte en la presa, en un juego psicológico de atracción y peligro.',
    'Una narrativa de poder y transformación que desafía las dinámicas tradicionales de perseguidor y perseguido. La novela explora los límites de la identidad, el control y la resistencia, presentando un juego psicológico complejo donde los roles de víctima y agresor se difuminan constantemente.',
    'H.', 'D.', 'Carlton', 
    'Romance oscuro', 'Thriller', '', '', '', 
    'Hunting Adeline', 'issafeez', 'completed', 
    '2025-03-30', '2024-09-01', '2024-09-06', 
    'Conclusión satisfactoria que mantiene la tensión hasta el final. Los giros argumentales son impredecibles.', 
    8.36, 
    'Incluso en la oscuridad más profunda, encontraré el camino hacia ti.', 
    'Analizar la evolución psicológica de los personajes'
);

-- Destrózame
CALL add_book_full(
    'Destrózame', 348, 
    'En un mundo distópico, Juliette posee un toque mortal y ha sido recluida toda su vida, hasta que un día es liberada por un misterioso soldado que parece inmune a su poder.',
    'Una metafórica exploración de la opresión, la identidad y la liberación personal. La novela utiliza la metáfora del poder destructivo como una alegoría de la marginación social, presentando una protagonista que debe reconciliar su trauma con su potencial de autodeterminación.',
    'Tahereh', 'Mafi', '', 
    'Distopía', 'Romance', '', '', '', 
    'Shatter Me', 'issafeez', 'completed', 
    '2025-03-30', '2024-09-05', '2024-09-07', 
    'Estilo de escritura único y poético. La voz narrativa de Juliette es fresca y conmovedora.', 
    8.93, 
    'Mi toque es letal, pero mi corazón solo quiere amar.', 
    'Prestar atención al uso de metáforas y tachones en el texto'
);

-- Uneme (Destrúyeme 1.5)
CALL add_book_full(
    'Uneme (Destrúyeme 1.5)', 114, 
    'Una historia corta desde la perspectiva de Warner que revela sus pensamientos y sentimientos durante los eventos del primer libro, dando profundidad a este complejo personaje.',
    'Un interludio narrativo que profundiza en la complejidad psicológica de un personaje tradicionalmente visto como antagonista. La novela corta desafía las nociones simplistas de buenos y malos, presentando una mirada íntima a las motivaciones y vulnerabilidades internas.',
    'Tahereh', 'Mafi', '', 
    'Distopía', 'Romance', '', '', '', 
    'Shatter Me', 'issafeez', 'completed', 
    '2025-03-30', '2024-09-07', '2024-09-09', 
    'Fascinante ver la perspectiva de Warner. Humaniza al "villano" y añade capas a la historia.', 
    8.00, 
    'No sabía que podía amarla hasta que supe que no debía.', 
    'Releer después del primer libro para mejor contexto'
);

-- Liberame
CALL add_book_full(
    'Liberame', 471, 
    'Juliette ha tomado el control de su poder y de su vida, pero el mundo fuera de los muros de la Sector 45 es más peligroso de lo que imaginaba.',
    'Una narrativa de empoderamiento y autodescubrimiento que desafía las estructuras de control y opresión. La novela explora cómo la verdadera liberación viene de la comprensión y aceptación de uno mismo, más allá de los límites físicos o sociales impuestos.',
    'Tahereh', 'Mafi', '', 
    'Distopía', 'Ciencia ficción', '', '', '', 
    'Shatter Me', 'issafeez', 'completed', 
    '2025-03-30', '2024-09-10', '2024-09-12', 
    'La evolución de Juliette es impresionante. La acción y el romance están perfectamente equilibrados.', 
    10.00, 
    'No soy un arma. No soy un monstruo. Soy libre.', 
    'El discurso de Juliette en el capítulo 25 es inspirador'
);

-- Uneme (Fracturame 2.5)
CALL add_book_full(
    'Uneme (Fracturame 2.5)', 74, 
    'Breve historia que explora momentos clave entre Warner y Juliette, dando mayor profundidad a su compleja relación durante los eventos del segundo libro.',
    'Un breve pero intenso análisis de la intimidad y la conexión más allá de las apariencias externas. La novela corta descompone las barreras entre vulnerabilidad y fortaleza, presentando una mirada íntima a la construcción de la conexión emocional.',
    'Tahereh', 'Mafi', '', 
    'Distopía', 'Romance', '', '', '', 
    'Shatter Me', 'issafeez', 'completed', 
    '2025-03-30', '2024-09-12', '2024-09-15', 
    'Pequeña joya para fans de la pareja. Escenas íntimas y emotivas bien logradas.', 
    7.50, 
    'En sus ojos encontré el reflejo de la persona que quería ser.', 
    'Leer justo después de LiberaME para continuidad'
);
-- Continuation of book inserts with custom descriptions

-- Enciendeme
CALL add_book_full(
    'Enciendeme', 439, 
    'Juliette debe unir fuerzas con aliados inesperados para enfrentar la creciente amenaza del Restablecimiento, mientras descubre la verdadera extensión de sus poderes.',
    'Una narrativa de transformación colectiva que explora cómo el poder individual se multiplica a través de la unidad y la comprensión mutua. La novela desafía las nociones de heroísmo solitario, presentando una historia de crecimiento conjunto y resistencia compartida.',
    'Tahereh', 'Mafi', '', 
    'Distopía', 'Ciencia ficción', '', '', '', 
    'Shatter Me', 'issafeez', 'completed', 
    '2025-03-30', '2024-09-12', '2024-09-19', 
    'Tercera parte llena de acción y revelaciones. El desarrollo del mundo es excelente.', 
    8.93, 
    'No somos lo que nos hicieron, somos lo que elegimos ser.', 
    'Prestar atención a los nuevos poderes que aparecen'
);

-- Caraval
CALL add_book_full(
    'Caraval', 416, 
    'Scarlett Dragna siempre ha soñado con asistir a Caraval, el espectáculo itinerante donde la audiencia participa en el show. Cuando finalmente recibe una invitación, su hermana Tella es secuestrada por el maestro del espectáculo, y Scarlett debe encontrar a su hermana antes de que termine el juego.',
    'Una exploración mágica de los límites entre realidad y fantasía, donde el juego se convierte en una metáfora de la vida misma. La novela desafía las percepciones del lector, presentando un mundo donde la línea entre lo real y lo imaginario se difumina constantemente.',
    'Stephanie', 'Garber', '', 
    'Fantasía', 'Romance', '', '', '', 
    'Caraval', 'issafeez', 'completed', 
    '2025-03-30', '2024-09-17', '2024-09-27', 
    'Mundo mágico y atmosférico con giros inesperados. La ambientación de Caraval es fascinante.', 
    9.43, 
    'Recuerda, todo en Caraval es un juego. No creas todo lo que ves.', 
    'Prestar atención a las pistas ocultas a lo largo de la historia'
);

-- El imperio del vampiro
CALL add_book_full(
    'El imperio del vampiro', 1059, 
    'En un mundo donde el sol ha muerto y los vampiros gobiernan, Gabriel de León, el último miembro de una orden de cazadores de vampiros, es capturado y obligado a contar su historia a la reina vampira.',
    'Una narrativa oscura y profunda que explora los conceptos de supervivencia, moralidad y el significado de la humanidad en un mundo post-apocalíptico. La novela desafía las nociones tradicionales de héroe y villano, presentando un universo donde las líneas entre la luz y la oscuridad se desdibujan constantemente.',
    'Jay', 'Kristoff', '', 
    'Fantasía oscura', 'Horror', '', '', '', 
    'El imperio del vampiro', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-09-20', '2024-09-28', 
    'Narrativa cruda y poderosa. Combina perfectamente fantasía oscura con elementos de horror.', 
    10.00, 
    'La esperanza es el primer paso en el camino a la decepción.', 
    'Contenido gráfico: revisar advertencias antes de releer'
);

-- El príncipe cautivo
CALL add_book_full(
    'El príncipe cautivo', 254, 
    'Un príncipe es capturado por una reina guerrera y debe aprender a navegar por la corte de su captora mientras planea su escape, pero lo que comienza como odio podría convertirse en algo más.',
    'Una exploración magistral de las dinámicas de poder, vulnerabilidad y transformación personal. La novela desafía las nociones tradicionales de romance y sumisión, presentando una relación compleja que se desarrolla más allá de las expectativas iniciales.',
    'C.', 'S.', 'Pacat', 
    'Romance', 'Fantasía', '', '', '', 
    'El príncipe cautivo', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-09-28', '2024-09-29', 
    'Química electrizante entre los protagonistas. Dinámica de enemigos a amantes bien ejecutada.', 
    7.93, 
    'El cautiverio no es solo de cuerpos, sino también de corazones.', 
    'Analizar la evolución de la relación principal'
);

-- El juego del príncipe
CALL add_book_full(
    'El juego del príncipe', 344, 
    'El príncipe continúa su juego peligroso en la corte, donde las líneas entre aliados y enemigos se difuminan y cada movimiento podría ser su último.',
    'Una intrincada danza política que explora los matices del poder, la manipulación y la supervivencia. La novela presenta un mundo donde cada interacción es un movimiento estratégico, desafiando las nociones simplistas de bien y mal.',
    'C.', 'S.', 'Pacat', 
    'Romance', 'Fantasía', '', '', '', 
    'El príncipe cautivo', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-09-28', '2024-09-30', 
    'Intriga política bien desarrollada. La tensión sexual aumenta de manera satisfactoria.', 
    7.86, 
    'En el juego del poder, cada gesto es un movimiento calculado.', 
    'Tomar notas de las estrategias políticas empleadas'
);

-- La rebelión del rey
CALL add_book_full(
    'La rebelión del rey', 305, 
    'La conclusión de la trilogía donde las lealtades son puestas a prueba y el príncipe debe decidir entre su deber y su corazón en una batalla final por el poder.',
    'Una culminación épica que examina los conflictos internos entre la obligación personal y el deseo individual. La novela desafía las estructuras de poder establecidas, presentando una narrativa de autodeterminación y transformación política.',
    'C.', 'S.', 'Pacat', 
    'Romance', 'Fantasía', '', '', '', 
    'El príncipe cautivo', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-09-30', '2024-10-02', 
    'Final satisfactorio con giros inesperados. La evolución de los personajes es notable.', 
    10.00, 
    'A veces, rebelarse es la única forma de ser fiel a uno mismo.', 
    'El epílogo es perfecto - leer con atención'
);
-- Continuation of book inserts with custom descriptions

-- Todos los ángeles del infierno
CALL add_book_full(
    'Todos los ángeles del infierno', 412, 
    'Una historia de amor prohibido entre ángeles caídos y demonios donde los límites entre el bien y el mal se difuminan, y el amor puede ser la mayor condena o la salvación.',
    'Una exploración profunda de la moralidad y la redención, que desafía las nociones tradicionales de bondad y maldad. La novela presenta un mundo donde la complejidad de la naturaleza espiritual se revela a través de personajes que trascienden las etiquetas simplistas de ángel o demonio.',
    'Miriam', 'Mosquera', '', 
    'Fantasía oscura', 'Romance', '', '', '', 
    'La caída del cielo', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-09-30', '2024-10-03', 
    'Mundo rico y personajes complejos. La mitología angelical está bien desarrollada.', 
    9.43, 
    'Incluso los ángeles más puros esconden un infierno interior.', 
    'Analizar la simbología religiosa en la historia'
);

-- Hooked
CALL add_book_full(
    'Hooked', 348, 
    'Una reinterpretación oscura de Peter Pan donde James Garber es un empresario despiadado y Wendy Darling una ladrona que roba su reloj, iniciando un juego peligroso de atracción y venganza.',
    'Una reimaginación audaz que descompone los mitos clásicos, presentando una narrativa que explora los conceptos de poder, deseo y transformación personal. La novela desafía las nociones tradicionales de los cuentos de hadas, ofreciendo una visión más compleja y adulta de la identidad y el conflicto.',
    'Emily', 'McIntire', '', 
    'Romance oscuro', 'Reimaginación', '', '', '', 
    'Historia de Nunca Jamás', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-03', '2024-10-05', 
    'Versión adulta y retorcida del clásico cuento. La química entre los protagonistas es eléctrica.', 
    8.71, 
    'Todos crecen, excepto aquellos que eligen perderse en el juego.', 
    'Comparar con el Peter Pan original - diferencias interesantes'
);

-- Scarred
CALL add_book_full(
    'Scarred', 401, 
    'Segunda parte de la saga oscura de Nunca Jamás, centrada en el Capitán Garfio y su obsesión por una mujer que podría ser su perdición o su redención.',
    'Una exploración psicológicamente compleja de la redención, la obsesión y la transformación personal. La novela desafía las nociones tradicionales de heroísmo y villanía, presentando un personaje multidimensional cuyas cicatrices internas son tan profundas como las externas.',
    'Emily', 'McIntire', '', 
    'Romance oscuro', 'Reimaginación', '', '', '', 
    'Historia de Nunca Jamás', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-04', '2024-10-09', 
    'Mejor que el primero. La profundidad psicológica del Capitán Garfio es fascinante.', 
    10.00, 
    'Las cicatrices más profundas no son las que se ven, sino las que llevamos dentro.', 
    'El monólogo interno del Capitán es brillante - analizar'
);

-- La serpiente y las alas de la noche
CALL add_book_full(
    'La serpiente y las alas de la noche', 495, 
    'En un mundo de vampiros y dioses oscuros, una humana se ve atrapada en un torneo mortal donde su mayor enemigo podría ser su única salvación.',
    'Una narrativa que desafía las jerarquías tradicionales de poder, explorando cómo la vulnerabilidad puede convertirse en la mayor fortaleza. La novela presenta un mundo complejo donde las líneas entre predador y presa, entre divinidad y mortalidad, se desdibujan constantemente.',
    'Carissa', 'Broadbent', '', 
    'Fantasía oscura', 'Romance', '', '', '', 
    'Crowns of Nyaxia', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-06', '2024-10-11', 
    'Sistema de magia único y personajes complejos. La tensión romántica está bien construida.', 
    9.14, 
    'No rezo a los dioses. Soy lo que los dioses temen.', 
    'El sistema de vampirismo es original - tomar notas'
);

-- God of Malice
CALL add_book_full(
    'God of Malice', 560, 
    'Killian es el dios de la malicia en una universidad donde los hijos de las familias mafiosas juegan a ser dioses. Glyndon es la única que parece inmune a su encanto, convirtiéndose en su obsesión.',
    'Una exploración profunda de las dinámicas de poder, atracción y resistencia en un escenario académico extraordinario. La novela desafía las nociones tradicionales de romance y sumisión, presentando una relación compleja que se desarrolla más allá de las expectativas iniciales.',
    'Rina', 'Kent', '', 
    'Romance oscuro', 'Bully romance', '', '', '', 
    'Legado de dioses', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-17', '2024-10-21', 
    'Química tóxica pero adictiva entre los protagonistas. La dinámica de poder es intrigante.', 
    7.43, 
    'No soy un salvador. Soy el villano de tu historia.', 
    'Contenido sensible: revisar advertencias'
);

-- El libro de Azrael
CALL add_book_full(
    'El libro de Azrael', 735, 
    'En un mundo donde dioses y monstruos libran una guerra eterna, una asesina mortal se alía con el enemigo más peligroso para evitar el fin del mundo.',
    'Una narrativa épica que descompone las nociones tradicionales de bien y mal, presentando un mundo donde la supervivencia y la alianza superan las etiquetas morales simplistas. La novela explora cómo los individuos pueden trascender sus roles predeterminados para enfrentar amenazas mayores.',
    'Amber', 'V.', 'Nicole', 
    'Fantasía oscura', 'Romance', '', '', '', 
    'Dioses y monstruos', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-17', '2024-10-20', 
    'Mundo complejo y personajes fascinantes. La química entre los protagonistas es electrizante.', 
    10.00, 
    'Los monstruos más peligrosos no son los que muestran sus garras, sino los que esconden sonrisas.',
    'buenisimo'
    );
    -- Continuation of book inserts with custom descriptions

-- Trono de monstruos
CALL add_book_full(
    'Trono de monstruos', 444, 
    'Segunda parte de la saga donde las alianzas se prueban y los secretos salen a la luz, mientras el mundo se balancea al borde de la destrucción total.',
    'Una exploración profunda de la naturaleza de los conflictos y las alianzas en un mundo de dioses y monstruos. La novela desafía las nociones preconcebidas de heroísmo y maldad, presentando personajes que navegan por las zonas grises de la moralidad y el poder.',
    'Amber', 'V.', 'Nicole', 
    'Fantasía oscura', 'Romance', '', '', '', 
    'Dioses y monstruos', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-20', '2024-10-22', 
    'Secuela que supera al original. Más acción, más giros y mayor desarrollo de personajes.', 
    10.00, 
    'Para gobernar un trono de monstruos, primero debes convertirte en uno.', 
    'Comparar evolución de los personajes principales'
);

-- Reconstruyeme
CALL add_book_full(
    'Reconstruyeme', 347, 
    'Juliette Ferrars ha regresado con un nuevo propósito y un ejército de aliados inesperados, lista para enfrentarse al Restablecimiento de una vez por todas.',
    'Una narrativa de resiliencia y transformación personal que explora cómo los individuos pueden reconstruirse después de la opresión. La novela desafía las nociones de víctima y poder, presentando un viaje de autodescubrimiento y resistencia colectiva.',
    'Tahereh', 'Mafi', '', 
    'Distopía', 'Ciencia ficción', '', '', '', 
    'Shatter Me', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-22', '2024-10-23', 
    'Evolución notable de la protagonista. La narrativa poética sigue siendo impactante.', 
    8.86, 
    'No estoy rota, solo reconstruida de manera diferente.', 
    'Prestar atención al desarrollo de los personajes secundarios'
);

-- Desafíame
CALL add_book_full(
    'Desafíame', 283, 
    'La batalla final se acerca y Juliette debe tomar decisiones imposibles que determinarán el futuro de su mundo y de todos los que ama.',
    'Una culminación épica que explora los límites del sacrificio personal y la resistencia colectiva. La novela desafía las nociones de heroísmo individual, presentando una narrativa donde la verdadera fuerza proviene de la conexión y la solidaridad.',
    'Tahereh', 'Mafi', '', 
    'Distopía', 'Ciencia ficción', '', '', '', 
    'Shatter Me', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-23', '2024-10-24', 
    'Conclusión emocionante de la saga principal. Satisfactoria evolución de todos los personajes.', 
    10.00, 
    'Desafiarte a ti mismo es el acto más valiente de todos.', 
    'El epílogo es perfecto - leer con atención'
);

-- Encuentrame (Ocultame 4.5)
CALL add_book_full(
    'Encuentrame (Ocultame 4.5)', 76, 
    'Una historia corta que sigue a Warner mientras busca a Juliette después de los eventos de "OcultaME", revelando sus pensamientos más íntimos y su determinación inquebrantable.',
    'Un breve pero intenso análisis de la conexión emocional más allá de las circunstancias externas. La novela corta descompone las barreras entre vulnerabilidad y fortaleza, presentando una mirada íntima a la búsqueda del amor en medio del caos.',
    'Tahereh', 'Mafi', '', 
    'Distopía', 'Romance', '', '', '', 
    'Shatter Me', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-24', '2024-10-24', 
    'Perspectiva conmovedora de Warner. Añade profundidad a su personaje y a su relación con Juliette.', 
    7.86, 
    'Cruzaría mil mundos destruidos solo para encontrarte en uno.', 
    'Leer después de OcultaME para mejor contexto'
);

-- Encuentrame (Muestrame 5.5)
CALL add_book_full(
    'Encuentrame (Muestrame 5.5)', 80, 
    'Una historia corta desde la perspectiva de Warner que revela sus pensamientos más íntimos mientras busca a Juliette después de los eventos de "MuestraME".',
    'Un interludio narrativo que profundiza en la complejidad psicológica de un personaje tradicionalmente visto como periférico. La novela corta desafía las nociones simplistas de amor y búsqueda, presentando una mirada íntima a la determinación y la conexión emocional.',
    'Tahereh', 'Mafi', '', 
    'Distopía', 'Romance', '', '', '', 
    'Shatter Me', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-24', '2024-10-24', 
    'Conmovedora mirada al interior de Warner. Añade profundidad emocional a su personaje.', 
    8.14, 
    'Encontrarte no fue un destino, fue mi elección constante.', 
    'Leer después de MuestraME para mejor contexto'
);

-- Una perdición de ruina y furia
CALL add_book_full(
    'Una perdición de ruina y furia', 558, 
    'Raine se ve atrapada en un juego peligroso con el Príncipe de la Perdición, donde la línea entre el odio y la atracción se difumina cada vez más.',
    'Una exploración magistral de las dinámicas de poder, vulnerabilidad y transformación personal. La novela desafía las nociones tradicionales de romance y sumisión, presentando una relación compleja que se desarrolla más allá de las expectativas iniciales.',
    'Jennifer','L.', 'Armentrout', 
    'Fantasía oscura', 'Romance', '', '', '', 
    'Una perdición de ruina y furia', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-10-29', '2024-11-01', 
    'Química explosiva entre los protagonistas. Mundo construido de manera fascinante.', 
    9.21, 
    'La ruina no es el fin, sino el principio de algo más poderoso.', 
    'Analizar la mitología del mundo creado'
);
-- Final batch of book inserts with custom descriptions

-- Mi alma es tuya
CALL add_book_full(
    'Mi alma es tuya', 416, 
    'En un pacto demoníaco, un alma humana es ofrecida como sacrificio, pero lo que comienza como un contrato se convierte en una conexión inesperada.',
    'Una exploración profunda de los límites entre el sacrificio y la conexión personal, desafiando las nociones tradicionales de libre albedrío y destino. La novela presenta un mundo donde los contratos sobrenaturales se convierten en metáforas de las relaciones humanas más complejas.',
    'Harley', 'Laroux', '', 
    'Romance oscuro', 'Fantasía', '', '', '', 
    'Alma', 'heliiovk_', 'completed', 
    '2025-03-30', '2024-11-01', '2024-11-06', 
    'Historia intensa con personajes complejos. La dinámica de poder está bien lograda.', 
    7.93, 
    'No me ofreciste tu alma, me entregaste tu corazón sin saberlo.', 
    'Contenido sensible: revisar advertencias'
);
/*
	Ejemplo de añadir un progreso de libro
    CALL add_reading_progress_full(
    '',     	-- Nickname del usuario
    '',     	-- Título del libro
    ',0,0,0'    -- Páginas leídas (separadas por comas)
    '1111-11-11,1111-11-11' -- Fechas correspondientes (separadas por comas)
);
*/
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Alas de sangre',               -- Título del libro
    '52,54,101,121,282,120',       -- Páginas leídas (separadas por comas)
    '2023-12-22,2023-12-23,2023-12-25,2023-12-26,2023-12-27,2023-12-28' -- Fechas correspondientes
);

CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Trono de cristal',               -- Título del libro
    '25,45,40,60,116,203',       -- Páginas leídas (separadas por comas)
    '2023-12-29,2023-12-30,2023-12-31,2024-01-01,2024-01-02,2024-01-03' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Corona de medianoche',               -- Título del libro
    '28,207,265',       -- Páginas leídas (separadas por comas)
    '2024-01-03,2024-01-04,2024-01-05' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Heredera de fuego',               -- Título del libro
    '111,553',       -- Páginas leídas (separadas por comas)
    '2024-01-08,2024-01-10,' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Reina de sombras',               -- Título del libro
    '79,354,153,144',       -- Páginas leídas (separadas por comas)
    '2024-01-10,2024-01-11,2024-01-12,2024-01-13' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Una corte de rosas y espinas',               -- Título del libro
    '122,170,162',       -- Páginas leídas (separadas por comas)
    '2024-01-14,2024-01-15,2024-01-16' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Una corte de niebla y furia',               -- Título del libro
    '90,93,233,167',       -- Páginas leídas (separadas por comas)
    '2024-01-16,2024-01-17,2024-01-18,2024-01-19' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Una corte de alas y ruina',               -- Título del libro
    '84,285,172,122',       -- Páginas leídas (separadas por comas)
    '2024-01-20,2024-01-21,2024-01-22,2024-01-23' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Una corte de hielo y estrellas',               -- Título del libro
    '265',       -- Páginas leídas (separadas por comas)
    '2024-01-23' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Imperio de tormentas',               -- Título del libro
    '92,194,25,334,116',       -- Páginas leídas (separadas por comas)
    '2024-01-24,2024-01-25,2024-01-26,2024-01-28,2024-01-29' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Torre del alba',               -- Título del libro
    '748',       -- Páginas leídas (separadas por comas)
    '2024-01-29' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Reino de cenizas',               -- Título del libro
    '85,211,236,51,62,199,122',       -- Páginas leídas (separadas por comas)
    '2024-01-30,2024-01-31,2024-02-01,2024-02-02,2024-02-04,2024-02-05,2024-02-06' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Una corte de llamas plateadas',               -- Título del libro
    '184,292,206',       -- Páginas leídas (separadas por comas)
    '2024-02-08,2024-02-10,2024-02-11' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Casa de tierra y sangre',               -- Título del libro
    '141,52,51,88,92,109,160,99',       -- Páginas leídas (separadas por comas)
    '2024-02-12,2024-02-13,2024-02-14,2024-02-15,2024-02-17,2024-02-18,2024-02-19,2024-02-20' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Alas de hierro',               -- Título del libro
    '254,364,199,68',       -- Páginas leídas (separadas por comas)
    '2024-02-22,2024-02-23,2024-02-24,2024-02-25' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Casa de cielo y aliento',               -- Título del libro
    '89,120,35,155,149,278',       -- Páginas leídas (separadas por comas)
    '2024-02-25,2024-02-26,2024-02-27,2024-02-28,2024-02-29,2024-03-01' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Casa de llama y sombra',               -- Título del libro
    '164,239,145,301',       -- Páginas leídas (separadas por comas)
    '2024-03-03,2024-03-04,2024-03-05,2024-03-06' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Powerless',               -- Título del libro
    '303,63,225',       -- Páginas leídas (separadas por comas)
    '2024-03-07,2024-03-08,2024-03-09' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'De sangre y cenizas',               -- Título del libro
    '510,153',       -- Páginas leídas (separadas por comas)
    '2024-03-11,2024-03-12' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Un reino de carne y fuego',               -- Título del libro
    '110,218,186,279',       -- Páginas leídas (separadas por comas)
    '2024-03-12,2024-03-13,2024-03-14,2024-03-15' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Una corona de huesos dorados',               -- Título del libro
    '211,114,252,217',       -- Páginas leídas (separadas por comas)
    '2024-03-16,2024-03-17,2024-03-18,2024-03-19' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Una sombra en las brasas',               -- Título del libro
    '244,197,205,94,71',       -- Páginas leídas (separadas por comas)
    '2024-03-20,2024-03-21,2024-03-22,2024-03-23,2024-03-24' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Una sombra en las brasas',               -- Título del libro
    '244,197,205,94,71',       -- Páginas leídas (separadas por comas)
    '2024-03-20,2024-03-21,2024-03-22,2024-03-23,2024-03-24' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'La guerra de las dos reinas',               -- Título del libro
    '227,196,47,53,276,120',       -- Páginas leídas (separadas por comas)
    '2024-03-25,2024-03-26,2024-03-27,2024-03-29,2024-04-01,2024-04-02' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Una luz en la llama',               -- Título del libro
    '185,290,289,113',       -- Páginas leídas (separadas por comas)
    '2024-04-03,2024-04-04,2024-04-05,2024-04-06' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Un alma de ceniza y sangre',               -- Título del libro
    '768',       -- Páginas leídas (separadas por comas)
    '2024-04-07' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Un fuego en la carne',               -- Título del libro
    '325,274,156',       -- Páginas leídas (separadas por comas)
    '2024-04-08,2024-04-09,2024-04-10' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'El imperio final',               -- Título del libro
    '127,80,223,145,135,131',       -- Páginas leídas (separadas por comas)
    '2024-04-10,2024-04-11,2024-04-12,2024-04-13,2024-04-14,2024-04-15' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'El pozo de la ascensión',               -- Título del libro
    '205,80,103',       -- Páginas leídas (separadas por comas)
    '2024-04-17,2024-04-18,2024-04-19' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'El principe cruel',               -- Título del libro
    '245,215',       -- Páginas leídas (separadas por comas)
    '2024-04-24,2024-04-25' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'El rey malvado',               -- Título del libro
    '179,197',       -- Páginas leídas (separadas por comas)
    '2024-04-28,2024-04-29' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Destino prohibido',               -- Título del libro
    '84,123,133',       -- Páginas leídas (separadas por comas)
    '2024-08-19,2024-08-20,2024-08-21' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Promesas cautivas',               -- Título del libro
    '325',       -- Páginas leídas (separadas por comas)
    '2024-08-22' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Nunca te dejaré',               -- Título del libro
    '55,73,78,146,233',       -- Páginas leídas (separadas por comas)
    '2024-08-23,2024-08-24,2024-08-27,2024-08-28,2024-08-29' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Te encontraré',               -- Título del libro
    '106,254,146,35,121',       -- Páginas leídas (separadas por comas)
    '2024-09-01,2024-09-02,2024-09-03,2024-09-04,2024-09-05' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Destrózame',               -- Título del libro
    '128,220',       -- Páginas leídas (separadas por comas)
    '2024-09-05,2024-09-06' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Uneme (Destrúyeme 1.5)',               -- Título del libro
    '114',       -- Páginas leídas (separadas por comas)
    '2024-09-07' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Reckless',               -- Título del libro
    '74,362',       -- Páginas leídas (separadas por comas)
    '2024-09-08,2024-09-09' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Liberame',               -- Título del libro
    '322,149',       -- Páginas leídas (separadas por comas)
    '2024-09-10,2024-09-1' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Uneme (Fracturame 2.5)',               -- Título del libro
    '74',       -- Páginas leídas (separadas por comas)
    '2024-09-12' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Enciendeme',               -- Título del libro
    '210,70,30,129',       -- Páginas leídas (separadas por comas)
    '2024-09-12,2024-09-13,2024-09-14,2024-09-15' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Caraval',               -- Título del libro
    '124,204,89',       -- Páginas leídas (separadas por comas)
    '2024-09-17,2024-09-18,2024-09-19' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'El imperio del vampiro',               -- Título del libro
    '25,71,122,80,117,288,279,77',       -- Páginas leídas (separadas por comas)
    '2024-09-20,2024-09-21,2024-09-22,2024-09-23,2024-09-24,2024-09-25,2024-09-26,2024-09-27' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'El príncipe cautivo',               -- Título del libro
    '254',       -- Páginas leídas (separadas por comas)
    '2024-09-28' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'El juego del principe',               -- Título del libro
    '70,274',       -- Páginas leídas (separadas por comas)
    '2024-09-28,2024-09-29' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'La rebelión del rey',               -- Título del libro
    '305',       -- Páginas leídas (separadas por comas)
    '2024-09-30' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Todos los angeles del infierno',               -- Título del libro
    '82,182,148',       -- Páginas leídas (separadas por comas)
    '2024-09-30,2024-10-01,2024-10-02' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Hooked',               -- Título del libro
    '348',       -- Páginas leídas (separadas por comas)
    '2024-10-03' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Scarred',               -- Título del libro
    '90.311',       -- Páginas leídas (separadas por comas)
    '2024-10-04,2024-10-05' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'La serpiente y las alas de la noche',               -- Título del libro
    '128,235,40,92',       -- Páginas leídas (separadas por comas)
    '2024-10-06,2024-10-07,2024-10-08,2024-10-09' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'God of malice',               -- Título del libro
    '310,250',       -- Páginas leídas (separadas por comas)
    '2024-10-10,2024-10-11' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'El libro de Azrael',               -- Título del libro
    '277,199,228,31',       -- Páginas leídas (separadas por comas)
    '2024-10-14,2024-10-15,2024-10-16,2024-10-17' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Trono de monstruos',               -- Título del libro
    '123,161,160',       -- Páginas leídas (separadas por comas)
    '2024-10-18,2024-10-15,2024-10-19,2024-10-20' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Reconstruyeme',               -- Título del libro
    '175,172',       -- Páginas leídas (separadas por comas)
    '2024-10-21,2024-10-22' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Desafíame',               -- Título del libro
    '134,149',       -- Páginas leídas (separadas por comas)
    '2024-10-22,2024-10-23' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Encuentrame (Ocultame 4.5)',               -- Título del libro
    '76',       -- Páginas leídas (separadas por comas)
    '2024-10-24' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Encuentrame (Muestrame 5.5)',               -- Título del libro
    '80',       -- Páginas leídas (separadas por comas)
    '2024-10-25' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Una perdición de ruina y furia',               -- Título del libro
    '300,139,119',       -- Páginas leídas (separadas por comas)
    '2024-10-29,2024-10-30,2024-11-01' -- Fechas correspondientes
);
CALL add_reading_progress_full(
    'joss0102',                     -- Nickname del usuario
    'Mi alma es tuya',               -- Título del libro
    '96,144,100,76',       -- Páginas leídas (separadas por comas)
    '2024-11-02,2024-11-04,2024-11-05,2024-11-06' -- Fechas correspondientes
);