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
