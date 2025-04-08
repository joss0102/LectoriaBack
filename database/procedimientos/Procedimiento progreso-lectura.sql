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