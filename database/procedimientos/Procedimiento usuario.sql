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