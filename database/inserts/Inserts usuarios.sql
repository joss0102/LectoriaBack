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