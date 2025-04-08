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