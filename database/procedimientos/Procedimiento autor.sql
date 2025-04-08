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