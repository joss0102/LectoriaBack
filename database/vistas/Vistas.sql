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