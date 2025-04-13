-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1:3306
-- Tiempo de generación: 13-04-2025 a las 12:58:15
-- Versión del servidor: 8.0.31
-- Versión de PHP: 8.0.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `lectoria`
--
DROP DATABASE IF EXISTS Lectoria;
CREATE DATABASE Lectoria;
USE Lectoria;

DELIMITER $$
--
-- Procedimientos
--
DROP PROCEDURE IF EXISTS `add_author_full`$$
CREATE DEFINER=`Lectoria`@`localhost` PROCEDURE `add_author_full` (IN `p_name` VARCHAR(100), IN `p_last_name1` VARCHAR(100), IN `p_last_name2` VARCHAR(100), IN `p_description` TEXT)   BEGIN
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
END$$

DROP PROCEDURE IF EXISTS `add_book_full`$$
CREATE DEFINER=`Lectoria`@`localhost` PROCEDURE `add_book_full` (IN `p_title` VARCHAR(255), IN `p_pages` INT, IN `p_synopsis` TEXT, IN `p_custom_description` TEXT, IN `p_author_name` VARCHAR(255), IN `p_author_last_name1` VARCHAR(255), IN `p_author_last_name2` VARCHAR(255), IN `p_genre1` VARCHAR(255), IN `p_genre2` VARCHAR(255), IN `p_genre3` VARCHAR(255), IN `p_genre4` VARCHAR(255), IN `p_genre5` VARCHAR(255), IN `p_saga_name` VARCHAR(255), IN `p_user_nickname` VARCHAR(100), IN `p_status` VARCHAR(50), IN `p_date_added` DATE, IN `p_date_start` DATE, IN `p_date_ending` DATE, IN `p_review` TEXT, IN `p_rating` DECIMAL(4,2), IN `p_phrases` TEXT, IN `p_notes` TEXT)   BEGIN
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

END$$

DROP PROCEDURE IF EXISTS `add_reading_progress_full`$$
CREATE DEFINER=`Lectoria`@`localhost` PROCEDURE `add_reading_progress_full` (IN `p_nickname` VARCHAR(100), IN `p_book_title` VARCHAR(255), IN `p_pages_read_list` TEXT, IN `p_dates_list` TEXT)   BEGIN
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
    

END$$

DROP PROCEDURE IF EXISTS `add_user_full`$$
CREATE DEFINER=`Lectoria`@`localhost` PROCEDURE `add_user_full` (IN `p_name` VARCHAR(100), IN `p_last_name1` VARCHAR(100), IN `p_last_name2` VARCHAR(100), IN `p_birthdate` DATE, IN `p_union_date` DATE, IN `p_nickName` VARCHAR(100), IN `p_password` VARCHAR(255), IN `p_role_name` VARCHAR(50))   BEGIN
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
    
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `author`
--

DROP TABLE IF EXISTS `author`;
CREATE TABLE IF NOT EXISTS `author` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `last_name1` varchar(100) DEFAULT NULL,
  `last_name2` varchar(100) DEFAULT NULL,
  `description` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `author`
--

INSERT INTO `author` (`id`, `name`, `last_name1`, `last_name2`, `description`) VALUES
(1, 'Rebecca', 'Yarros', '', 'Rebecca Yarros es una autora bestseller de novelas románticas para jóvenes adultos. Conocida por su narrativa emocional e intensa, ha escrito series populares como la trilogía Empíreo y La última carta. Esposa de un militar, su escritura a menudo explora temas de resiliencia, amor y crecimiento personal.'),
(2, 'Sarah', 'J.', 'Maas', 'Sarah J. Maas es una autora bestseller de The New York Times, reconocida por sus novelas de fantasía épica y para jóvenes adultos. Creó las inmensamente populares series Trono de Cristal y Una Corte de Rosas y Espinas. Su escritura se caracteriza por protagonistas femeninas fuertes, una construcción de mundo intrincada y tramas románticas complejas.'),
(3, 'Lauren', 'Roberts', '', 'Lauren Roberts es una autora de fantasía para jóvenes adultos conocida por su serie Powerless. Su escritura se enfoca en mundos distópicos y personajes que navegan estructuras sociales complejas. Ha ganado rápidamente popularidad por su enfoque innovador de la narrativa fantástica y su desarrollo de personajes cautivador.'),
(4, 'Jennifer', 'L.', 'Armentrout', 'Jennifer L. Armentrout es una autora prolífica y bestseller de ficción para jóvenes adultos, nuevos adultos y adultos en múltiples géneros, incluyendo romance paranormal, contemporáneo y de fantasía. Es conocida por sus series Lux, De Sangre y Cenizas, y su capacidad para crear narrativas apasionantes con personajes complejos.'),
(5, 'Brandon', 'Sanderson', '', 'Brandon Sanderson es un reconocido autor de fantasía y ciencia ficción conocido por sus sistemas de magia intrincados y su construcción épica de mundos. Completó la serie Rueda del Tiempo de Robert Jordan y es famoso por la trilogía Nacidos de la Bruma, El Archivo de las Tormentas, y su enfoque único de la escritura de fantasía que enfatiza reglas mágicas lógicas y sistemáticas.'),
(6, 'Holly', 'Black', '', 'Holly Black es una aclamada autora de fantasía para jóvenes adultos conocida por sus oscuros y complejos cuentos de hadas. Co-creó las Crónicas Spiderwick y escribió la popular trilogía Habitantes del Aire. Su escritura a menudo explora temas complejos de poder, identidad y ambigüedad moral en entornos mágicos.'),
(7, 'Alba', 'Zamora', '', 'Alba Zamora es una autora emergente en el género de fantasía romántica para jóvenes adultos. Su serie Crónicas de Hiraia explora temas de amor prohibido y destino personal dentro de mundos fantásticos ricamente imaginados. Es conocida por crear narrativas emocionalmente cautivadoras que mezclan romance y elementos mágicos.'),
(8, 'H.', 'D.', 'Carlton', 'H. D. Carlton es una autora de romance contemporáneo conocida por escribir novelas románticas oscuras e intensas. Su trabajo a menudo explora la profundidad psicológica y las dinámicas de relaciones complejas, desafiando los límites del romance tradicional.'),
(9, 'Tahereh', 'Mafi', '', 'Tahereh Mafi es una autora bestseller conocida por su serie Shatter Me, una innovadora novela distópica que combina elementos de ciencia ficción y romance. Su estilo de escritura distintivo se caracteriza por un uso poético del lenguaje y narrativas que exploran la transformación personal y la resistencia.'),
(10, 'Stephanie', 'Garber', '', 'Stephanie Garber es una autora de fantasía para jóvenes adultos conocida por su serie Caraval. Su escritura se destaca por crear mundos mágicos inmersivos con elementos de juego, ilusión y misterio, explorando temas de destino, libertad y los límites entre la realidad y la fantasía.'),
(11, 'Jay', 'Kristoff', '', 'Jay Kristoff es un autor australiano de ciencia ficción y fantasía conocido por sus novelas oscuras y originales. Sus obras, como El Imperio del Vampiro, combinan elementos de horror y fantasía oscura, destacándose por su narrativa innovadora y mundos complejos.'),
(12, 'C.', 'S.', 'Pecat', 'C. S. Pecat es una autora conocida por su trilogía El Príncipe Cautivo, que combina elementos de fantasía y romance. Su trabajo se caracteriza por explorar dinámicas de poder, política y relaciones románticas complejas en mundos de fantasía elaborados.'),
(13, 'Miriam', 'Mosquera', '', 'Miriam Mosquera es una autora de fantasía oscura que explora temas de mitología, espiritualidad y relaciones complejas. Su trabajo se centra en mundos donde los límites entre el bien y el mal se desdibujan, presentando narrativas que desafían las percepciones tradicionales.'),
(14, 'Emily', 'McIntire', '', 'Emily McIntire es una autora de romance contemporáneo y reinterpretaciones oscuras de cuentos clásicos. Su trabajo se caracteriza por transformar narrativas familiares en historias para adultos que exploran la psicología de los personajes y las dinámicas de poder.'),
(15, 'Carissa', 'Broadbent', '', 'Carissa Broadbent es una autora emergente de fantasía romántica conocida por crear mundos complejos con sistemas de magia únicos. Su trabajo combina elementos de fantasía oscura y romance, explorando temas de poder, transformación y conexiones más allá de lo convencional.'),
(16, 'Rina', 'Kent', '', 'Rina Kent es una autora de romance contemporáneo y new adult conocida por sus novelas intensas y psicológicamente complejas. Su trabajo se enfoca en relaciones con dinámicas de poder desafiantes y personajes con profundidades emocionales complejas.'),
(17, 'Amber', 'V.', 'Nicole', 'Amber V. Nicole es una autora de fantasía oscura y romance que se destaca por crear mundos mitológicos complejos. Su trabajo explora temas de dioses, monstruos y las complejas relaciones entre seres sobrenaturales, presentando narrativas que desafían las expectativas del género.'),
(18, 'Harley', 'Laroux', '', 'Harley Laroux es una autora de romance oscuro conocida por crear narrativas intensas que exploran los límites entre el amor, el poder y la oscuridad. Su trabajo se caracteriza por relaciones complejas que desafían las nociones tradicionales de romance y consentimiento.'),
(19, 'Ana', 'Huang', '', 'Ana Huang es una autora bestseller de novelas románticas contemporáneas para adultos jóvenes. Conocida por sus tramas intensas que combinan drama, pasión y personajes complejos, ha ganado reconocimiento internacional con su serie \"Twisted\" y \"Kings of Sin\". '),
(20, 'Sarah', 'A.', 'Parker', 'Sarah A. Parker es una autora superventas internacional. Se crio en una granja en Nueva Zelanda, donde pasaba los días deambulando entre los pastos, construyendo fuertes en la maleza, trepando árboles y explorando el bosque mientras imaginaba historias llenas de detalles que jamás la han abandonado.'),
(21, 'Abigail', 'Owen', '', 'Abigail Owen es una autora de fantasía romántica juvenil y new adult. Le encantan las tramas rápidas y apasionantes, las heroínas y los héroes con corazón, un toque de sarcasmo y muchos finales felices.');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `book`
--

DROP TABLE IF EXISTS `book`;
CREATE TABLE IF NOT EXISTS `book` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `pages` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `book`
--

INSERT INTO `book` (`id`, `title`, `pages`) VALUES
(1, 'Alas de sangre', 730),
(2, 'Trono de cristal', 489),
(3, 'Corona de medianoche', 500),
(4, 'Heredera de fuego', 664),
(5, 'Reina de sombras', 730),
(6, 'Una corte de rosas y espinas', 456),
(7, 'Una corte de niebla y furia', 592),
(8, 'Una corte de alas y ruina', 800),
(9, 'Una corte de hielo y estrellas', 240),
(10, 'Imperio de tormentas', 752),
(11, 'Torre del alba', 760),
(12, 'Reino de cenizas', 966),
(13, 'Una corte de llamas plateadas', 816),
(14, 'Casa de tierra y sangre', 792),
(15, 'Alas de hierro', 885),
(16, 'Casa de cielo y aliento', 826),
(17, 'Casa de llama y sombra', 849),
(18, 'Powerless', 591),
(19, 'De sangre y cenizas', 663),
(20, 'Un reino de carne y fuego', 793),
(21, 'Una corona de huesos dorados', 784),
(22, 'Una sombra en las brasas', 811),
(23, 'La guerra de las dos reinas', 911),
(24, 'Una luz en la llama', 877),
(25, 'Un alma de ceniza y sangre', 771),
(26, 'Un fuego en la carne', 755),
(27, 'El imperio final', 841),
(28, 'El pozo de la ascensión', 766),
(29, 'El príncipe cruel', 460),
(30, 'El rey malvado', 376),
(31, 'Destino Prohibido', 340),
(32, 'Promesas cautivas', 325),
(33, 'Nunca te dejaré', 585),
(34, 'Te encontraré', 662),
(35, 'Destrózame', 348),
(36, 'Uneme (Destrúyeme 1.5)', 114),
(37, 'Reckless', 432),
(38, 'Liberame', 471),
(39, 'Uneme (Fracturame 2.5)', 74),
(40, 'Enciendeme', 439),
(41, 'Caraval', 416),
(42, 'El imperio del vampiro', 1059),
(43, 'El príncipe cautivo', 254),
(44, 'El juego del príncipe', 344),
(45, 'La rebelión del rey', 305),
(46, 'Todos los ángeles del infierno', 412),
(47, 'Hooked', 348),
(48, 'La serpiente y las alas de la noche', 495),
(49, 'God of Malice', 560),
(50, 'El libro de Azrael', 735),
(51, 'Trono de monstruos', 444),
(52, 'Reconstruyeme', 347),
(53, 'Desafíame', 283),
(54, 'Encuentrame (Ocultame 4.5)', 76),
(55, 'Encuentrame (Muestrame 5.5)', 80),
(56, 'Una perdición de ruina y furia', 558),
(57, 'Mi alma es tuya', 416),
(58, 'Scarred', 401),
(59, 'Nacida de sangre y cenizas', 1020),
(60, 'Twisted love', 389),
(61, 'Twisted games', 489),
(62, 'Rey de la ira', 489),
(63, 'Rey de la soberbia', 458),
(64, 'Rey de la codicia', 356),
(65, 'El imperio de los condenados', 909),
(66, 'Fearless', 647),
(67, 'Hasta que caiga la luna', 643),
(68, 'Alas de ónix', 888),
(69, 'Legendary', 374),
(70, 'Finale', 412),
(71, 'Spectacular', 203),
(72, 'Érase una vez un corazón roto', 343),
(73, 'La balada de nunca jamás', 345),
(74, 'La maldición del amor verdadero', 345),
(75, 'Los juegos de los dioses', 616),
(76, 'Mi alma por venganza', 325),
(77, 'La reina de nada', 278);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `book_has_author`
--

DROP TABLE IF EXISTS `book_has_author`;
CREATE TABLE IF NOT EXISTS `book_has_author` (
  `id_book` int NOT NULL,
  `id_author` int NOT NULL,
  PRIMARY KEY (`id_book`,`id_author`),
  KEY `id_author` (`id_author`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `book_has_author`
--

INSERT INTO `book_has_author` (`id_book`, `id_author`) VALUES
(1, 1),
(2, 2),
(3, 2),
(4, 2),
(5, 2),
(6, 2),
(7, 2),
(8, 2),
(9, 2),
(10, 2),
(11, 2),
(12, 2),
(13, 2),
(14, 2),
(15, 1),
(16, 2),
(17, 2),
(18, 3),
(19, 4),
(20, 4),
(21, 4),
(22, 4),
(23, 4),
(24, 4),
(25, 4),
(26, 4),
(27, 5),
(28, 5),
(29, 6),
(30, 6),
(31, 7),
(32, 7),
(33, 8),
(34, 8),
(35, 9),
(36, 9),
(37, 3),
(38, 9),
(39, 9),
(40, 9),
(41, 10),
(42, 11),
(43, 12),
(44, 12),
(45, 12),
(46, 13),
(47, 14),
(48, 15),
(49, 16),
(50, 17),
(51, 17),
(52, 9),
(53, 9),
(54, 9),
(55, 9),
(56, 4),
(57, 18),
(58, 14),
(59, 4),
(60, 19),
(61, 19),
(62, 19),
(63, 19),
(64, 19),
(65, 11),
(66, 3),
(67, 20),
(68, 1),
(69, 10),
(70, 10),
(71, 10),
(72, 10),
(73, 10),
(74, 10),
(75, 21),
(76, 18),
(77, 6);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `book_has_genre`
--

DROP TABLE IF EXISTS `book_has_genre`;
CREATE TABLE IF NOT EXISTS `book_has_genre` (
  `id_book` int NOT NULL,
  `id_genre` int NOT NULL,
  PRIMARY KEY (`id_book`,`id_genre`),
  KEY `id_genre` (`id_genre`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `book_has_genre`
--

INSERT INTO `book_has_genre` (`id_book`, `id_genre`) VALUES
(1, 1),
(1, 2),
(1, 3),
(2, 1),
(2, 4),
(2, 5),
(3, 1),
(3, 4),
(3, 5),
(4, 1),
(4, 4),
(4, 5),
(5, 1),
(5, 4),
(5, 5),
(6, 1),
(6, 5),
(6, 6),
(7, 1),
(7, 5),
(7, 6),
(8, 1),
(8, 2),
(8, 5),
(9, 5),
(9, 7),
(9, 8),
(10, 1),
(10, 2),
(10, 5),
(11, 1),
(11, 2),
(11, 5),
(12, 1),
(12, 2),
(12, 5),
(13, 1),
(13, 5),
(13, 6),
(14, 7),
(14, 9),
(14, 10),
(15, 1),
(15, 2),
(15, 3),
(16, 1),
(16, 9),
(16, 10),
(17, 1),
(17, 9),
(17, 10),
(18, 7),
(18, 11),
(18, 12),
(19, 1),
(19, 6),
(19, 13),
(20, 1),
(20, 6),
(20, 13),
(21, 1),
(21, 6),
(21, 13),
(22, 1),
(22, 6),
(22, 13),
(23, 1),
(23, 2),
(23, 13),
(24, 1),
(24, 6),
(24, 13),
(25, 1),
(25, 6),
(25, 13),
(26, 1),
(26, 6),
(26, 13),
(27, 2),
(27, 14),
(27, 15),
(28, 2),
(28, 14),
(28, 15),
(29, 7),
(29, 11),
(30, 7),
(30, 11),
(31, 7),
(31, 11),
(32, 7),
(32, 11),
(33, 16),
(33, 17),
(34, 16),
(34, 17),
(35, 7),
(35, 12),
(35, 18),
(36, 7),
(36, 12),
(36, 18),
(37, 7),
(37, 11),
(37, 12),
(38, 12),
(38, 18),
(38, 19),
(39, 7),
(39, 12),
(39, 18),
(40, 12),
(40, 18),
(40, 19),
(41, 7),
(41, 8),
(41, 20),
(42, 6),
(42, 21),
(42, 22),
(43, 7),
(43, 8),
(43, 23),
(44, 7),
(44, 8),
(44, 23),
(45, 7),
(45, 8),
(45, 23),
(46, 6),
(46, 7),
(46, 24),
(47, 16),
(47, 25),
(48, 7),
(48, 8),
(48, 22),
(49, 16),
(49, 26),
(50, 7),
(50, 8),
(50, 10),
(51, 7),
(51, 8),
(51, 10),
(52, 11),
(52, 12),
(53, 11),
(53, 12),
(54, 11),
(54, 12),
(55, 11),
(55, 12),
(56, 6),
(56, 7),
(56, 13),
(57, 8),
(57, 16),
(57, 27),
(58, 16),
(58, 25),
(59, 1),
(59, 2),
(59, 13),
(60, 10),
(60, 28),
(61, 10),
(61, 28),
(62, 10),
(62, 28),
(63, 10),
(63, 28),
(64, 10),
(64, 28),
(65, 6),
(65, 21),
(65, 22),
(66, 7),
(66, 11),
(66, 12),
(67, 3),
(67, 7),
(67, 8),
(68, 1),
(68, 2),
(68, 3),
(69, 7),
(69, 8),
(69, 20),
(70, 7),
(70, 8),
(70, 20),
(71, 7),
(71, 8),
(71, 20),
(72, 7),
(72, 8),
(72, 20),
(73, 7),
(73, 8),
(73, 20),
(74, 7),
(74, 8),
(74, 20),
(75, 7),
(75, 8),
(75, 13),
(76, 7),
(76, 8),
(76, 27),
(77, 5),
(77, 7),
(77, 11);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `book_has_saga`
--

DROP TABLE IF EXISTS `book_has_saga`;
CREATE TABLE IF NOT EXISTS `book_has_saga` (
  `id_book` int NOT NULL,
  `id_saga` int NOT NULL,
  PRIMARY KEY (`id_book`,`id_saga`),
  KEY `id_saga` (`id_saga`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `book_has_saga`
--

INSERT INTO `book_has_saga` (`id_book`, `id_saga`) VALUES
(1, 1),
(2, 2),
(3, 2),
(4, 2),
(5, 2),
(6, 3),
(7, 3),
(8, 3),
(9, 3),
(10, 2),
(11, 2),
(12, 2),
(13, 3),
(14, 4),
(15, 1),
(16, 4),
(17, 4),
(18, 5),
(19, 6),
(20, 6),
(21, 6),
(22, 6),
(23, 6),
(24, 6),
(25, 6),
(26, 6),
(27, 7),
(28, 7),
(29, 8),
(30, 8),
(31, 9),
(32, 9),
(33, 10),
(34, 10),
(35, 11),
(36, 11),
(37, 5),
(38, 11),
(39, 11),
(40, 11),
(41, 12),
(42, 13),
(43, 14),
(44, 14),
(45, 14),
(46, 15),
(47, 16),
(48, 17),
(49, 18),
(50, 19),
(51, 19),
(52, 11),
(53, 11),
(54, 11),
(55, 11),
(56, 20),
(57, 21),
(58, 16),
(59, 6),
(60, 22),
(61, 22),
(62, 23),
(63, 23),
(64, 23),
(65, 13),
(66, 5),
(67, 24),
(68, 1),
(69, 12),
(70, 12),
(71, 12),
(72, 12),
(73, 12),
(74, 12),
(75, 25),
(76, 21),
(77, 8);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `book_note`
--

DROP TABLE IF EXISTS `book_note`;
CREATE TABLE IF NOT EXISTS `book_note` (
  `id` int NOT NULL AUTO_INCREMENT,
  `text` text NOT NULL,
  `id_book` int NOT NULL,
  `id_user` int NOT NULL,
  `date_created` date NOT NULL,
  `date_modified` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `id_book` (`id_book`),
  KEY `id_user` (`id_user`)
) ENGINE=MyISAM AUTO_INCREMENT=97 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `book_note`
--

INSERT INTO `book_note` (`id`, `text`, `id_book`, `id_user`, `date_created`, `date_modified`) VALUES
(1, 'Releer capítulo 12 - la escena del primer vuelo es impresionante', 1, 1, '2025-04-13', NULL),
(2, 'Celaena es increíblemente sarcástica - tomar notas de sus diálogos', 2, 1, '2025-04-13', NULL),
(3, 'Analizar el desarrollo del personaje de Chaol en esta entrega', 3, 1, '2025-04-13', NULL),
(4, 'El capítulo 42 contiene una de las mejores escenas de acción de la saga', 4, 1, '2025-04-13', NULL),
(5, 'Subrayar todos los diálogos entre Aelin y Rowan - química perfecta', 5, 1, '2025-04-13', NULL),
(6, 'Releer la escena del baile bajo la máscara - simbolismo impresionante', 6, 1, '2025-04-13', NULL),
(7, 'Analizar el desarrollo del personaje de Rhysand - arco magistral', 7, 1, '2025-04-13', NULL),
(8, 'El discurso de Feyre en el capítulo 67 es inspirador - memorizar', 8, 1, '2025-04-13', NULL),
(9, 'Lectura ligera para disfrutar en invierno', 9, 1, '2025-04-13', NULL),
(10, 'El capítulo 89 es uno de los más impactantes de toda la saga - preparar pañuelos', 10, 1, '2025-04-13', NULL),
(11, 'Analizar los paralelismos entre Aelin y Elena', 11, 1, '2025-04-13', NULL),
(12, 'El epílogo es perfecto - leer con música épica de fondo', 12, 1, '2025-04-13', NULL),
(13, 'Subrayar todas las escenas de entrenamiento - crecimiento impresionante', 13, 1, '2025-04-13', NULL),
(14, 'El sistema de magia es único - hacer diagramas para entenderlo mejor', 14, 1, '2025-04-13', NULL),
(15, 'El capítulo final cambia TODO - releer antes del próximo libro', 15, 1, '2025-04-13', NULL),
(16, 'El cameo de personajes de ACOTAR es brillante - analizar conexiones', 16, 1, '2025-04-13', NULL),
(17, 'Hacer mapa de conexiones entre los diferentes universos de SJM', 17, 1, '2025-04-13', NULL),
(18, 'Comparar con otros libros de competiciones/torneos', 18, 1, '2025-04-13', NULL),
(19, 'Analizar paralelismos con mitología griega', 19, 1, '2025-04-13', NULL),
(20, 'Las escenas de batalla son cinematográficas - visualizar bien', 20, 1, '2025-04-13', NULL),
(21, 'Analizar el discurso de Poppy en el capítulo 32 - poderosa declaración de principios', 21, 1, '2025-04-13', NULL),
(22, 'El nuevo personaje introducido en el capítulo 15 será clave - tomar notas', 22, 1, '2025-04-13', NULL),
(23, 'El capítulo 78 es devastador - prepararse emocionalmente para releer', 23, 1, '2025-04-13', NULL),
(24, 'Analizar el desarrollo de la relación principal en esta nueva etapa', 24, 1, '2025-04-13', NULL),
(25, 'La revelación final cambia toda la perspectiva de la saga - releer con esta nueva información', 25, 1, '2025-04-13', NULL),
(26, 'Prestar atención a los nuevos poderes que se manifiestan - importante para próximos libros', 26, 1, '2025-04-13', NULL),
(27, 'Hacer diagramas del sistema de alomancia para entenderlo mejor', 27, 1, '2025-04-13', NULL),
(28, 'Analizar las diferencias entre los sistemas de magia de este mundo', 28, 1, '2025-04-13', NULL),
(29, 'Tomar notas de las estrategias políticas de Jude', 29, 1, '2025-04-13', NULL),
(30, 'Analizar el arco de redención del personaje principal', 30, 1, '2025-04-13', NULL),
(31, 'Analizar la construcción del mundo fantástico - prometedor para la saga', 31, 1, '2025-04-13', NULL),
(32, 'Comparar evolución de los personajes con el primer libro', 32, 1, '2025-04-13', NULL),
(33, 'Contenido sensible: revisar advertencias antes de releer', 33, 1, '2025-04-13', NULL),
(34, 'Analizar la evolución psicológica de los personajes', 34, 1, '2025-04-13', NULL),
(35, 'Prestar atención al uso de metáforas y tachones en el texto', 35, 1, '2025-04-13', NULL),
(36, 'Releer después del primer libro para mejor contexto', 36, 1, '2025-04-13', NULL),
(37, 'Comparar evolución de Paedyn con el primer libro', 37, 1, '2025-04-13', NULL),
(38, 'El discurso de Juliette en el capítulo 25 es inspirador', 38, 1, '2025-04-13', NULL),
(39, 'Leer justo después de LiberaME para continuidad', 39, 1, '2025-04-13', NULL),
(40, 'Prestar atención a los nuevos poderes que aparecen', 40, 1, '2025-04-13', NULL),
(41, 'Prestar atención a las pistas ocultas a lo largo de la historia', 41, 1, '2025-04-13', NULL),
(42, 'Contenido gráfico: revisar advertencias antes de releer', 42, 1, '2025-04-13', NULL),
(43, 'Analizar la evolución de la relación principal', 43, 1, '2025-04-13', NULL),
(44, 'Tomar notas de las estrategias políticas empleadas', 44, 1, '2025-04-13', NULL),
(45, 'El epílogo es perfecto - leer con atención', 45, 1, '2025-04-13', NULL),
(46, 'Analizar la simbología religiosa en la historia', 46, 1, '2025-04-13', NULL),
(47, 'El monólogo interno del Capitán es brillante - analizar', 47, 1, '2025-04-13', NULL),
(48, 'El sistema de vampirismo es original - tomar notas', 48, 1, '2025-04-13', NULL),
(49, 'Contenido sensible: revisar advertencias', 49, 1, '2025-04-13', NULL),
(50, 'Analizar la mitología creada - muy original', 50, 1, '2025-04-13', NULL),
(51, 'Comparar evolución de los personajes principales', 51, 1, '2025-04-13', NULL),
(52, 'Prestar atención al desarrollo de los personajes secundarios', 52, 1, '2025-04-13', NULL),
(53, 'El epílogo es perfecto - leer con atención', 53, 1, '2025-04-13', NULL),
(54, 'Leer después de OcultaME para mejor contexto', 54, 1, '2025-04-13', NULL),
(55, 'Leer después de MuestraME para mejor contexto', 55, 1, '2025-04-13', NULL),
(56, 'Analizar la mitología del mundo creado', 56, 1, '2025-04-13', NULL),
(57, 'Contenido sensible: revisar advertencias', 57, 1, '2025-04-13', NULL),
(58, 'Comparar con el Peter Pan original - diferencias interesantes', 58, 1, '2025-04-13', NULL),
(59, 'Releer capítulo 12 - la escena del primer vuelo es impresionante', 1, 3, '2025-04-13', NULL),
(60, 'Celaena es increíblemente sarcástica - tomar notas de sus diálogos', 2, 3, '2025-04-13', NULL),
(61, 'Analizar el desarrollo del personaje de Chaol en esta entrega', 3, 3, '2025-04-13', NULL),
(62, 'El capítulo 42 contiene una de las mejores escenas de acción de la saga', 4, 3, '2025-04-13', NULL),
(63, 'Subrayar todos los diálogos entre Aelin y Rowan - química perfecta', 5, 3, '2025-04-13', NULL),
(64, 'Releer la escena del baile bajo la máscara - simbolismo impresionante', 6, 3, '2025-04-13', NULL),
(65, 'Analizar el desarrollo del personaje de Rhysand - arco magistral', 7, 3, '2025-04-13', NULL),
(66, 'El discurso de Feyre en el capítulo 67 es inspirador - memorizar', 8, 3, '2025-04-13', NULL),
(67, 'Lectura ligera para disfrutar en invierno', 9, 3, '2025-04-13', NULL),
(68, 'El capítulo final cambia TODO - releer antes del próximo libro', 15, 3, '2025-04-13', NULL),
(69, 'Comparar con otros libros de competiciones/torneos', 18, 3, '2025-04-13', NULL),
(70, 'Comparar evolución de Paedyn con el primer libro', 37, 3, '2025-04-13', NULL),
(71, 'Analizar la construcción del mundo fantástico - prometedor para la saga', 31, 3, '2025-04-13', NULL),
(72, 'Contenido sensible: revisar advertencias antes de releer', 33, 4, '2025-04-13', NULL),
(73, 'Analizar la evolución psicológica de los personajes', 34, 4, '2025-04-13', NULL),
(74, 'Prestar atención al uso de metáforas y tachones en el texto', 35, 4, '2025-04-13', NULL),
(75, 'Releer después del primer libro para mejor contexto', 36, 4, '2025-04-13', NULL),
(76, 'El discurso de Juliette en el capítulo 25 es inspirador', 38, 4, '2025-04-13', NULL),
(77, 'Leer justo después de LiberaME para continuidad', 39, 4, '2025-04-13', NULL),
(78, 'Prestar atención a los nuevos poderes que aparecen', 40, 4, '2025-04-13', NULL),
(79, 'Prestar atención a las pistas ocultas a lo largo de la historia', 41, 4, '2025-04-13', NULL),
(80, 'Contenido gráfico: revisar advertencias antes de releer', 42, 5, '2025-04-13', NULL),
(81, 'Analizar la evolución de la relación principal', 43, 5, '2025-04-13', NULL),
(82, 'Tomar notas de las estrategias políticas empleadas', 44, 5, '2025-04-13', NULL),
(83, 'El epílogo es perfecto - leer con atención', 45, 5, '2025-04-13', NULL),
(84, 'Analizar la simbología religiosa en la historia', 46, 5, '2025-04-13', NULL),
(85, 'Comparar con el Peter Pan original - diferencias interesantes', 47, 5, '2025-04-13', NULL),
(86, 'El monólogo interno del Capitán es brillante - analizar', 58, 5, '2025-04-13', NULL),
(87, 'El sistema de vampirismo es original - tomar notas', 48, 5, '2025-04-13', NULL),
(88, 'Contenido sensible: revisar advertencias', 49, 5, '2025-04-13', NULL),
(89, 'buenisimo', 50, 5, '2025-04-13', NULL),
(90, 'Comparar evolución de los personajes principales', 51, 5, '2025-04-13', NULL),
(91, 'Prestar atención al desarrollo de los personajes secundarios', 52, 5, '2025-04-13', NULL),
(92, 'El epílogo es perfecto - leer con atención', 53, 5, '2025-04-13', NULL),
(93, 'Leer después de OcultaME para mejor contexto', 54, 2, '2025-04-13', NULL),
(94, 'Leer después de MuestraME para mejor contexto', 55, 2, '2025-04-13', NULL),
(95, 'Analizar la mitología del mundo creado', 56, 2, '2025-04-13', NULL),
(96, 'Contenido sensible: revisar advertencias', 57, 2, '2025-04-13', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `genre`
--

DROP TABLE IF EXISTS `genre`;
CREATE TABLE IF NOT EXISTS `genre` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `genre`
--

INSERT INTO `genre` (`id`, `name`) VALUES
(1, 'Romantasy'),
(2, 'Fantasía épica'),
(3, 'Dragones'),
(4, 'Fantasía heroica'),
(5, 'Faes'),
(6, 'Fantasía oscura'),
(7, 'Romance'),
(8, 'Fantasía'),
(9, 'Fantasía urbana'),
(10, 'New adult'),
(11, 'Fantasía juvenil'),
(12, 'Distopía'),
(13, 'Dioses'),
(14, 'Fantasía política'),
(15, 'Sistema de mágia'),
(16, 'Dark romance'),
(17, 'Thriller'),
(18, 'Poderes'),
(19, 'Ciencia ficción'),
(20, 'Circense'),
(21, 'Horror'),
(22, 'Vampiros'),
(23, 'BL'),
(24, 'Distoía'),
(25, 'Retelling'),
(26, 'Bully romance'),
(27, 'Demonios'),
(28, 'Romance contemporaneo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `phrase`
--

DROP TABLE IF EXISTS `phrase`;
CREATE TABLE IF NOT EXISTS `phrase` (
  `id` int NOT NULL AUTO_INCREMENT,
  `text` text NOT NULL,
  `id_book` int NOT NULL,
  `id_user` int NOT NULL,
  `date_added` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id_book` (`id_book`),
  KEY `id_user` (`id_user`)
) ENGINE=MyISAM AUTO_INCREMENT=97 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `phrase`
--

INSERT INTO `phrase` (`id`, `text`, `id_book`, `id_user`, `date_added`) VALUES
(1, 'A veces, la fuerza no viene de los músculos, sino de la voluntad de seguir adelante cuando todo parece perdido.', 1, 1, '2025-04-13'),
(2, 'La mayor debilidad de una persona no es la que todo el mundo ve, sino la que ella misma oculta incluso a sí misma.', 2, 1, '2025-04-13'),
(3, 'Incluso en la oscuridad, puede nacer la luz más brillante.', 3, 1, '2025-04-13'),
(4, 'El fuego que te quema es el mismo que te hace brillar.', 4, 1, '2025-04-13'),
(5, 'No eres dueña de tu destino, pero sí de cómo lo enfrentas.', 5, 1, '2025-04-13'),
(6, 'No dejes que el miedo a perder te impida jugar el juego.', 6, 1, '2025-04-13'),
(7, 'A las estrellas que escuchan, y a los sueños que están ansiosos por ser respondidos.', 7, 1, '2025-04-13'),
(8, 'Sólo puedes ser valiente cuando has tenido miedo.', 8, 1, '2025-04-13'),
(9, 'La familia no es sólo sangre, sino aquellos por los que estarías dispuesto a sangrar.', 9, 1, '2025-04-13'),
(10, 'Tú no cedas. Tú no retrocedas. Hay que ser esa chispa que enciende el fuego de la revolución.', 10, 1, '2025-04-13'),
(11, 'Incluso en la oscuridad más profunda, no olvides quién eres.', 11, 1, '2025-04-13'),
(12, 'La luz siempre encontrará la manera de abrirse paso, incluso en los lugares más oscuros.', 12, 1, '2025-04-13'),
(13, 'No eres nada hasta que decides serlo todo.', 13, 1, '2025-04-13'),
(14, 'A través del amor, todos son inmortales.', 14, 1, '2025-04-13'),
(15, 'Elige tu propio camino, incluso si tienes que arrastrarte por él.', 15, 1, '2025-04-13'),
(16, 'A veces las cosas rotas son las más fuertes, porque han tenido que aprender a sostenerse solas.', 16, 1, '2025-04-13'),
(17, 'El amor no es una debilidad, es el arma más poderosa que tenemos.', 17, 1, '2025-04-13'),
(18, 'Ser ordinario en un mundo extraordinario es el poder más peligroso de todos.', 18, 1, '2025-04-13'),
(19, 'La libertad siempre vale el precio, sin importar cuán alto sea.', 19, 1, '2025-04-13'),
(20, 'En la oscuridad es donde encontramos nuestra verdadera fuerza.', 20, 1, '2025-04-13'),
(21, 'Una reina no nace, se forja en el fuego de la adversidad.', 21, 1, '2025-04-13'),
(22, 'La esperanza es como una brasa: parece apagada, pero puede iniciar el incendio más grande.', 22, 1, '2025-04-13'),
(23, 'En la guerra no hay vencedores, sólo sobrevivientes.', 23, 1, '2025-04-13'),
(24, 'La luz más brillante a menudo nace de la oscuridad más profunda.', 24, 1, '2025-04-13'),
(25, 'El amor no borra el pasado, pero da fuerza para enfrentar el futuro.', 25, 1, '2025-04-13'),
(26, 'El fuego que nos consume es el mismo que nos fortalece.', 26, 1, '2025-04-13'),
(27, 'La supervivencia no es suficiente. Para vivir, debemos encontrar algo por lo que valga la pena morir.', 27, 1, '2025-04-13'),
(28, 'Un líder debe ver lo que es, no lo que desea que sea.', 28, 1, '2025-04-13'),
(29, 'Si no puedo ser mejor que ellos, seré mucho peor.', 29, 1, '2025-04-13'),
(30, 'El poder es mucho más fácil de adquirir que de mantener.', 30, 1, '2025-04-13'),
(31, 'El corazón no entiende de prohibiciones cuando encuentra su verdadero destino.', 31, 1, '2025-04-13'),
(32, 'Una promesa hecha con el corazón es más fuerte que cualquier cadena.', 32, 1, '2025-04-13'),
(33, 'Perteneces a mí, incluso cuando luchas contra ello.', 33, 1, '2025-04-13'),
(34, 'Incluso en la oscuridad más profunda, encontraré el camino hacia ti.', 34, 1, '2025-04-13'),
(35, 'Mi toque es letal, pero mi corazón solo quiere amar.', 35, 1, '2025-04-13'),
(36, 'No sabía que podía amarla hasta que supe que no debía.', 36, 1, '2025-04-13'),
(37, 'Ser temerario no es falta de miedo, sino valor para actuar a pesar de él.', 37, 1, '2025-04-13'),
(38, 'No soy un arma. No soy un monstruo. Soy libre.', 38, 1, '2025-04-13'),
(39, 'En sus ojos encontré el reflejo de la persona que quería ser.', 39, 1, '2025-04-13'),
(40, 'No somos lo que nos hicieron, somos lo que elegimos ser.', 40, 1, '2025-04-13'),
(41, 'Recuerda, todo en Caraval es un juego. No creas todo lo que ves.', 41, 1, '2025-04-13'),
(42, 'La esperanza es el primer paso en el camino a la decepción.', 42, 1, '2025-04-13'),
(43, 'El cautiverio no es solo de cuerpos, sino también de corazones.', 43, 1, '2025-04-13'),
(44, 'En el juego del poder, cada gesto es un movimiento calculado.', 44, 1, '2025-04-13'),
(45, 'A veces, rebelarse es la única forma de ser fiel a uno mismo.', 45, 1, '2025-04-13'),
(46, 'Incluso los ángeles más puros esconden un infierno interior.', 46, 1, '2025-04-13'),
(47, 'Las cicatrices más profundas no son las que se ven, sino las que llevamos dentro.', 47, 1, '2025-04-13'),
(48, 'No rezo a los dioses. Soy lo que los dioses temen.', 48, 1, '2025-04-13'),
(49, 'No soy un salvador. Soy el villano de tu historia.', 49, 1, '2025-04-13'),
(50, 'Los monstruos más peligrosos no son los que muestran sus garras, sino los que esconden sonrisas.', 50, 1, '2025-04-13'),
(51, 'Para gobernar un trono de monstruos, primero debes convertirte en uno.', 51, 1, '2025-04-13'),
(52, 'No estoy rota, solo reconstruida de manera diferente.', 52, 1, '2025-04-13'),
(53, 'Desafiarte a ti mismo es el acto más valiente de todos.', 53, 1, '2025-04-13'),
(54, 'Cruzaría mil mundos destruidos solo para encontrarte en uno.', 54, 1, '2025-04-13'),
(55, 'Encontrarte no fue un destino, fue mi elección constante.', 55, 1, '2025-04-13'),
(56, 'La ruina no es el fin, sino el principio de algo más poderoso.', 56, 1, '2025-04-13'),
(57, 'No me ofreciste tu alma, me entregaste tu corazón sin saberlo.', 57, 1, '2025-04-13'),
(58, 'Todos crecen, excepto aquellos que eligen perderse en el juego.', 58, 1, '2025-04-13'),
(59, 'A veces, la fuerza no viene de los músculos, sino de la voluntad de seguir adelante cuando todo parece perdido.', 1, 3, '2025-04-13'),
(60, 'La mayor debilidad de una persona no es la que todo el mundo ve, sino la que ella misma oculta incluso a sí misma.', 2, 3, '2025-04-13'),
(61, 'Incluso en la oscuridad, puede nacer la luz más brillante.', 3, 3, '2025-04-13'),
(62, 'El fuego que te quema es el mismo que te hace brillar.', 4, 3, '2025-04-13'),
(63, 'No eres dueña de tu destino, pero sí de cómo lo enfrentas.', 5, 3, '2025-04-13'),
(64, 'No dejes que el miedo a perder te impida jugar el juego.', 6, 3, '2025-04-13'),
(65, 'A las estrellas que escuchan, y a los sueños que están ansiosos por ser respondidos.', 7, 3, '2025-04-13'),
(66, 'Sólo puedes ser valiente cuando has tenido miedo.', 8, 3, '2025-04-13'),
(67, 'La familia no es sólo sangre, sino aquellos por los que estarías dispuesto a sangrar.', 9, 3, '2025-04-13'),
(68, 'Elige tu propio camino, incluso si tienes que arrastrarte por él.', 15, 3, '2025-04-13'),
(69, 'Ser ordinario en un mundo extraordinario es el poder más peligroso de todos.', 18, 3, '2025-04-13'),
(70, 'Ser temerario no es falta de miedo, sino valor para actuar a pesar de él.', 37, 3, '2025-04-13'),
(71, 'El corazón no entiende de prohibiciones cuando encuentra su verdadero destino.', 31, 3, '2025-04-13'),
(72, 'Perteneces a mí, incluso cuando luchas contra ello.', 33, 4, '2025-04-13'),
(73, 'Incluso en la oscuridad más profunda, encontraré el camino hacia ti.', 34, 4, '2025-04-13'),
(74, 'Mi toque es letal, pero mi corazón solo quiere amar.', 35, 4, '2025-04-13'),
(75, 'No sabía que podía amarla hasta que supe que no debía.', 36, 4, '2025-04-13'),
(76, 'No soy un arma. No soy un monstruo. Soy libre.', 38, 4, '2025-04-13'),
(77, 'En sus ojos encontré el reflejo de la persona que quería ser.', 39, 4, '2025-04-13'),
(78, 'No somos lo que nos hicieron, somos lo que elegimos ser.', 40, 4, '2025-04-13'),
(79, 'Recuerda, todo en Caraval es un juego. No creas todo lo que ves.', 41, 4, '2025-04-13'),
(80, 'La esperanza es el primer paso en el camino a la decepción.', 42, 5, '2025-04-13'),
(81, 'El cautiverio no es solo de cuerpos, sino también de corazones.', 43, 5, '2025-04-13'),
(82, 'En el juego del poder, cada gesto es un movimiento calculado.', 44, 5, '2025-04-13'),
(83, 'A veces, rebelarse es la única forma de ser fiel a uno mismo.', 45, 5, '2025-04-13'),
(84, 'Incluso los ángeles más puros esconden un infierno interior.', 46, 5, '2025-04-13'),
(85, 'Todos crecen, excepto aquellos que eligen perderse en el juego.', 47, 5, '2025-04-13'),
(86, 'Las cicatrices más profundas no son las que se ven, sino las que llevamos dentro.', 58, 5, '2025-04-13'),
(87, 'No rezo a los dioses. Soy lo que los dioses temen.', 48, 5, '2025-04-13'),
(88, 'No soy un salvador. Soy el villano de tu historia.', 49, 5, '2025-04-13'),
(89, 'Los monstruos más peligrosos no son los que muestran sus garras, sino los que esconden sonrisas.', 50, 5, '2025-04-13'),
(90, 'Para gobernar un trono de monstruos, primero debes convertirte en uno.', 51, 5, '2025-04-13'),
(91, 'No estoy rota, solo reconstruida de manera diferente.', 52, 5, '2025-04-13'),
(92, 'Desafiarte a ti mismo es el acto más valiente de todos.', 53, 5, '2025-04-13'),
(93, 'Cruzaría mil mundos destruidos solo para encontrarte en uno.', 54, 2, '2025-04-13'),
(94, 'Encontrarte no fue un destino, fue mi elección constante.', 55, 2, '2025-04-13'),
(95, 'La ruina no es el fin, sino el principio de algo más poderoso.', 56, 2, '2025-04-13'),
(96, 'No me ofreciste tu alma, me entregaste tu corazón sin saberlo.', 57, 2, '2025-04-13');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reading_progress`
--

DROP TABLE IF EXISTS `reading_progress`;
CREATE TABLE IF NOT EXISTS `reading_progress` (
  `id` int NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `pages` int NOT NULL,
  `id_book` int NOT NULL,
  `id_user` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id_book` (`id_book`),
  KEY `idx_user_book_date` (`id_user`,`id_book`,`date`)
) ENGINE=MyISAM AUTO_INCREMENT=193 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `reading_progress`
--

INSERT INTO `reading_progress` (`id`, `date`, `pages`, `id_book`, `id_user`) VALUES
(1, '2023-12-22', 52, 1, 1),
(2, '2023-12-23', 54, 1, 1),
(3, '2023-12-25', 101, 1, 1),
(4, '2023-12-26', 121, 1, 1),
(5, '2023-12-27', 282, 1, 1),
(6, '2023-12-28', 120, 1, 1),
(7, '2023-12-29', 25, 2, 1),
(8, '2023-12-30', 45, 2, 1),
(9, '2023-12-31', 40, 2, 1),
(10, '2024-01-01', 60, 2, 1),
(11, '2024-01-02', 116, 2, 1),
(12, '2024-01-03', 203, 2, 1),
(13, '2024-01-03', 28, 3, 1),
(14, '2024-01-04', 207, 3, 1),
(15, '2024-01-05', 265, 3, 1),
(16, '2024-01-08', 111, 4, 1),
(17, '2024-01-10', 553, 4, 1),
(18, '2024-01-10', 79, 5, 1),
(19, '2024-01-11', 354, 5, 1),
(20, '2024-01-12', 153, 5, 1),
(21, '2024-01-13', 144, 5, 1),
(22, '2024-01-14', 122, 6, 1),
(23, '2024-01-15', 170, 6, 1),
(24, '2024-01-16', 162, 6, 1),
(25, '2024-01-16', 90, 7, 1),
(26, '2024-01-17', 93, 7, 1),
(27, '2024-01-18', 233, 7, 1),
(28, '2024-01-19', 167, 7, 1),
(29, '2024-01-20', 84, 8, 1),
(30, '2024-01-21', 285, 8, 1),
(31, '2024-01-22', 172, 8, 1),
(32, '2024-01-23', 122, 8, 1),
(33, '2024-01-24', 92, 10, 1),
(34, '2024-01-25', 194, 10, 1),
(35, '2024-01-26', 25, 10, 1),
(36, '2024-01-28', 334, 10, 1),
(37, '2024-01-29', 116, 10, 1),
(38, '2024-01-29', 748, 11, 1),
(39, '2024-01-30', 85, 12, 1),
(40, '2024-01-31', 211, 12, 1),
(41, '2024-02-01', 236, 12, 1),
(42, '2024-02-02', 51, 12, 1),
(43, '2024-02-04', 62, 12, 1),
(44, '2024-02-05', 199, 12, 1),
(45, '2024-02-06', 122, 12, 1),
(46, '2024-02-08', 184, 13, 1),
(47, '2024-02-10', 292, 13, 1),
(48, '2024-02-11', 206, 13, 1),
(49, '2024-02-12', 141, 14, 1),
(50, '2024-02-13', 52, 14, 1),
(51, '2024-02-14', 51, 14, 1),
(52, '2024-02-15', 88, 14, 1),
(53, '2024-02-17', 92, 14, 1),
(54, '2024-02-18', 109, 14, 1),
(55, '2024-02-19', 160, 14, 1),
(56, '2024-02-20', 99, 14, 1),
(57, '2024-02-22', 254, 15, 1),
(58, '2024-02-23', 364, 15, 1),
(59, '2024-02-24', 199, 15, 1),
(60, '2024-02-25', 68, 15, 1),
(61, '2024-02-25', 89, 16, 1),
(62, '2024-02-26', 120, 16, 1),
(63, '2024-02-27', 35, 16, 1),
(64, '2024-02-28', 155, 16, 1),
(65, '2024-02-29', 149, 16, 1),
(66, '2024-03-01', 278, 16, 1),
(67, '2024-03-03', 164, 17, 1),
(68, '2024-03-04', 239, 17, 1),
(69, '2024-03-05', 145, 17, 1),
(70, '2024-03-06', 301, 17, 1),
(71, '2024-03-07', 303, 18, 1),
(72, '2024-03-08', 63, 18, 1),
(73, '2024-03-09', 225, 18, 1),
(74, '2024-03-11', 510, 19, 1),
(75, '2024-03-12', 153, 19, 1),
(76, '2024-03-12', 110, 20, 1),
(77, '2024-03-13', 218, 20, 1),
(78, '2024-03-14', 186, 20, 1),
(79, '2024-03-15', 279, 20, 1),
(80, '2024-03-16', 211, 21, 1),
(81, '2024-03-17', 114, 21, 1),
(82, '2024-03-18', 252, 21, 1),
(83, '2024-03-19', 217, 21, 1),
(84, '2024-03-20', 244, 22, 1),
(85, '2024-03-21', 197, 22, 1),
(86, '2024-03-22', 205, 22, 1),
(87, '2024-03-23', 94, 22, 1),
(88, '2024-03-24', 71, 22, 1),
(89, '2024-03-20', 244, 22, 1),
(90, '2024-03-21', 197, 22, 1),
(91, '2024-03-22', 205, 22, 1),
(92, '2024-03-23', 94, 22, 1),
(93, '2024-03-24', 71, 22, 1),
(94, '2024-03-25', 227, 23, 1),
(95, '2024-03-26', 196, 23, 1),
(96, '2024-03-27', 47, 23, 1),
(97, '2024-03-29', 53, 23, 1),
(98, '2024-04-01', 276, 23, 1),
(99, '2024-04-02', 120, 23, 1),
(100, '2024-04-03', 185, 24, 1),
(101, '2024-04-04', 290, 24, 1),
(102, '2024-04-05', 289, 24, 1),
(103, '2024-04-06', 113, 24, 1),
(104, '2024-04-07', 768, 25, 1),
(105, '2024-04-08', 325, 26, 1),
(106, '2024-04-09', 274, 26, 1),
(107, '2024-04-10', 156, 26, 1),
(108, '2024-04-10', 127, 27, 1),
(109, '2024-04-11', 80, 27, 1),
(110, '2024-04-12', 223, 27, 1),
(111, '2024-04-13', 145, 27, 1),
(112, '2024-04-14', 135, 27, 1),
(113, '2024-04-15', 131, 27, 1),
(114, '2024-04-17', 205, 28, 1),
(115, '2024-04-18', 80, 28, 1),
(116, '2024-04-19', 103, 28, 1),
(117, '2024-04-24', 245, 29, 1),
(118, '2024-04-25', 215, 29, 1),
(119, '2024-04-28', 179, 30, 1),
(120, '2024-04-29', 197, 30, 1),
(121, '2024-08-19', 84, 31, 1),
(122, '2024-08-20', 123, 31, 1),
(123, '2024-08-21', 133, 31, 1),
(124, '2024-08-22', 325, 32, 1),
(125, '2024-08-23', 55, 33, 1),
(126, '2024-08-24', 73, 33, 1),
(127, '2024-08-27', 78, 33, 1),
(128, '2024-08-28', 146, 33, 1),
(129, '2024-08-29', 233, 33, 1),
(130, '2024-09-01', 106, 34, 1),
(131, '2024-09-02', 254, 34, 1),
(132, '2024-09-03', 146, 34, 1),
(133, '2024-09-04', 35, 34, 1),
(134, '2024-09-05', 121, 34, 1),
(135, '2024-09-05', 128, 35, 1),
(136, '2024-09-06', 220, 35, 1),
(137, '2024-09-07', 114, 36, 1),
(138, '2024-09-08', 74, 37, 1),
(139, '2024-09-09', 362, 37, 1),
(140, '2024-09-10', 322, 38, 1),
(141, '2024-09-01', 149, 38, 1),
(142, '2024-09-12', 74, 39, 1),
(143, '2024-09-12', 210, 40, 1),
(144, '2024-09-13', 70, 40, 1),
(145, '2024-09-14', 30, 40, 1),
(146, '2024-09-15', 129, 40, 1),
(147, '2024-09-17', 124, 41, 1),
(148, '2024-09-18', 204, 41, 1),
(149, '2024-09-19', 89, 41, 1),
(150, '2024-09-20', 25, 42, 1),
(151, '2024-09-21', 71, 42, 1),
(152, '2024-09-22', 122, 42, 1),
(153, '2024-09-23', 80, 42, 1),
(154, '2024-09-24', 117, 42, 1),
(155, '2024-09-25', 288, 42, 1),
(156, '2024-09-26', 279, 42, 1),
(157, '2024-09-27', 77, 42, 1),
(158, '2024-09-28', 254, 43, 1),
(159, '2024-09-28', 70, 44, 1),
(160, '2024-09-29', 274, 44, 1),
(161, '2024-09-30', 305, 45, 1),
(162, '2024-09-30', 82, 46, 1),
(163, '2024-10-01', 182, 46, 1),
(164, '2024-10-02', 148, 46, 1),
(165, '2024-10-03', 348, 47, 1),
(166, '2024-10-04', 90, 58, 1),
(167, '2024-10-06', 128, 48, 1),
(168, '2024-10-07', 235, 48, 1),
(169, '2024-10-08', 40, 48, 1),
(170, '2024-10-09', 92, 48, 1),
(171, '2024-10-10', 310, 49, 1),
(172, '2024-10-11', 250, 49, 1),
(173, '2024-10-14', 277, 50, 1),
(174, '2024-10-15', 199, 50, 1),
(175, '2024-10-16', 228, 50, 1),
(176, '2024-10-17', 31, 50, 1),
(177, '2024-10-18', 123, 51, 1),
(178, '2024-10-15', 161, 51, 1),
(179, '2024-10-19', 160, 51, 1),
(180, '2024-10-21', 175, 52, 1),
(181, '2024-10-22', 172, 52, 1),
(182, '2024-10-22', 134, 53, 1),
(183, '2024-10-23', 149, 53, 1),
(184, '2024-10-24', 76, 54, 1),
(185, '2024-10-25', 80, 55, 1),
(186, '2024-10-29', 300, 56, 1),
(187, '2024-10-30', 139, 56, 1),
(188, '2024-11-01', 119, 56, 1),
(189, '2024-11-02', 96, 57, 1),
(190, '2024-11-04', 144, 57, 1),
(191, '2024-11-05', 100, 57, 1),
(192, '2024-11-06', 76, 57, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reading_status`
--

DROP TABLE IF EXISTS `reading_status`;
CREATE TABLE IF NOT EXISTS `reading_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `reading_status`
--

INSERT INTO `reading_status` (`id`, `name`, `description`) VALUES
(1, 'reading', 'El usuario está actualmente leyendo este libro'),
(2, 'completed', 'El usuario ha terminado de leer este libro'),
(3, 'dropped', 'El usuario ha abandonado la lectura de este libro'),
(4, 'on_hold', 'El usuario ha pausado temporalmente la lectura'),
(5, 'plan_to_read', 'El usuario planea leer este libro en el futuro');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `review`
--

DROP TABLE IF EXISTS `review`;
CREATE TABLE IF NOT EXISTS `review` (
  `id` int NOT NULL AUTO_INCREMENT,
  `text` text NOT NULL,
  `rating` decimal(5,2) DEFAULT NULL,
  `date_created` date NOT NULL,
  `id_book` int NOT NULL,
  `id_user` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id_book` (`id_book`),
  KEY `id_user` (`id_user`)
) ;

--
-- Volcado de datos para la tabla `review`
--

INSERT INTO `review` (`id`, `text`, `rating`, `date_created`, `id_book`, `id_user`) VALUES
(1, 'Una historia emocionante con personajes complejos y una trama llena de giros inesperados. La evolución de Violet es fascinante.', '8.57', '2025-04-13', 1, 1),
(2, 'Un inicio prometedor para la saga, con una protagonista fuerte y un mundo lleno de intrigas.', '7.50', '2025-04-13', 2, 1),
(3, 'La evolución de Celaena como personaje es magistral, con giros argumentales que mantienen en vilo.', '7.71', '2025-04-13', 3, 1),
(4, 'El punto de inflexión de la saga donde todo cobra mayor profundidad y complejidad.', '9.29', '2025-04-13', 4, 1),
(5, 'Intenso, emocionante y lleno de momentos épicos. La transformación de Aelin es impresionante.', '10.00', '2025-04-13', 5, 1),
(6, 'Hermosa adaptación de La Bella y la Bestia con un giro oscuro y sensual. La evolución de Feyre es fascinante.', '7.79', '2025-04-13', 6, 1),
(7, 'Mejor que el primero en todos los aspectos. Rhysand se convierte en uno de los mejores personajes de la saga.', '10.00', '2025-04-13', 7, 1),
(8, 'Conclusión emocionante de la trilogía original, con batallas épicas y momentos emocionales intensos.', '9.14', '2025-04-13', 8, 1),
(9, 'Historia corta y dulce para los fans de la saga, aunque menos sustancial que los libros principales.', '5.00', '2025-04-13', 9, 1),
(10, 'Uno de los mejores libros de la saga, con acción incesante y momentos emocionales devastadores.', '10.00', '2025-04-13', 10, 1),
(11, 'Intenso y emocional, aunque el ritmo es más lento que en libros anteriores. Los capítulos de Manon son los mejores.', '7.86', '2025-04-13', 11, 1),
(12, 'Conclusión épica y satisfactoria para la saga. Sarah J. Maas demuestra por qué es la reina del Romantasy.', '10.00', '2025-04-13', 12, 1),
(13, 'Historia de redención poderosa. Nesta se convierte en uno de los personajes más complejos del universo ACOTAR.', '8.43', '2025-04-13', 13, 1),
(14, 'Fascinante mezcla de fantasía y elementos urbanos. Bryce es una protagonista refrescante y carismática.', '9.29', '2025-04-13', 14, 1),
(15, 'Segundo libro aún mejor que el primero. La evolución de Violet y Xaden es magistral. Cliffhanger devastador.', '10.00', '2025-04-13', 15, 1),
(16, 'Expande magistralmente el mundo creado en el primer libro. La evolución de la relación Bryce-Hunt es conmovedora.', '8.71', '2025-04-13', 16, 1),
(17, 'El mejor libro de la saga hasta ahora. Conexiones inesperadas con otros universos de Maas. Final electrizante.', '10.00', '2025-04-13', 17, 1),
(18, 'Mezcla interesante de \"Los Juegos del Hambre\" y fantasía. La química entre los protagonistas es eléctrica.', '8.17', '2025-04-13', 18, 1),
(19, 'Adictivo desde la primera página. Poppy es una protagonista que evoluciona de manera fascinante.', '10.00', '2025-04-13', 19, 1),
(20, 'Segundo libro que supera al primero. Más acción, más romance y revelaciones impactantes.', '8.86', '2025-04-13', 20, 1),
(21, 'El libro más intenso de la saga hasta ahora. La evolución de Poppy como líder es impresionante.', '10.00', '2025-04-13', 21, 1),
(22, 'Expande el mundo de manera magistral. La mitología de este universo sigue sorprendiendo.', '9.29', '2025-04-13', 22, 1),
(23, 'Confrontación épica que justifica toda la saga. Escenas de batalla magistralmente escritas.', '9.64', '2025-04-13', 23, 1),
(24, 'Hermoso libro de reconstrucción emocional. La vulnerabilidad de los personajes es conmovedora.', '10.00', '2025-04-13', 24, 1),
(25, 'Conclusión satisfactoria para esta etapa de la saga. Deja el camino abierto para más historias.', '7.57', '2025-04-13', 25, 1),
(26, 'Nueva entrega que mantiene la calidad de la saga, con giros inesperados y desarrollo de personajes secundarios.', '9.21', '2025-04-13', 26, 1),
(27, 'Sistema de magia innovador y construcción de mundo excepcional, aunque el ritmo es lento al principio.', '6.36', '2025-04-13', 27, 1),
(28, 'Segundo libro que profundiza en los dilemas políticos y personajes. Plot twists magistrales.', '5.57', '2025-04-13', 28, 1),
(29, 'Protagonista femenina inteligente y estratégica. Mundo feérico oscuro y fascinante.', '8.86', '2025-04-13', 29, 1),
(30, 'Conclusión satisfactoria con giros inesperados. La evolución de Cardan es particularmente notable.', '7.93', '2025-04-13', 30, 1),
(31, 'Encantadora historia de amor con suficiente conflicto para mantener el interés. Los personajes secundarios añaden profundidad al mundo.', '8.57', '2025-04-13', 31, 1),
(32, 'Segunda parte que mantiene la magia del primero. La tensión emocional está bien lograda.', '8.71', '2025-04-13', 32, 1),
(33, 'Intenso y perturbador, pero imposible de soltar. La química entre los personajes es electrizante.', '9.21', '2025-04-13', 33, 1),
(34, 'Conclusión satisfactoria que mantiene la tensión hasta el final. Los giros argumentales son impredecibles.', '8.36', '2025-04-13', 34, 1),
(35, 'Estilo de escritura único y poético. La voz narrativa de Juliette es fresca y conmovedora.', '8.93', '2025-04-13', 35, 1),
(36, 'Fascinante ver la perspectiva de Warner. Humaniza al \"villano\" y añade capas a la historia.', '8.00', '2025-04-13', 36, 1),
(37, 'Secuela que supera al original. Más acción, más giros y desarrollo de personajes excelente.', '8.57', '2025-04-13', 37, 1),
(38, 'La evolución de Juliette es impresionante. La acción y el romance están perfectamente equilibrados.', '10.00', '2025-04-13', 38, 1),
(39, 'Pequeña joya para fans de la pareja. Escenas íntimas y emotivas bien logradas.', '7.50', '2025-04-13', 39, 1),
(40, 'Tercera parte llena de acción y revelaciones. El desarrollo del mundo es excelente.', '8.93', '2025-04-13', 40, 1),
(41, 'Mundo mágico y atmosférico con giros inesperados. La ambientación de Caraval es fascinante.', '9.43', '2025-04-13', 41, 1),
(42, 'Narrativa cruda y poderosa. Combina perfectamente fantasía oscura con elementos de horror.', '10.00', '2025-04-13', 42, 1),
(43, 'Química electrizante entre los protagonistas. Dinámica de enemigos a amantes bien ejecutada.', '7.93', '2025-04-13', 43, 1),
(44, 'Intriga política bien desarrollada. La tensión sexual aumenta de manera satisfactoria.', '7.86', '2025-04-13', 44, 1),
(45, 'Final satisfactorio con giros inesperados. La evolución de los personajes es notable.', '10.00', '2025-04-13', 45, 1),
(46, 'Mundo rico y personajes complejos. La mitología angelical está bien desarrollada.', '9.43', '2025-04-13', 46, 1),
(47, 'Mejor que el primero. La profundidad psicológica del Capitán Garfio es fascinante.', '10.00', '2025-04-13', 47, 1),
(48, 'Sistema de magia único y personajes complejos. La tensión romántica está bien construida.', '9.14', '2025-04-13', 48, 1),
(49, 'Química tóxica pero adictiva entre los protagonistas. La dinámica de poder es intrigante.', '7.43', '2025-04-13', 49, 1),
(50, 'Mundo complejo y personajes fascinantes. La química entre los protagonistas es electrizante.', '10.00', '2025-04-13', 50, 1),
(51, 'Secuela que supera al original. Más acción, más giros y mayor desarrollo de personajes.', '10.00', '2025-04-13', 51, 1),
(52, 'Evolución notable de la protagonista. La narrativa poética sigue siendo impactante.', '8.86', '2025-04-13', 52, 1),
(53, 'Conclusión emocionante de la saga principal. Satisfactoria evolución de todos los personajes.', '10.00', '2025-04-13', 53, 1),
(54, 'Perspectiva conmovedora de Warner. Añade profundidad a su personaje y a su relación con Juliette.', '7.86', '2025-04-13', 54, 1),
(55, 'Conmovedora mirada al interior de Warner. Añade profundidad emocional a su personaje.', '8.14', '2025-04-13', 55, 1),
(56, 'Química explosiva entre los protagonistas. Mundo construido de manera fascinante.', '9.21', '2025-04-13', 56, 1),
(57, 'Historia intensa con personajes complejos. La dinámica de poder está bien lograda.', '7.93', '2025-04-13', 57, 1),
(58, 'Versión adulta y retorcida del clásico cuento. La química entre los protagonistas es eléctrica.', '8.71', '2025-04-13', 58, 1),
(59, 'Una historia emocionante con personajes complejos y una trama llena de giros inesperados. La evolución de Violet es fascinante.', '8.00', '2025-04-13', 1, 3),
(60, 'Un inicio prometedor para la saga, con una protagonista fuerte y un mundo lleno de intrigas.', '7.00', '2025-04-13', 2, 3),
(61, 'La evolución de Celaena como personaje es magistral, con giros argumentales que mantienen en vilo.', '7.00', '2025-04-13', 3, 3),
(62, 'El punto de inflexión de la saga donde todo cobra mayor profundidad y complejidad.', '9.00', '2025-04-13', 4, 3),
(63, 'Intenso, emocionante y lleno de momentos épicos. La transformación de Aelin es impresionante.', '10.00', '2025-04-13', 5, 3),
(64, 'Hermosa adaptación de La Bella y la Bestia con un giro oscuro y sensual. La evolución de Feyre es fascinante.', '7.00', '2025-04-13', 6, 3),
(65, 'Mejor que el primero en todos los aspectos. Rhysand se convierte en uno de los mejores personajes de la saga.', '10.00', '2025-04-13', 7, 3),
(66, 'Conclusión emocionante de la trilogía original, con batallas épicas y momentos emocionales intensos.', '9.00', '2025-04-13', 8, 3),
(67, 'Historia corta y dulce para los fans de la saga, aunque menos sustancial que los libros principales.', '5.00', '2025-04-13', 9, 3),
(68, 'Segundo libro aún mejor que el primero. La evolución de Violet y Xaden es magistral. Cliffhanger devastador.', '10.00', '2025-04-13', 15, 3),
(69, 'Mezcla interesante de \"Los Juegos del Hambre\" y fantasía. La química entre los protagonistas es eléctrica.', '8.00', '2025-04-13', 18, 3),
(70, 'Secuela que supera al original. Más acción, más giros y desarrollo de personajes excelente.', '8.00', '2025-04-13', 37, 3),
(71, 'Encantadora historia de amor con suficiente conflicto para mantener el interés. Los personajes secundarios añaden profundidad al mundo.', '8.00', '2025-04-13', 31, 3),
(72, 'Intenso y perturbador, pero imposible de soltar. La química entre los personajes es electrizante.', '9.21', '2025-04-13', 33, 4),
(73, 'Conclusión satisfactoria que mantiene la tensión hasta el final. Los giros argumentales son impredecibles.', '8.36', '2025-04-13', 34, 4),
(74, 'Estilo de escritura único y poético. La voz narrativa de Juliette es fresca y conmovedora.', '8.93', '2025-04-13', 35, 4),
(75, 'Fascinante ver la perspectiva de Warner. Humaniza al \"villano\" y añade capas a la historia.', '8.00', '2025-04-13', 36, 4),
(76, 'La evolución de Juliette es impresionante. La acción y el romance están perfectamente equilibrados.', '10.00', '2025-04-13', 38, 4),
(77, 'Pequeña joya para fans de la pareja. Escenas íntimas y emotivas bien logradas.', '7.50', '2025-04-13', 39, 4),
(78, 'Tercera parte llena de acción y revelaciones. El desarrollo del mundo es excelente.', '8.93', '2025-04-13', 40, 4),
(79, 'Mundo mágico y atmosférico con giros inesperados. La ambientación de Caraval es fascinante.', '9.43', '2025-04-13', 41, 4),
(80, 'Narrativa cruda y poderosa. Combina perfectamente fantasía oscura con elementos de horror.', '10.00', '2025-04-13', 42, 5),
(81, 'Química electrizante entre los protagonistas. Dinámica de enemigos a amantes bien ejecutada.', '7.93', '2025-04-13', 43, 5),
(82, 'Intriga política bien desarrollada. La tensión sexual aumenta de manera satisfactoria.', '7.86', '2025-04-13', 44, 5),
(83, 'Final satisfactorio con giros inesperados. La evolución de los personajes es notable.', '10.00', '2025-04-13', 45, 5),
(84, 'Mundo rico y personajes complejos. La mitología angelical está bien desarrollada.', '9.43', '2025-04-13', 46, 5),
(85, 'Versión adulta y retorcida del clásico cuento. La química entre los protagonistas es eléctrica.', '8.71', '2025-04-13', 47, 5),
(86, 'Mejor que el primero. La profundidad psicológica del Capitán Garfio es fascinante.', '10.00', '2025-04-13', 58, 5),
(87, 'Sistema de magia único y personajes complejos. La tensión romántica está bien construida.', '9.14', '2025-04-13', 48, 5),
(88, 'Química tóxica pero adictiva entre los protagonistas. La dinámica de poder es intrigante.', '7.43', '2025-04-13', 49, 5),
(89, 'Mundo complejo y personajes fascinantes. La química entre los protagonistas es electrizante.', '10.00', '2025-04-13', 50, 5),
(90, 'Secuela que supera al original. Más acción, más giros y mayor desarrollo de personajes.', '10.00', '2025-04-13', 51, 5),
(91, 'Evolución notable de la protagonista. La narrativa poética sigue siendo impactante.', '8.86', '2025-04-13', 52, 5),
(92, 'Conclusión emocionante de la saga principal. Satisfactoria evolución de todos los personajes.', '10.00', '2025-04-13', 53, 5),
(93, 'Perspectiva conmovedora de Warner. Añade profundidad a su personaje y a su relación con Juliette.', '7.86', '2025-04-13', 54, 2),
(94, 'Conmovedora mirada al interior de Warner. Añade profundidad emocional a su personaje.', '8.14', '2025-04-13', 55, 2),
(95, 'Química explosiva entre los protagonistas. Mundo construido de manera fascinante.', '9.21', '2025-04-13', 56, 2),
(96, 'Historia intensa con personajes complejos. La dinámica de poder está bien lograda.', '7.93', '2025-04-13', 57, 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `saga`
--

DROP TABLE IF EXISTS `saga`;
CREATE TABLE IF NOT EXISTS `saga` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `saga`
--

INSERT INTO `saga` (`id`, `name`) VALUES
(1, 'Empíreo'),
(2, 'Trono de cristal'),
(3, 'Una corte de rosas y espinas'),
(4, 'Ciudad medialuna'),
(5, 'Powerless'),
(6, 'De sangre y cenizas'),
(7, 'Nacidos de la bruma'),
(8, 'Habitantes del aire'),
(9, 'Crónicas de Hiraia'),
(10, 'Hunting Adeline'),
(11, 'Shatter Me'),
(12, 'Caraval'),
(13, 'El imperio del vampiro'),
(14, 'El príncipe cautivo'),
(15, 'La caída del cielo'),
(16, 'Historia de Nunca Jamás'),
(17, 'Crowns of Nyaxia'),
(18, 'Legado de dioses'),
(19, 'Dioses y monstruos'),
(20, 'Una perdición de ruina y furia'),
(21, 'Alma'),
(22, 'Twisted'),
(23, 'Pecados'),
(24, 'La caída lunar'),
(25, 'Los juegos de los dioses');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `synopsis`
--

DROP TABLE IF EXISTS `synopsis`;
CREATE TABLE IF NOT EXISTS `synopsis` (
  `id` int NOT NULL AUTO_INCREMENT,
  `text` text NOT NULL,
  `id_book` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_book` (`id_book`)
) ENGINE=MyISAM AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `synopsis`
--

INSERT INTO `synopsis` (`id`, `text`, `id_book`) VALUES
(1, 'En un mundo al borde de la guerra, Violet Sorrengail, una joven que debería haber ingresado en el Cuerpo de Escribas, es obligada a unirse a los jinetes de dragones, una élite de guerreros que montan dragones. Violet debe sobrevivir al brutal entrenamiento y a las traiciones mientras descubre secretos que podrían cambiar el curso de la guerra.', 1),
(2, 'En las tenebrosas minas de sal de Endovier, una muchacha de dieciocho años cumple cadena perpetua. Es una asesina profesional, la mejor en lo suyo, pero ha cometido un error fatal. La han capturado. El joven capitán Westfall le ofrece un trato: la libertad a cambio de un enorme sacrificio.', 2),
(3, 'Celaena Sardothien, la asesina más temida de Adarlan, ha sobrevivido a las pruebas del Rey de los Asesinos, pero a un alto costo. Ahora, debe decidir cuánto está dispuesta a sacrificar por su gente y por aquellos a quienes ama.', 3),
(4, 'Celaena ha sobrevivido a pruebas mortales, pero ahora se enfrenta a su destino. Mientras el reino se desmorona, deberá elegir entre su legado y su corazón, entre la venganza y la redención.', 4),
(5, 'Celaena Sardothien ha aceptado su identidad como Aelin Galathynius, reina de Terrasen. Pero antes de reclamar su trono, debe liberar a su pueblo de la tiranía del rey de Adarlan.', 5),
(6, 'Feyre, una cazadora, mata a un lobo en el bosque y una bestia monstruosa exige una compensación. Arrastrada a un reino mágico, descubre que su captor no es una bestia, sino Tamlin, un Alto Señor del mundo de las hadas. Mientras Feyre habita en su corte, una antigua y siniestra sombra crece sobre el reino, y deberá luchar para salvar a Tamlin y su pueblo.', 6),
(7, 'Feyre ha superado la prueba de Amarantha, pero a un alto costo. Ahora debe aprender a vivir con sus decisiones y descubrir su lugar en el mundo de las hadas mientras una guerra se avecina.', 7),
(8, 'La guerra se acerca y Feyre debe unir a los Alta Corte y al mortal mundo para enfrentarse al Rey Hybern. Mientras tanto, descubre secretos sobre su propia familia y poder.', 8),
(9, 'Una historia navideña ambientada en el mundo de ACOTAR, donde Feyre y Rhysand organizan una celebración invernal en la Corte de la Noche.', 9),
(10, 'Aelin Galathynius se enfrenta a su destino final mientras prepara a su reino para la batalla contra Erawan. Mientras tanto, Manon Blackbeak debe tomar decisiones que cambiarán el curso de la guerra.', 10),
(11, 'Aelin Galathynius ha sido capturada por la Reina Maeve y su destino pende de un hilo. Mientras tanto, sus aliados se dispersan por el mundo tratando de reunir fuerzas para la batalla final contra Erawan.', 11),
(12, 'La batalla final ha llegado. Aelin y sus aliados deben unirse para enfrentarse a Erawan y Maeve en un conflicto que decidirá el destino de su mundo.', 12),
(13, 'Nesta Archeron, ahora sumida en la autodestrucción, es llevada a la Casa del Viento por Cassian y Azriel. Allí deberá enfrentar sus demonios mientras una nueva amenaza surge en las montañas.', 13),
(14, 'Bryce Quinlan, una medio-hada que trabaja en una galería de arte, investiga una serie de asesinatos junto al cazador de recompensas Hunt Athalar en la vibrante ciudad de Lunathion.', 14),
(15, 'Violet Sorrengail continúa su entrenamiento como jinete de dragones mientras la guerra se intensifica. Los secretos sobre su familia y el conflicto comienzan a revelarse.', 15),
(16, 'Bryce Quinlan y Hunt Athalar intentan recuperar la normalidad después de los eventos traumáticos, pero nuevas amenazas emergen en la ciudad de Lunathion mientras descubren secretos sobre su mundo y sus propias conexiones.', 16),
(17, 'Bryce se encuentra en un mundo desconocido mientras sus amigos en Lunathion luchan por sobrevivir a las consecuencias de sus acciones. Todos deberán enfrentar desafíos inimaginables para reunirse nuevamente.', 17),
(18, 'En un mundo donde algunos nacen con poderes y otros no, Paedyn Gray, una Ordinaria, se ve obligada a competir en los Juegos Purging para demostrar su valía, mientras oculta su verdadera naturaleza.', 18),
(19, 'Poppy está destinada a ser la Doncella, guardada para los dioses hasta el día de su Ascensión. Pero cuando es asignada a su nuevo guardián, Hawke, comienza a cuestionar todo lo que le han enseñado.', 19),
(20, 'Poppy ha descubierto la verdad sobre su destino y ahora debe navegar por un mundo de mentiras y traiciones mientras su relación con Casteel se profundiza y los peligros aumentan.', 20),
(21, 'Poppy y Casteel enfrentan nuevas amenazas mientras intentan unificar a su pueblo contra el verdadero enemigo. Los secretos del pasado resurgen y las alianzas se ponen a prueba.', 21),
(22, 'Mientras la guerra se intensifica, Poppy debe viajar a tierras desconocidas para encontrar aliados inesperados. Misterios ancestrales salen a la luz, cambiando todo lo que creían saber.', 22),
(23, 'El conflicto entre Poppy y la Reina Isbeth llega a su punto culminante en una batalla épica que decidirá el destino de los reinos. Las pérdidas serán inevitables.', 23),
(24, 'Después de los eventos traumáticos de la guerra, Poppy y Casteel deben reconstruir su relación y su reino, mientras una nueva amenaza surge en el horizonte.', 24),
(25, 'Poppy y Casteel enfrentan su desafío más personal mientras luchan por mantener la paz recién ganada. Secretos familiares salen a la luz, cambiando todo lo que creían saber sobre sus orígenes.', 25),
(26, 'La historia continúa explorando las consecuencias de las revelaciones finales, con los personajes enfrentando nuevos desafíos personales y políticos en un mundo cambiante.', 26),
(27, 'En un mundo donde el sol rojo brilla sin descanso y las cenizas caen como nieve, un joven ladrón descubre que posee poderes únicos que podrían cambiar el destino de su opresivo mundo.', 27),
(28, 'Después de derrocar al Lord Legislador, Vin y Elend deben gobernar un imperio fracturado mientras nuevas amenazas emergen de las sombras.', 28),
(29, 'Jude, una mortal criada en la Corte Feérica, debe aprender a sobrevivir en un mundo de engaños y peligros, donde su mayor enemigo podría ser el irresistible príncipe Cardan.', 29),
(30, 'Jude se encuentra atrapada en un juego peligroso de poder y traición, donde debe decidir entre su ambición y su corazón, mientras el reino se balancea al borde de la guerra.', 30),
(31, 'Una historia de amor prohibido entre dos almas destinadas a estar juntas pero separadas por las circunstancias. La química entre los protagonistas es palpable desde el primer encuentro.', 31),
(32, 'Las consecuencias del amor prohibido se hacen presentes mientras los protagonistas luchan por mantener sus promesas en un mundo que se opone a su unión.', 32),
(33, 'Una historia oscura de obsesión y amor peligroso que explora los límites de la posesión y el consentimiento en una relación tóxica pero fascinante.', 33),
(34, 'La persecución continúa en esta segunda parte, donde los roles se invierten y la cazadora se convierte en la presa, en un juego psicológico de atracción y peligro.', 34),
(35, 'En un mundo distópico, Juliette posee un toque mortal y ha sido recluida toda su vida, hasta que un día es liberada por un misterioso soldado que parece inmune a su poder.', 35),
(36, 'Una historia corta desde la perspectiva de Warner que revela sus pensamientos y sentimientos durante los eventos del primer libro, dando profundidad a este complejo personaje.', 36),
(37, 'Paedyn Gray enfrenta nuevas amenazas mientras navega por las consecuencias de los Juegos Purging. Los secretos salen a la luz y las lealtades son puestas a prueba.', 37),
(38, 'Juliette ha tomado el control de su poder y de su vida, pero el mundo fuera de los muros de la Sector 45 es más peligroso de lo que imaginaba.', 38),
(39, 'Breve historia que explora momentos clave entre Warner y Juliette, dando mayor profundidad a su compleja relación durante los eventos del segundo libro.', 39),
(40, 'Juliette debe unir fuerzas con aliados inesperados para enfrentar la creciente amenaza del Restablecimiento, mientras descubre la verdadera extensión de sus poderes.', 40),
(41, 'Scarlett Dragna siempre ha soñado con asistir a Caraval, el espectáculo itinerante donde la audiencia participa en el show. Cuando finalmente recibe una invitación, su hermana Tella es secuestrada por el maestro del espectáculo, y Scarlett debe encontrar a su hermana antes de que termine el juego.', 41),
(42, 'En un mundo donde el sol ha muerto y los vampiros gobiernan, Gabriel de León, el último miembro de una orden de cazadores de vampiros, es capturado y obligado a contar su historia a la reina vampira.', 42),
(43, 'Un príncipe es capturado por una reina guerrera y debe aprender a navegar por la corte de su captora mientras planea su escape, pero lo que comienza como odio podría convertirse en algo más.', 43),
(44, 'El príncipe continúa su juego peligroso en la corte, donde las líneas entre aliados y enemigos se difuminan y cada movimiento podría ser su último.', 44),
(45, 'La conclusión de la trilogía donde las lealtades son puestas a prueba y el príncipe debe decidir entre su deber y su corazón en una batalla final por el poder.', 45),
(46, 'Una historia oscura de ángeles caídos y demonios donde los límites entre el bien y el mal se difuminan, y el amor puede ser la mayor condena o la salvación.', 46),
(47, 'Una reinterpretación oscura de Peter Pan donde James Garber es un empresario despiadado y Wendy Darling una ladrona que roba su reloj, iniciando un juego peligroso de atracción y venganza.', 47),
(48, 'En un mundo de vampiros y dioses oscuros, una humana se ve atrapada en un torneo mortal donde su mayor enemigo podría ser su única salvación.', 48),
(49, 'Killian es el dios de la malicia en una universidad donde los hijos de las familias mafiosas juegan a ser dioses. Glyndon es la única que parece inmune a su encanto, convirtiéndose en su obsesión.', 49),
(50, 'En un mundo donde dioses y monstruos libran una guerra eterna, una asesina mortal se alía con el enemigo más peligroso para evitar el fin del mundo.', 50),
(51, 'Segunda parte de la saga donde las alianzas se prueban y los secretos salen a la luz, mientras el mundo se balancea al borde de la destrucción total.', 51),
(52, 'Juliette Ferrars ha regresado con un nuevo propósito y un ejército de aliados inesperados, lista para enfrentarse al Restablecimiento de una vez por todas.', 52),
(53, 'La batalla final se acerca y Juliette debe tomar decisiones imposibles que determinarán el futuro de su mundo y de todos los que ama.', 53),
(54, 'Una historia corta que sigue a Warner mientras busca a Juliette después de los eventos de \"OcultaME\", revelando sus pensamientos más íntimos y su determinación inquebrantable.', 54),
(55, 'Una historia corta desde la perspectiva de Warner que revela sus pensamientos más íntimos mientras busca a Juliette después de los eventos de \"MuestraME\".', 55),
(56, 'Raine se ve atrapada en un juego peligroso con el Príncipe de la Perdición, donde la línea entre el odio y la atracción se difumina cada vez más.', 56),
(57, 'En un pacto demoníaco, un alma humana es ofrecida como sacrificio, pero lo que comienza como un contrato se convierte en una conexión inesperada.', 57),
(58, 'Segunda parte de la saga oscura de Nunca Jamás, centrada en el Capitán Garfio y su obsesión por una mujer que podría ser su perdición o su redención.', 58),
(59, 'Aunque Sera se ha liberado de las garras de Kolis y ha regresado con sus seres queridos, no todo está en calma. Los recuerdos todavía la atormentan, pero Sera, por fin, tiene esperanza en un futuro con la otra mitad de su corazón y de su alma. Nyktos desea, ama y acepta todas las partes de ella... incluso las más monstruosas.', 59),
(60, 'Alexei Volkov solo tiene una regla: nunca involucrarse emocionalmente. Frío, calculador y centrado exclusivamente en su carrera, ha construido una vida perfectamente ordenada hasta que su hermana le pide un favor imposible de rechazar: cuidar de su compañera de piso, Ava Chen, mientras ella está fuera.', 60),
(61, 'Rhys Larsen vive por un solo propósito: proteger a la princesa Bridget von Ascheberg como su guardaespaldas personal. Disciplinado, profesional y absolutamente dedicado a su deber, Rhys ha mantenido sus sentimientos bajo un férreo control durante años. Bridget, heredera del trono de Eldora, ha pasado su vida siguiendo las expectativas reales y sacrificando sus deseos personales por el bien de su país.', 61),
(62, 'Dante Russo, despiadado magnate de bienes raíces y heredero del imperio Russo, vive consumido por la venganza. Cuando un matrimonio arreglado con Vivian Lau, heredera de una dinastía hotelera rival, se convierte en su realidad, Dante ve la oportunidad perfecta para destruir a la familia que arruinó a la suya. ', 62),
(63, 'Christian Archibald, CEO implacable y la personificación del orgullo, ha construido su imperio mediante decisiones despiadadas y una convicción inquebrantable en su propia superioridad. Cuando Delilah Kim, una brillante diseñadora de videojuegos y su némesis profesional, regresa a su vida, Christian se ve obligado a enfrentar el único fracaso de su pasado: haberla dejado ir.', 63),
(64, 'Julian Alesandro, multimillonario despiadado y tercer miembro de los infames Reyes de Manhattan, vive por una sola regla: siempre querer más. Cuando Elise Moore, la brillante pero reticente heredera del imperio mediático Moore, cruza su camino, Julian inmediatamente la añade a su lista de adquisiciones.', 64),
(65, 'Gabriel de León ha perdido la oportunidad de acabar con la noche sin fin. Ahora, embarcado en una incierta alianza con una vampira, se propone recurrir a la enigmática estirpe Esani para averiguar cómo deshacer la muerte de los días… Por más que a los lobos no les inquieten los males de los gusanos. Perseguido por la estirpe Voss, arrastrado a letales contiendas en las gélidas Tierras Altas y destrozado por su propia sed de sangre, el último santo de plata sabe que quizá no sobreviva lo suficiente para presenciar cómo alguien muy importante para él descubre la verdad.', 65),
(66, 'Paedyn Gray estaba lista para recibir una sentencia de muerte, no un compromiso. Despues de matar al rey, casarse con su hijo Kitt era lo ultimo que ella y el pueblo hubiesen esperado. Pero, como reina, Paedyn tendrá la oportunidad de unir Ilya y crear un reino donde los vulgares vivan sin miedo.', 66),
(67, '«Los Creadores jamás esperaron que sus queridos dragones, al llegar su fin, ascendieran a los cielos. Tampoco que se enroscaran en forma de esfera allá donde la gravedad no podía alcanzarlos y llenaran el firmamento de tumbas... De lunas. Y, desde luego, jamás esperaronque cayeran». Como asesina rebelde, el objetivo de Raeve es cumplir su misión y que jamás la atrapen. Sin embargo, cuando un cazarrecompensas rival hace añicos su realidad, la joven se ve prisionera del Gremio de Nobles, una organización de elementales poderosos que pretenden dar ejemplo con ella. Solo la muerte podrá liberarla.', 67),
(68, 'Tras casi dieciocho meses en el Colegio de Guerra Basgiath, Violet Sorrengail tiene claro que no queda tiempo para entrenar. Hay que tomar decisiones. La batalla ha comenzado y, con enemigos acercándose a las murallas e infiltrados en sus propias filas, es imposible saber en quién confiar. Ahora Violet deberá emprender un viaje fuera de los límites de Aretia, en busca de aliados de tierras desconocidas que acepten pelear por Navarre. La misión pondrá a prueba su suerte, y la obligará a usar todo su ingenio y fortaleza para salvar lo que más ama: sus dragones, su familia, su hogar y a él.', 68),
(69, 'Después de sobrevivir a Caraval, Donatella Dragna se encuentra nuevamente envuelta en un peligroso juego. Ha hecho un trato con un misterioso criminal: descubrir la verdadera identidad de Legend, el maestro de Caraval, a cambio de información sobre su madre desaparecida. Mientras un nuevo Caraval comienza, Tella se sumerge en un mundo de magia oscura, secretos familiares y amores prohibidos.', 69),
(70, 'En el épico cierre de la trilogía Caraval, las hermanas Dragna enfrentan su desafío final. Mientras Legend prepara su coronación como emperador, fuerzas antiguas despiertan amenazando el destino del imperio. Tella y Scarlett deben decidir si confiar en Legend o luchar contra él, mientras ambas navegan entre complicadas relaciones amorosas y descubrimientos sobre su propia herencia mágica.', 70),
(71, 'En este spin-off del universo Caraval, una joven ilusionista con un oscuro pasado es invitada a participar en Spectaculaire, un místico y exclusivo espectáculo de magia que ocurre solo una vez cada cien años. Con la promesa de un deseo que puede cambiar su destino, se adentra en un mundo de ilusiones deslumbrantes, competidores letales y secretos ancestrales. A medida que los concursantes empiezan a desaparecer misteriosamente, descubre que hay magia real entre los trucos y que algunas leyendas esconden terribles verdades.', 71),
(72, 'Evangeline Fox siempre ha creído en finales felices, hasta que descubre que el amor de su vida se casará con otra. Desesperada, hace un trato con el Príncipe del Corazón Roto, un Destino inmortal y misterioso: detener la boda a cambio de tres besos que ella le dará cuando él los reclame. Pero los tratos con los Destinos nunca son simples, y pronto Evangeline se encuentra atrapada en un laberinto de secretos mágicos, maldiciones ancestrales y peligrosas verdades. En un mundo donde los cuentos de hadas cobran vida, Evangeline descubrirá que conseguir su \"felices para siempre\" podría costarle más de lo que jamás imaginó.', 72),
(73, 'Tras los eventos de \"Érase un Corazón Roto\", Evangeline Fox continúa su peligrosa alianza con el Príncipe del Corazón Roto para encontrar la magia perdida que podría romper una maldición ancestral. Atrapada entre mentiras y verdades a medias, Evangeline se adentra en un mundo de artefactos mágicos, palacios encantados y secretos largamente enterrados. Mientras su corazón se debate entre la desconfianza y una creciente atracción hacia el enigmático Destino, Evangeline deberá determinar si los motivos del Príncipe son sinceros o parte de un plan más siniestro. Con cada paso que da, descubre que los cuentos de hadas que tanto amaba esconden oscuridades que nunca imaginó.', 73),
(74, 'Evangeline Fox viajó al Glorioso Norte buscando su «felices para siempre» y parece que lo ha conseguido: está casada con un atractivo príncipe y vive en un castillo legendario. Pero no tiene ni idea del devastador precio que ha pagado por ese cuento de hadas. Desconoce lo que ha perdido y su marido va a asegurarse de que no lo descubra nunca. pero antes debe matar a Jacks, el Príncipe de Corazones.', 74),
(75, 'Lyra Keres es la mujer más solitaria de San Francisco. Cuando hace veintitrés años a su madre se le rompieron las aguas en el mismo templo de Zeus, el dios lanzó una maldición sobre la recién nacida: nunca sería amada. Entregada por sus padres a la Orden de los Ladrones cuando era niña, Lyra creció sin familia, sin amigos y sin siquiera saber su verdadero nombre. Pero ella está harta de esta maldición, harta de la ira de Zeus. Por eso, en la noche de apertura de la Prueba, la competición que los dioses celebran cada cien años para decidir quién será el rey del Olimpo, ella se dirige al templo de Zeus, decidida a causar estragos. Sin embargo, cuando llega allí, termina encontrando… a Hades.', 75),
(76, 'Lyra Keres es la mujer más solitaria de San Francisco. Cuando hace veintitrés años a su madre se le rompieron las aguas en el mismo templo de Zeus, el dios lanzó una maldición sobre la recién nacida: nunca sería amada. Entregada por sus padres a la Orden de los Ladrones cuando era niña, Lyra creció sin familia, sin amigos y sin siquiera saber su verdadero nombre. Pero ella está harta de esta maldición, harta de la ira de Zeus. Por eso, en la noche de apertura de la Prueba, la competición que los dioses celebran cada cien años para decidir quién será el rey del Olimpo, ella se dirige al templo de Zeus, decidida a causar estragos. Sin embargo, cuando llega allí, termina encontrando… a Hades.', 76),
(77, '\"La Reina de Nada\" concluye la historia de Jude Duarte, una mortal criada en el mundo de las hadas, y su complicada relación con Cardan, el Rey Supremo de Elfhame. En este libro final, Jude debe regresar al reino de las hadas después de haber sido exiliada por Cardan, enfrentarse a nuevas amenazas políticas y resolver definitivamente su relación con el rey de las hadas.', 77);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE IF NOT EXISTS `user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `last_name1` varchar(100) DEFAULT NULL,
  `last_name2` varchar(100) DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  `union_date` date NOT NULL,
  `nickName` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `id_role` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nickName` (`nickName`),
  KEY `id_role` (`id_role`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `user`
--

INSERT INTO `user` (`id`, `name`, `last_name1`, `last_name2`, `birthdate`, `union_date`, `nickName`, `password`, `id_role`) VALUES
(1, 'Jose Ayrton', 'Rosell', 'Bonavina', '2000-08-06', '2024-03-30', 'joss0102', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', 1),
(2, 'David', 'Fernandez', 'Valbuena', '2003-08-06', '2024-03-30', 'DavidFdz', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', 1),
(3, 'Dumi', 'Tomas', '', '2002-09-14', '2024-03-30', 'dumitxmss', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', 2),
(4, 'Isabel', 'Isidro', 'Fernandez', '2002-04-18', '2024-03-30', 'issafeez', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', 2),
(5, 'Helio', 'Rebato', 'Gamez', '2002-07-25', '2024-03-30', 'heliiovk_', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user_book_description`
--

DROP TABLE IF EXISTS `user_book_description`;
CREATE TABLE IF NOT EXISTS `user_book_description` (
  `id_user` int NOT NULL,
  `id_book` int NOT NULL,
  `custom_description` text NOT NULL,
  PRIMARY KEY (`id_user`,`id_book`),
  KEY `id_book` (`id_book`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `user_book_description`
--

INSERT INTO `user_book_description` (`id_user`, `id_book`, `custom_description`) VALUES
(1, 1, 'Me encantó la evolución de Violet y su relación con los otros reclutas. La construcción del mundo de los dragones es fascinante y los giros argumentales me mantuvieron en vilo.'),
(1, 2, 'Una protagonista fuerte e ingeniosa. Lo que más me gustó fue el equilibrio entre las intrigas de palacio y los elementos de fantasía que van creciendo en importancia conforme avanza la historia.'),
(1, 3, 'Me sorprendió positivamente cómo este libro expande el universo y profundiza en los personajes. La trama de la competición está bien ejecutada y hay momentos muy tensos.'),
(1, 4, 'El punto de inflexión de la saga. La introducción de nuevos personajes como Rowan y Manon añade nuevas dimensiones a la historia. La evolución de Celaena/Aelin es perfecta.'),
(1, 5, 'El desarrollo de Aelin como líder es fascinante. Las escenas de acción son espectaculares y la forma en que se entrelazan las diferentes tramas es magistral. La química entre Aelin y Rowan es electrizante.'),
(1, 6, 'Una reinvención fascinante de La Bella y la Bestia. El mundo feérico está construido de manera original y los personajes tienen profundidad. El giro final de la trama me dejó sin palabras.'),
(1, 7, 'El mejor libro de la saga. La forma en que Maas desarrolla la relación entre Feyre y Rhysand es magistral. La Corte de la Noche es simplemente fascinante y la expansión del mundo es perfecta.'),
(1, 8, 'Una conclusión épica para la trilogía principal. Las batallas son impresionantes y el desarrollo de todos los personajes secundarios es notable. El Círculo Íntimo se ha convertido en uno de mis grupos de personajes favoritos.'),
(1, 9, 'Una historia ligera pero encantadora que muestra momentos cotidianos del Círculo Íntimo. Ideal para fans que quieren más interacciones entre los personajes favoritos sin grandes amenazas.'),
(1, 10, 'Uno de mis favoritos de la saga. Las escenas de batalla son épicas y el desarrollo de Manon es especialmente notable. Este libro me hizo llorar varias veces.'),
(1, 11, 'Este libro utiliza múltiples perspectivas de manera magistral. El sufrimiento de Aelin es desgarrador y la forma en que sus aliados luchan por encontrarla es emocionante. Manon sigue robándose cada escena.'),
(1, 12, 'Una conclusión épica para una de las mejores sagas de fantasía. Las batallas son impresionantes, los momentos emocionales son profundos y el cierre de todos los arcos argumentales es satisfactorio. El epílogo es perfecto.'),
(1, 13, 'Una historia de redención poderosa. El desarrollo de Nesta desde un personaje difícil de querer hasta una heroína compleja es brillante. Su romance con Cassian tiene la tensión perfecta y las escenas de entrenamiento son adictivas.'),
(1, 14, 'Una vuelta de tuerca a la fantasía urbana con toques de misterio y noir. Bryce es una protagonista diferente a las anteriores de SJM, con un enfoque más moderno. El worldbuilding es impresionante y los personajes secundarios son memorables.'),
(1, 15, 'Aún mejor que el primero. La evolución de Violet es perfecta y su relación con Xaden se profundiza de manera natural. Los giros argumentales son impactantes y el cliffhanger final es devastador. No podía dejar de leerlo.'),
(1, 16, 'Una secuela que expande el universo de manera magistral. La evolución de la relación entre Bryce y Hunt es conmovedora, y los nuevos elementos mitológicos añaden capas a la historia. Las conexiones con otros universos de Maas son fascinantes.'),
(1, 17, 'El mejor libro de la saga hasta ahora. Las conexiones entre los diferentes universos de Maas son brillantes y las revelaciones sobre los orígenes de los mundos son fascinantes. El final es electrizante y abre posibilidades infinitas.'),
(1, 18, 'Una mezcla interesante de Los Juegos del Hambre con elementos de X-Men. La premisa es original y la protagonista es carismática. La química entre los personajes principales es palpable desde el principio y los giros argumentales mantienen el interés.'),
(1, 19, 'Una protagonista que evoluciona desde la sumisión a la fuerza de forma natural. El giro en la trama a mitad del libro es impactante y cambia completamente la dirección de la historia. El romance es adictivo y el worldbuilding detallado.'),
(1, 20, 'Un segundo libro que supera al primero. La evolución de Poppy hacia su verdadero potencial es fascinante y su química con Casteel se profundiza. El worldbuilding se expande de manera natural y los nuevos personajes son carismáticos.'),
(1, 21, 'El libro más intenso de la saga hasta ahora. La evolución de Poppy como líder es impresionante y las revelaciones sobre su pasado cambian todo. La relación con Casteel continúa desarrollándose de manera natural y los personajes secundarios brillan.'),
(1, 22, 'Este libro expande el mundo de manera magistral. La mitología se profundiza y los nuevos personajes añaden dimensiones interesantes. Las revelaciones sobre los dioses y los Atlantianos son fascinantes y cambian completamente la perspectiva de la saga.'),
(1, 23, 'Confrontación épica que justifica toda la construcción previa. Las escenas de batalla están magníficamente escritas y el desarrollo de los poderes de Poppy alcanza nuevas alturas. Los momentos emocionales son devastadores y las pérdidas se sienten reales.'),
(1, 24, 'Un libro de reconstrucción emocional que muestra las secuelas psicológicas de la guerra. La vulnerabilidad de los personajes es conmovedora y la forma en que enfrentan sus traumas es realista. Una nueva etapa para la saga que profundiza en aspectos más íntimos.'),
(1, 25, 'Conclusión satisfactoria para esta etapa de la saga. Las revelaciones sobre los orígenes de Poppy y Casteel recontextualizan toda la historia. Los momentos íntimos entre la pareja son emotivos y el camino queda abierto para más aventuras.'),
(1, 26, 'Una nueva entrega que mantiene la calidad de la saga. Los personajes secundarios ganan protagonismo y se desarrollan de manera satisfactoria. Los nuevos poderes que se manifiestan abren posibilidades interesantes para futuras tramas.'),
(1, 27, 'El sistema de magia de la alomancia es uno de los más innovadores y bien construidos que he leído. Sanderson crea un mundo distópico fascinante con reglas coherentes. El ritmo es algo lento al principio pero la recompensa vale la pena.'),
(1, 28, 'Un segundo libro que profundiza en los dilemas políticos y morales. La evolución de Vin y Elend como líderes es fascinante, y los nuevos aspectos del sistema de magia que se revelan expanden el mundo de manera lógica. Los giros finales son impactantes.'),
(1, 29, 'Una protagonista fascinante que utiliza su ingenio para sobrevivir en un mundo donde está en desventaja. La Corte Feérica es oscura y peligrosa, y las intrigas políticas están bien desarrolladas. La relación con Cardan es complicada y adictiva.'),
(1, 30, 'Conclusión perfecta para la historia de Jude y Cardan. Los giros políticos son inesperados y la evolución de ambos personajes principales es notable. La forma en que se resuelven los conflictos es satisfactoria sin ser predecible.'),
(1, 31, 'Una historia de amor con suficiente conflicto para mantener el interés. El mundo fantástico está bien construido y los personajes secundarios añaden profundidad. La química entre los protagonistas es creíble desde el primer momento.'),
(1, 32, 'Segunda parte que mantiene la magia del primero. La tensión emocional está bien lograda y los obstáculos que enfrentan los protagonistas son creíbles. La evolución de su relación es natural y emotiva.'),
(1, 33, 'Intenso y perturbador, pero imposible de soltar. Explora temas oscuros de obsesión y los límites borrosos del consentimiento. La química entre los personajes es electrizante y la narrativa te mantiene en tensión constante.'),
(1, 34, 'Una continuación que mantiene la intensidad del primero. Los roles invertidos añaden una dimensión interesante a la dinámica entre los protagonistas. Los giros argumentales son impredecibles y el ritmo no decae en ningún momento.'),
(1, 35, 'El estilo de escritura poético y experimental hace que esta historia destaque. Juliette es una protagonista compleja con un poder fascinante. La construcción del mundo distópico es inquietante y la evolución de la protagonista es notable.'),
(1, 36, 'Una perspectiva fascinante que humaniza al aparente villano. Ver los eventos a través de los ojos de Warner añade capas a la historia principal y recontextualiza muchas de sus acciones. Imprescindible para entender completamente al personaje.'),
(1, 37, 'Secuela que supera al original. La evolución de Paedyn es excelente y los nuevos giros en la trama mantienen el interés. La acción está bien equilibrada con el desarrollo de personajes y las revelaciones sobre el sistema de poderes son fascinantes.'),
(1, 38, 'La evolución de Juliette desde una chica asustada a una mujer que toma el control de su vida es impresionante. La acción y el romance están perfectamente equilibrados, y las nuevas amenazas mantienen la tensión narrativa. El estilo poético sigue siendo cautivador.'),
(1, 39, 'Pequeña joya para los fans de la pareja. Las escenas íntimas y emotivas están bien logradas y añaden contexto importante a la evolución de su relación. La perspectiva de Warner siempre es fascinante y compleja.'),
(1, 40, 'Tercera parte llena de acción y revelaciones. El desarrollo del mundo y del sistema de poderes es excelente. Las alianzas inesperadas añaden dinamismo a la trama y la evolución de Juliette alcanza nuevas dimensiones fascinantes.'),
(1, 41, 'Un mundo mágico y atmosférico con giros inesperados. La ambientación de Caraval es fascinante y te sumerge completamente en este espectáculo mágico. Las reglas del juego mantienen la tensión y nunca sabes qué es real y qué es parte del espectáculo.'),
(1, 42, 'Narrativa cruda y poderosa que combina perfectamente fantasía oscura con elementos de horror. La construcción del mundo post-apocalíptico dominado por vampiros es inquietante y fascinante. Los personajes son complejos y la narrativa no rehúye los aspectos más oscuros.'),
(1, 43, 'Química electrizante entre los protagonistas. La dinámica de enemigos a amantes está bien ejecutada y la tensión política añade capas a la historia. El worldbuilding es sólido y los personajes tienen profundidad psicológica.'),
(1, 44, 'Intriga política bien desarrollada. La tensión sexual entre los protagonistas aumenta de manera satisfactoria mientras navegan por las traiciones y alianzas de la corte. Las estrategias políticas son fascinantes y la evolución de la relación principal es creíble.'),
(1, 45, 'Final satisfactorio con giros inesperados. La evolución de los personajes llega a su culminación natural y la resolución de los conflictos políticos y personales está bien equilibrada. El epílogo cierra perfectamente la historia.'),
(1, 46, 'Mundo rico y personajes complejos. La mitología angelical está bien desarrollada y la forma en que explora las líneas difusas entre lo correcto y lo incorrecto es fascinante. La simbología religiosa está integrada de manera inteligente en la trama.'),
(1, 47, 'Versión adulta y retorcida del clásico cuento. La química entre los protagonistas es eléctrica y los guiños al material original son inteligentes. Un thriller romántico oscuro con giros inesperados que mantienen el interés.'),
(1, 48, 'Sistema de magia único y personajes complejos. La tensión romántica está bien construida y el sistema de vampirismo es original. El torneo mantiene la tensión narrativa y los giros políticos añaden complejidad.'),
(1, 49, 'Química tóxica pero adictiva entre los protagonistas. La dinámica de poder es intrigante y el ambiente universitario con elementos de mafia resulta original. La evolución de la relación desde el antagonismo es fascinante.'),
(1, 50, 'Mundo complejo y personajes fascinantes. La química entre los protagonistas es electrizante y la mitología creada es sorprendentemente original. La evolución de la relación desde enemigos mortales a aliados y más allá es creíble.'),
(1, 51, 'Secuela que supera al original. Más acción, más giros y mayor desarrollo de personajes. La evolución de los protagonistas es consistente y las nuevas amenazas elevan la tensión. La mitología se expande de forma coherente.'),
(1, 52, 'Evolución notable de la protagonista. La narrativa poética sigue siendo impactante y el desarrollo de los personajes secundarios añade profundidad a la historia. La trama política se vuelve más compleja y fascinante.'),
(1, 53, 'Conclusión emocionante de la saga principal. Satisfactoria evolución de todos los personajes y resolución de los conflictos principales. El epílogo cierra perfectamente los arcos narrativos iniciados en el primer libro.'),
(1, 54, 'Perspectiva conmovedora de Warner. Añade profundidad a su personaje y a su relación con Juliette. Ver su vulnerabilidad y determinación desde su punto de vista enriquece enormemente la historia principal.'),
(1, 55, 'Conmovedora mirada al interior de Warner. Añade profundidad emocional a su personaje y muestra su evolución a lo largo de la saga. Su dedicación y amor por Juliette son palpables en cada página.'),
(1, 56, 'Química explosiva entre los protagonistas. Mundo construido de manera fascinante con una mitología original. La dinámica entre los personajes principales evoluciona de forma creíble y la tensión romántica es adictiva.'),
(1, 57, 'Historia intensa con personajes complejos. La dinámica de poder está bien lograda y la evolución desde un contrato frío a una conexión emocional es creíble. Los elementos sobrenaturales están bien integrados en la trama.'),
(1, 58, 'Mejor que el primero. La profundidad psicológica del Capitán Garfio es fascinante y su monólogo interno revela capas de complejidad inesperadas. La reinterpretación del personaje clásico es original y convincente.'),
(3, 1, 'Una fascinante exploración de la resiliencia y la transformación personal, donde Violet debe desafiar sus propios límites y expectativas para sobrevivir en un mundo brutalmente competitivo de jinetes de dragones. La novela combina elementos de fantasía épica con un intenso desarrollo de personajes.'),
(3, 2, 'Una obra maestra de la fantasía que desafía los arquetipos tradicionales, presentando a una protagonista compleja y moralmente ambigua. La novela explora temas de libertad, redención y el peso de la identidad en un mundo de intrigas políticas y magia ancestral.'),
(3, 3, 'Un viaje profundo de desarrollo personal y conflicto moral, donde la protagonista se enfrenta a las consecuencias de sus acciones pasadas y los dilemas éticos de su profesión. La novela profundiza en la complejidad de la lealtad, el sacrificio y la búsqueda de un propósito más allá de la muerte.'),
(3, 4, 'Un punto de inflexión extraordinario en la saga que explora la transformación personal más profunda. La novela desafía las nociones de destino y elección, presentando a una protagonista que debe reconciliar sus múltiples identidades y encontrar su verdadero propósito en medio del caos y la destrucción.'),
(3, 5, 'Una narración épica de empoderamiento y liderazgo, donde la protagonista transforma su identidad de asesina a reina, enfrentando no solo desafíos externos, sino también internos. La novela examina el peso de la responsabilidad, el poder de la autodeterminación y el significado de liderar con compasión y estrategia.'),
(3, 6, 'Una reinterpretación moderna y oscura del clásico cuento de La Bella y la Bestia, que profundiza en los temas de transformación personal, sacrificio y el poder del amor para trascender las apariencias. La novela explora la evolución de Feyre desde una cazadora de supervivencia hasta una heroína compleja, desafiando las expectativas de género y poder.'),
(3, 7, 'Una exploración magistral de la recuperación, el empoderamiento y la superación del trauma. La novela desafía las estructuras de poder existentes, presentando una protagonista que se reconstruye a sí misma y encuentra su verdadera fuerza en la vulnerabilidad y la resistencia.'),
(3, 8, 'Una épica exploración de la unidad, el liderazgo y el sacrificio colectivo. La novela profundiza en la complejidad de las alianzas políticas, los costos de la guerra y la transformación de una heroína de víctima a estratega, presentando un análisis matizado de poder, resistencia y esperanza.'),
(3, 9, 'Un breve pero emotivo interludio que profundiza en la intimidad y el desarrollo de los personajes más allá de las grandes batallas. La novela ofrece una mirada íntima a la construcción de la familia, la comunidad y la paz después de la guerra, destacando que la verdadera fortaleza reside en los momentos de conexión y celebración.'),
(3, 10, 'Una narrativa compleja que explora los límites de la lealtad, el sacrificio y la redención. La novela entrelaza múltiples hilos narrativos, presentando personajes que deben elegir entre sus lealtades personales y el bien mayor, en un mundo al borde del colapso.'),
(3, 11, 'Un punto álgido de tensión narrativa que explora los límites de la resistencia humana y la esperanza. La novela profundiza en el concepto de sacrificio, mostrando cómo los personajes encuentran su verdadera fortaleza en los momentos más oscuros y desesperados.'),
(3, 15, 'Una profunda exploración de la superación personal y el poder de la determinación. La novela desafía las expectativas de género y capacidad, mostrando cómo la verdadera fuerza proviene de la voluntad interior, la adaptabilidad y el coraje de seguir adelante incluso cuando todo parece imposible.'),
(3, 18, 'Una narrativa innovadora que desafía los tropos de los libros de poderes, centrándose en la lucha de una protagonista sin habilidades especiales en un mundo que valora el poder extraordinario. La novela explora temas de supervivencia, identidad y el verdadero significado de la fortaleza más allá de los dones sobrenaturales.'),
(3, 37, 'Una exploración fascinante de la evolución personal en un mundo de conflicto y revelaciones. La novela profundiza en cómo las experiencias transforman a los individuos, desafiando las nociones preconcebidas de poder, lealtad y supervivencia.'),
(3, 31, 'Una narrativa romántica que explora los límites del amor más allá de las convenciones sociales. La novela desafía las nociones de destino y libre albedrío, presentando una historia de conexión profunda que trasciende las barreras impuestas por la sociedad y las circunstancias.'),
(4, 33, 'Una exploración psicológicamente compleja de los límites entre amor, obsesión y poder. La novela desafía las nociones convencionales de relaciones románticas, presentando una narrativa que examina los aspectos más oscuros de la conexión humana y la vulnerabilidad.'),
(4, 34, 'Una narrativa de poder y transformación que desafía las dinámicas tradicionales de perseguidor y perseguido. La novela explora los límites de la identidad, el control y la resistencia, presentando un juego psicológico complejo donde los roles de víctima y agresor se difuminan constantemente.'),
(4, 35, 'Una metafórica exploración de la opresión, la identidad y la liberación personal. La novela utiliza la metáfora del poder destructivo como una alegoría de la marginación social, presentando una protagonista que debe reconciliar su trauma con su potencial de autodeterminación.'),
(4, 36, 'Un interludio narrativo que profundiza en la complejidad psicológica de un personaje tradicionalmente visto como antagonista. La novela corta desafía las nociones simplistas de buenos y malos, presentando una mirada íntima a las motivaciones y vulnerabilidades internas.'),
(4, 38, 'Una narrativa de empoderamiento y autodescubrimiento que desafía las estructuras de control y opresión. La novela explora cómo la verdadera liberación viene de la comprensión y aceptación de uno mismo, más allá de los límites físicos o sociales impuestos.'),
(4, 39, 'Un breve pero intenso análisis de la intimidad y la conexión más allá de las apariencias externas. La novela corta descompone las barreras entre vulnerabilidad y fortaleza, presentando una mirada íntima a la construcción de la conexión emocional.'),
(4, 40, 'Una narrativa de transformación colectiva que explora cómo el poder individual se multiplica a través de la unidad y la comprensión mutua. La novela desafía las nociones de heroísmo solitario, presentando una historia de crecimiento conjunto y resistencia compartida.'),
(4, 41, 'Una exploración mágica de los límites entre realidad y fantasía, donde el juego se convierte en una metáfora de la vida misma. La novela desafía las percepciones del lector, presentando un mundo donde la línea entre lo real y lo imaginario se difumina constantemente.'),
(5, 42, 'Una narrativa oscura y profunda que explora los conceptos de supervivencia, moralidad y el significado de la humanidad en un mundo post-apocalíptico. La novela desafía las nociones tradicionales de héroe y villano, presentando un universo donde las líneas entre la luz y la oscuridad se desdibujan constantemente.'),
(5, 43, 'Una exploración magistral de las dinámicas de poder, vulnerabilidad y transformación personal. La novela desafía las nociones tradicionales de romance y sumisión, presentando una relación compleja que se desarrolla más allá de las expectativas iniciales.'),
(5, 44, 'Una intrincada danza política que explora los matices del poder, la manipulación y la supervivencia. La novela presenta un mundo donde cada interacción es un movimiento estratégico, desafiando las nociones simplistas de bien y mal.'),
(5, 45, 'Una culminación épica que examina los conflictos internos entre la obligación personal y el deseo individual. La novela desafía las estructuras de poder establecidas, presentando una narrativa de autodeterminación y transformación política.'),
(5, 46, 'Una exploración profunda de la moralidad y la redención, que desafía las nociones tradicionales de bondad y maldad. La novela presenta un mundo donde la complejidad de la naturaleza espiritual se revela a través de personajes que trascienden las etiquetas simplistas de ángel o demonio.'),
(5, 47, 'Una reimaginación audaz que descompone los mitos clásicos, presentando una narrativa que explora los conceptos de poder, deseo y transformación personal. La novela desafía las nociones tradicionales de los cuentos de hadas, ofreciendo una visión más compleja y adulta de la identidad y el conflicto.'),
(5, 58, 'Una exploración psicológicamente compleja de la redención, la obsesión y la transformación personal. La novela desafía las nociones tradicionales de heroísmo y villanía, presentando un personaje multidimensional cuyas cicatrices internas son tan profundas como las externas.'),
(5, 48, 'Una narrativa que desafía las jerarquías tradicionales de poder, explorando cómo la vulnerabilidad puede convertirse en la mayor fortaleza. La novela presenta un mundo complejo donde las líneas entre predador y presa, entre divinidad y mortalidad, se desdibujan constantemente.'),
(5, 49, 'Una exploración profunda de las dinámicas de poder, atracción y resistencia en un escenario académico extraordinario. La novela desafía las nociones tradicionales de romance y sumisión, presentando una relación compleja que se desarrolla más allá de las expectativas iniciales.'),
(5, 50, 'Una narrativa épica que descompone las nociones tradicionales de bien y mal, presentando un mundo donde la supervivencia y la alianza superan las etiquetas morales simplistas. La novela explora cómo los individuos pueden trascender sus roles predeterminados para enfrentar amenazas mayores.'),
(5, 51, 'Una exploración profunda de la naturaleza de los conflictos y las alianzas en un mundo de dioses y monstruos. La novela desafía las nociones preconcebidas de heroísmo y maldad, presentando personajes que navegan por las zonas grises de la moralidad y el poder.'),
(5, 52, 'Una narrativa de resiliencia y transformación personal que explora cómo los individuos pueden reconstruirse después de la opresión. La novela desafía las nociones de víctima y poder, presentando un viaje de autodescubrimiento y resistencia colectiva.'),
(5, 53, 'Una culminación épica que explora los límites del sacrificio personal y la resistencia colectiva. La novela desafía las nociones de heroísmo individual, presentando una narrativa donde la verdadera fuerza proviene de la conexión y la solidaridad.'),
(2, 54, 'Un breve pero intenso análisis de la conexión emocional más allá de las circunstancias externas. La novela corta descompone las barreras entre vulnerabilidad y fortaleza, presentando una mirada íntima a la búsqueda del amor en medio del caos.'),
(2, 55, 'Un interludio narrativo que profundiza en la complejidad psicológica de un personaje tradicionalmente visto como periférico. La novela corta desafía las nociones simplistas de amor y búsqueda, presentando una mirada íntima a la determinación y la conexión emocional.'),
(2, 56, 'Una exploración magistral de las dinámicas de poder, vulnerabilidad y transformación personal. La novela desafía las nociones tradicionales de romance y sumisión, presentando una relación compleja que se desarrolla más allá de las expectativas iniciales.'),
(2, 57, 'Una exploración profunda de los límites entre el sacrificio y la conexión personal, desafiando las nociones tradicionales de libre albedrío y destino. La novela presenta un mundo donde los contratos sobrenaturales se convierten en metáforas de las relaciones humanas más complejas.');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user_has_book`
--

DROP TABLE IF EXISTS `user_has_book`;
CREATE TABLE IF NOT EXISTS `user_has_book` (
  `id_user` int NOT NULL,
  `id_book` int NOT NULL,
  `id_status` int NOT NULL,
  `date_added` date NOT NULL,
  `date_start` date DEFAULT NULL,
  `date_ending` date DEFAULT NULL,
  PRIMARY KEY (`id_user`,`id_book`),
  KEY `id_book` (`id_book`),
  KEY `id_status` (`id_status`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `user_has_book`
--

INSERT INTO `user_has_book` (`id_user`, `id_book`, `id_status`, `date_added`, `date_start`, `date_ending`) VALUES
(1, 1, 2, '2025-03-30', '2023-12-22', '2024-01-03'),
(1, 2, 2, '2025-03-30', '2023-12-29', '2024-01-05'),
(1, 3, 2, '2025-03-30', '2024-01-03', '2024-01-10'),
(1, 4, 2, '2025-03-30', '2024-01-08', '2024-01-13'),
(1, 5, 2, '2025-03-30', '2024-01-10', '2024-01-16'),
(1, 6, 2, '2025-03-30', '2024-01-14', '2024-01-19'),
(1, 7, 2, '2025-03-30', '2024-01-16', '2024-01-23'),
(1, 8, 2, '2025-03-30', '2024-01-20', '2024-01-23'),
(1, 9, 2, '2025-03-30', '2024-01-23', '2024-01-29'),
(1, 10, 2, '2025-03-30', '2024-01-24', '2024-01-29'),
(1, 11, 2, '2025-03-30', '2024-01-24', '2024-02-06'),
(1, 12, 2, '2025-03-30', '2024-01-30', '2024-02-11'),
(1, 13, 2, '2025-03-30', '2024-02-08', '2024-02-20'),
(1, 14, 2, '2025-03-30', '2024-02-12', '2024-02-25'),
(1, 15, 2, '2025-03-30', '2024-02-22', '2024-03-01'),
(1, 16, 2, '2025-03-30', '2024-02-25', '2024-03-07'),
(1, 17, 2, '2025-03-30', '2024-03-03', '2024-03-09'),
(1, 18, 2, '2025-03-30', '2024-03-07', '2024-03-12'),
(1, 19, 2, '2025-03-30', '2024-03-10', '2024-03-15'),
(1, 20, 2, '2025-03-30', '2024-03-12', '2024-03-19'),
(1, 21, 2, '2025-03-30', '2024-03-16', '2024-03-24'),
(1, 22, 2, '2025-03-30', '2024-03-20', '2024-04-02'),
(1, 23, 2, '2025-03-30', '2024-03-25', '2024-04-06'),
(1, 24, 2, '2025-03-30', '2024-04-03', '2024-04-07'),
(1, 25, 2, '2025-03-30', '2024-04-07', '2024-04-10'),
(1, 26, 2, '2025-03-30', '2024-04-08', '2024-04-15'),
(1, 27, 2, '2025-03-30', '2024-04-10', '2024-04-23'),
(1, 28, 1, '2025-03-30', '2024-04-17', '2024-04-25'),
(1, 29, 2, '2025-03-30', '2024-04-24', '2024-04-29'),
(1, 30, 2, '2025-03-30', '2024-04-28', '2024-08-21'),
(1, 31, 2, '2025-03-30', '2024-08-19', '2024-08-22'),
(1, 32, 2, '2025-03-30', '2024-08-22', '2024-08-29'),
(1, 33, 2, '2025-03-30', '2024-08-23', '2024-09-04'),
(1, 34, 2, '2025-03-30', '2024-09-01', '2024-09-06'),
(1, 35, 2, '2025-03-30', '2024-09-05', '2024-09-07'),
(1, 36, 2, '2025-03-30', '2024-09-07', '2024-09-09'),
(1, 37, 2, '2025-03-30', '2024-09-08', '2024-09-11'),
(1, 38, 2, '2025-03-30', '2024-09-10', '2024-09-12'),
(1, 39, 2, '2025-03-30', '2024-09-12', '2024-09-15'),
(1, 40, 2, '2025-03-30', '2024-09-12', '2024-09-19'),
(1, 41, 2, '2025-03-30', '2024-09-17', '2024-09-27'),
(1, 42, 2, '2025-03-30', '2024-09-20', '2024-09-28'),
(1, 43, 2, '2025-03-30', '2024-09-28', '2024-09-29'),
(1, 44, 2, '2025-03-30', '2024-09-28', '2024-09-30'),
(1, 45, 2, '2025-03-30', '2024-09-30', '2024-10-02'),
(1, 46, 2, '2025-03-30', '2024-09-30', '2024-10-03'),
(1, 47, 2, '2025-03-30', '2024-10-04', '2024-10-09'),
(1, 48, 2, '2025-03-30', '2024-10-06', '2024-10-11'),
(1, 49, 2, '2025-03-30', '2024-10-17', '2024-10-21'),
(1, 50, 2, '2025-03-30', '2024-10-17', '2024-10-20'),
(1, 51, 2, '2025-03-30', '2024-10-20', '2024-10-22'),
(1, 52, 2, '2025-03-30', '2024-10-22', '2024-10-23'),
(1, 53, 2, '2025-03-30', '2024-10-23', '2024-10-24'),
(1, 54, 2, '2025-03-30', '2024-10-24', '2024-10-24'),
(1, 55, 2, '2025-03-30', '2024-10-24', '2024-10-24'),
(1, 56, 2, '2025-03-30', '2024-10-29', '2024-11-01'),
(1, 57, 2, '2025-03-30', '2024-11-01', '2024-11-06'),
(1, 58, 2, '2025-03-30', '2024-10-03', '2024-10-05'),
(3, 1, 2, '2025-03-30', '2024-03-22', '2024-04-03'),
(3, 2, 2, '2025-03-30', '2024-03-22', '2024-04-03'),
(3, 3, 2, '2025-03-30', '2024-06-03', '2024-06-10'),
(3, 4, 2, '2025-03-30', '2024-06-08', '2024-06-13'),
(3, 5, 2, '2025-03-30', '2024-06-10', '2024-06-16'),
(3, 6, 2, '2025-03-30', '2024-06-14', '2024-06-19'),
(3, 7, 2, '2025-03-30', '2024-06-16', '2024-06-23'),
(3, 8, 2, '2025-03-30', '2024-06-20', '2024-06-23'),
(3, 9, 2, '2025-03-30', '2024-06-23', '2024-06-29'),
(3, 10, 1, '2025-03-30', '2024-06-24', NULL),
(3, 11, 1, '2025-03-30', '2024-06-24', NULL),
(3, 15, 2, '2025-03-30', '2024-05-02', '2024-05-03'),
(3, 18, 2, '2025-03-30', '2024-07-07', '2024-07-12'),
(3, 37, 2, '2025-03-30', '2024-07-13', '2024-07-16'),
(3, 31, 2, '2025-03-30', '2024-09-19', '2024-09-22'),
(3, 32, 4, '2025-03-30', NULL, NULL),
(4, 33, 2, '2025-03-30', '2024-08-23', '2024-09-04'),
(4, 34, 2, '2025-03-30', '2024-09-01', '2024-09-06'),
(4, 35, 2, '2025-03-30', '2024-09-05', '2024-09-07'),
(4, 36, 2, '2025-03-30', '2024-09-07', '2024-09-09'),
(4, 38, 2, '2025-03-30', '2024-09-10', '2024-09-12'),
(4, 39, 2, '2025-03-30', '2024-09-12', '2024-09-15'),
(4, 40, 2, '2025-03-30', '2024-09-12', '2024-09-19'),
(4, 41, 2, '2025-03-30', '2024-09-17', '2024-09-27'),
(5, 42, 2, '2025-03-30', '2024-09-20', '2024-09-28'),
(5, 43, 2, '2025-03-30', '2024-09-28', '2024-09-29'),
(5, 44, 2, '2025-03-30', '2024-09-28', '2024-09-30'),
(5, 45, 2, '2025-03-30', '2024-09-30', '2024-10-02'),
(5, 46, 2, '2025-03-30', '2024-09-30', '2024-10-03'),
(5, 47, 2, '2025-03-30', '2024-10-03', '2024-10-05'),
(5, 58, 2, '2025-03-30', '2024-10-04', '2024-10-09'),
(5, 48, 2, '2025-03-30', '2024-10-06', '2024-10-11'),
(5, 49, 2, '2025-03-30', '2024-10-17', '2024-10-21'),
(5, 50, 2, '2025-03-30', '2024-10-17', '2024-10-20'),
(5, 51, 2, '2025-03-30', '2024-10-20', '2024-10-22'),
(5, 52, 2, '2025-03-30', '2024-10-22', '2024-10-23'),
(5, 53, 2, '2025-03-30', '2024-10-23', '2024-10-24'),
(2, 54, 2, '2025-03-30', '2024-10-24', '2024-10-24'),
(2, 55, 2, '2025-03-30', '2024-10-24', '2024-10-24'),
(2, 56, 2, '2025-03-30', '2024-10-29', '2024-11-01'),
(2, 57, 2, '2025-03-30', '2024-11-01', '2024-11-06'),
(1, 59, 4, '2025-04-12', NULL, NULL),
(1, 60, 4, '2025-04-12', NULL, NULL),
(1, 61, 4, '2025-04-12', NULL, NULL),
(1, 62, 4, '2025-04-12', NULL, NULL),
(1, 63, 4, '2025-04-12', NULL, NULL),
(1, 64, 4, '2025-04-12', NULL, NULL),
(1, 65, 4, '2025-04-12', NULL, NULL),
(1, 66, 4, '2025-04-12', NULL, NULL),
(1, 67, 4, '2025-04-12', NULL, NULL),
(1, 68, 4, '2025-04-12', NULL, NULL),
(1, 69, 4, '2025-04-12', NULL, NULL),
(1, 70, 4, '2025-04-12', NULL, NULL),
(1, 71, 4, '2025-04-12', NULL, NULL),
(1, 72, 4, '2025-04-12', NULL, NULL),
(1, 73, 4, '2025-04-12', NULL, NULL),
(1, 74, 4, '2025-04-12', NULL, NULL),
(1, 75, 4, '2025-04-12', NULL, NULL),
(1, 76, 4, '2025-04-12', NULL, NULL),
(1, 77, 3, '2025-03-30', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user_role`
--

DROP TABLE IF EXISTS `user_role`;
CREATE TABLE IF NOT EXISTS `user_role` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `user_role`
--

INSERT INTO `user_role` (`id`, `name`) VALUES
(1, 'admin'),
(2, 'client');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_book_complete_info`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `vw_book_complete_info`;
CREATE TABLE IF NOT EXISTS `vw_book_complete_info` (
`authors` text
,`book_id` int
,`book_pages` int
,`book_title` varchar(255)
,`genres` text
,`sagas` text
,`synopsis` text
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_book_reviews`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `vw_book_reviews`;
CREATE TABLE IF NOT EXISTS `vw_book_reviews` (
`authors` text
,`book_id` int
,`book_title` varchar(255)
,`genres` text
,`rating` decimal(5,2)
,`review_date` date
,`review_id` int
,`review_text` text
,`user_full_name` varchar(302)
,`user_id` int
,`user_nickname` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_reading_progress_detailed`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `vw_reading_progress_detailed`;
CREATE TABLE IF NOT EXISTS `vw_reading_progress_detailed` (
`book_id` int
,`book_title` varchar(255)
,`cumulative_pages_read` decimal(32,0)
,`cumulative_progress_percentage` decimal(38,2)
,`current_reading_status` varchar(50)
,`pages_read_session` int
,`progress_id` int
,`reading_date` date
,`total_pages` int
,`user_id` int
,`user_nickname` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_user_reading_info`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `vw_user_reading_info`;
CREATE TABLE IF NOT EXISTS `vw_user_reading_info` (
`book_id` int
,`book_title` varchar(255)
,`custom_description` text
,`date_added` date
,`date_ending` date
,`date_start` date
,`pages_read` decimal(32,0)
,`progress_percentage` decimal(38,2)
,`reading_status` varchar(50)
,`status_description` varchar(255)
,`total_pages` int
,`user_id` int
,`user_last_name1` varchar(100)
,`user_last_name2` varchar(100)
,`user_name` varchar(100)
,`user_nickname` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_user_reading_stats`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `vw_user_reading_stats`;
CREATE TABLE IF NOT EXISTS `vw_user_reading_stats` (
`average_rating` decimal(6,2)
,`avg_pages_per_day` decimal(35,2)
,`avg_reading_days_per_book` decimal(12,4)
,`completed_books` decimal(23,0)
,`dropped_books` decimal(23,0)
,`favorite_author` varchar(302)
,`favorite_genre` varchar(100)
,`on_hold_books` decimal(23,0)
,`planned_books` decimal(23,0)
,`reading_books` decimal(23,0)
,`total_books` bigint
,`total_pages_all_books` decimal(32,0)
,`total_pages_read_completed` decimal(32,0)
,`total_pages_read_sessions` decimal(32,0)
,`user_full_name` varchar(302)
,`user_id` int
,`user_nickname` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_book_complete_info`
--
DROP TABLE IF EXISTS `vw_book_complete_info`;

DROP VIEW IF EXISTS `vw_book_complete_info`;
CREATE ALGORITHM=UNDEFINED DEFINER=`Lectoria`@`localhost` SQL SECURITY DEFINER VIEW `vw_book_complete_info`  AS SELECT `b`.`id` AS `book_id`, `b`.`title` AS `book_title`, `b`.`pages` AS `book_pages`, `s`.`text` AS `synopsis`, group_concat(distinct concat(`a`.`name`,' ',coalesce(`a`.`last_name1`,''),' ',coalesce(`a`.`last_name2`,'')) separator ', ') AS `authors`, group_concat(distinct `g`.`name` separator ', ') AS `genres`, group_concat(distinct `sg`.`name` separator ', ') AS `sagas` FROM (((((((`book` `b` left join `synopsis` `s` on((`b`.`id` = `s`.`id_book`))) left join `book_has_author` `bha` on((`b`.`id` = `bha`.`id_book`))) left join `author` `a` on((`bha`.`id_author` = `a`.`id`))) left join `book_has_genre` `bhg` on((`b`.`id` = `bhg`.`id_book`))) left join `genre` `g` on((`bhg`.`id_genre` = `g`.`id`))) left join `book_has_saga` `bhs` on((`b`.`id` = `bhs`.`id_book`))) left join `saga` `sg` on((`bhs`.`id_saga` = `sg`.`id`))) GROUP BY `b`.`id`, `b`.`title`, `b`.`pages`, `s`.`text`  ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_book_reviews`
--
DROP TABLE IF EXISTS `vw_book_reviews`;

DROP VIEW IF EXISTS `vw_book_reviews`;
CREATE ALGORITHM=UNDEFINED DEFINER=`Lectoria`@`localhost` SQL SECURITY DEFINER VIEW `vw_book_reviews`  AS SELECT `r`.`id` AS `review_id`, `b`.`id` AS `book_id`, `b`.`title` AS `book_title`, `u`.`id` AS `user_id`, `u`.`nickName` AS `user_nickname`, concat(`u`.`name`,' ',coalesce(`u`.`last_name1`,''),' ',coalesce(`u`.`last_name2`,'')) AS `user_full_name`, `r`.`text` AS `review_text`, `r`.`rating` AS `rating`, `r`.`date_created` AS `review_date`, group_concat(distinct concat(`a`.`name`,' ',coalesce(`a`.`last_name1`,''),' ',coalesce(`a`.`last_name2`,'')) separator ', ') AS `authors`, group_concat(distinct `g`.`name` separator ', ') AS `genres` FROM ((((((`review` `r` join `book` `b` on((`r`.`id_book` = `b`.`id`))) join `user` `u` on((`r`.`id_user` = `u`.`id`))) left join `book_has_author` `bha` on((`b`.`id` = `bha`.`id_book`))) left join `author` `a` on((`bha`.`id_author` = `a`.`id`))) left join `book_has_genre` `bhg` on((`b`.`id` = `bhg`.`id_book`))) left join `genre` `g` on((`bhg`.`id_genre` = `g`.`id`))) GROUP BY `r`.`id`, `b`.`id`, `b`.`title`, `u`.`id`, `u`.`nickName`, `user_full_name`, `r`.`text`, `r`.`rating`, `r`.`date_created`  ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_reading_progress_detailed`
--
DROP TABLE IF EXISTS `vw_reading_progress_detailed`;

DROP VIEW IF EXISTS `vw_reading_progress_detailed`;
CREATE ALGORITHM=UNDEFINED DEFINER=`Lectoria`@`localhost` SQL SECURITY DEFINER VIEW `vw_reading_progress_detailed`  AS SELECT `u`.`id` AS `user_id`, `u`.`nickName` AS `user_nickname`, `b`.`id` AS `book_id`, `b`.`title` AS `book_title`, `b`.`pages` AS `total_pages`, `rp`.`id` AS `progress_id`, `rp`.`date` AS `reading_date`, `rp`.`pages` AS `pages_read_session`, (select sum(`reading_progress`.`pages`) from `reading_progress` where ((`reading_progress`.`id_user` = `u`.`id`) and (`reading_progress`.`id_book` = `b`.`id`) and (`reading_progress`.`date` <= `rp`.`date`))) AS `cumulative_pages_read`, (case when (`b`.`pages` > 0) then round((((select sum(`reading_progress`.`pages`) from `reading_progress` where ((`reading_progress`.`id_user` = `u`.`id`) and (`reading_progress`.`id_book` = `b`.`id`) and (`reading_progress`.`date` <= `rp`.`date`))) / `b`.`pages`) * 100),2) else 0 end) AS `cumulative_progress_percentage`, `rs`.`name` AS `current_reading_status` FROM ((((`reading_progress` `rp` join `user` `u` on((`rp`.`id_user` = `u`.`id`))) join `book` `b` on((`rp`.`id_book` = `b`.`id`))) join `user_has_book` `uhb` on(((`u`.`id` = `uhb`.`id_user`) and (`b`.`id` = `uhb`.`id_book`)))) join `reading_status` `rs` on((`uhb`.`id_status` = `rs`.`id`))) ORDER BY `u`.`id` ASC, `b`.`id` ASC, `rp`.`date` ASC  ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_user_reading_info`
--
DROP TABLE IF EXISTS `vw_user_reading_info`;

DROP VIEW IF EXISTS `vw_user_reading_info`;
CREATE ALGORITHM=UNDEFINED DEFINER=`Lectoria`@`localhost` SQL SECURITY DEFINER VIEW `vw_user_reading_info`  AS SELECT `u`.`id` AS `user_id`, `u`.`name` AS `user_name`, `u`.`last_name1` AS `user_last_name1`, `u`.`last_name2` AS `user_last_name2`, `u`.`nickName` AS `user_nickname`, `b`.`id` AS `book_id`, `b`.`title` AS `book_title`, `b`.`pages` AS `total_pages`, `rs`.`name` AS `reading_status`, `rs`.`description` AS `status_description`, `uhb`.`date_added` AS `date_added`, `uhb`.`date_start` AS `date_start`, `uhb`.`date_ending` AS `date_ending`, coalesce(sum(`rp`.`pages`),0) AS `pages_read`, (case when (`b`.`pages` > 0) then round(((coalesce(sum(`rp`.`pages`),0) / `b`.`pages`) * 100),2) else 0 end) AS `progress_percentage`, `ubd`.`custom_description` AS `custom_description` FROM (((((`user` `u` join `user_has_book` `uhb` on((`u`.`id` = `uhb`.`id_user`))) join `book` `b` on((`uhb`.`id_book` = `b`.`id`))) join `reading_status` `rs` on((`uhb`.`id_status` = `rs`.`id`))) left join `reading_progress` `rp` on(((`u`.`id` = `rp`.`id_user`) and (`b`.`id` = `rp`.`id_book`)))) left join `user_book_description` `ubd` on(((`u`.`id` = `ubd`.`id_user`) and (`b`.`id` = `ubd`.`id_book`)))) GROUP BY `u`.`id`, `u`.`name`, `u`.`last_name1`, `u`.`last_name2`, `u`.`nickName`, `b`.`id`, `b`.`title`, `b`.`pages`, `rs`.`name`, `rs`.`description`, `uhb`.`date_added`, `uhb`.`date_start`, `uhb`.`date_ending`, `ubd`.`custom_description`  ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_user_reading_stats`
--
DROP TABLE IF EXISTS `vw_user_reading_stats`;

DROP VIEW IF EXISTS `vw_user_reading_stats`;
CREATE ALGORITHM=UNDEFINED DEFINER=`Lectoria`@`localhost` SQL SECURITY DEFINER VIEW `vw_user_reading_stats`  AS SELECT `u`.`id` AS `user_id`, `u`.`nickName` AS `user_nickname`, concat(`u`.`name`,' ',coalesce(`u`.`last_name1`,''),' ',coalesce(`u`.`last_name2`,'')) AS `user_full_name`, count(distinct `uhb`.`id_book`) AS `total_books`, sum((case when (`rs`.`name` = 'completed') then 1 else 0 end)) AS `completed_books`, sum((case when (`rs`.`name` = 'reading') then 1 else 0 end)) AS `reading_books`, sum((case when (`rs`.`name` = 'plan_to_read') then 1 else 0 end)) AS `planned_books`, sum((case when (`rs`.`name` = 'dropped') then 1 else 0 end)) AS `dropped_books`, sum((case when (`rs`.`name` = 'on_hold') then 1 else 0 end)) AS `on_hold_books`, sum(`b`.`pages`) AS `total_pages_all_books`, sum((case when (`rs`.`name` = 'completed') then `b`.`pages` else 0 end)) AS `total_pages_read_completed`, coalesce((select sum(`rp`.`pages`) from `reading_progress` `rp` where (`rp`.`id_user` = `u`.`id`)),0) AS `total_pages_read_sessions`, round(avg(`r`.`rating`),2) AS `average_rating`, (select `g`.`name` from ((`book_has_genre` `bhg` join `genre` `g` on((`bhg`.`id_genre` = `g`.`id`))) join `user_has_book` `uhb2` on((`bhg`.`id_book` = `uhb2`.`id_book`))) where ((`uhb2`.`id_user` = `u`.`id`) and (`uhb2`.`id_status` = (select `reading_status`.`id` from `reading_status` where (`reading_status`.`name` = 'completed')))) group by `g`.`id` order by count(0) desc limit 1) AS `favorite_genre`, (select concat(`a`.`name`,' ',coalesce(`a`.`last_name1`,''),' ',coalesce(`a`.`last_name2`,'')) from ((`book_has_author` `bha` join `author` `a` on((`bha`.`id_author` = `a`.`id`))) join `user_has_book` `uhb3` on((`bha`.`id_book` = `uhb3`.`id_book`))) where ((`uhb3`.`id_user` = `u`.`id`) and (`uhb3`.`id_status` = (select `reading_status`.`id` from `reading_status` where (`reading_status`.`name` = 'completed')))) group by `a`.`id` order by count(0) desc limit 1) AS `favorite_author`, coalesce(avg((case when ((`uhb`.`date_start` is not null) and (`uhb`.`date_ending` is not null)) then (to_days(`uhb`.`date_ending`) - to_days(`uhb`.`date_start`)) else NULL end)),0) AS `avg_reading_days_per_book`, (case when (sum((case when ((`uhb`.`date_start` is not null) and (`uhb`.`date_ending` is not null)) then 1 else 0 end)) > 0) then round((sum((case when ((`uhb`.`date_start` is not null) and (`uhb`.`date_ending` is not null)) then `b`.`pages` else 0 end)) / sum((case when ((`uhb`.`date_start` is not null) and (`uhb`.`date_ending` is not null)) then (to_days(`uhb`.`date_ending`) - to_days(`uhb`.`date_start`)) else 0 end))),2) else 0 end) AS `avg_pages_per_day` FROM ((((`user` `u` left join `user_has_book` `uhb` on((`u`.`id` = `uhb`.`id_user`))) left join `book` `b` on((`uhb`.`id_book` = `b`.`id`))) left join `reading_status` `rs` on((`uhb`.`id_status` = `rs`.`id`))) left join `review` `r` on(((`u`.`id` = `r`.`id_user`) and (`b`.`id` = `r`.`id_book`)))) GROUP BY `u`.`id`, `u`.`nickName`, `user_full_name`  ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
