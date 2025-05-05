import re
import logging

logger = logging.getLogger('api')

def clean_title(title: str) -> str:
    """
    Limpia un título de libro para mejorar los resultados de búsqueda.
    
    Args:
        title (str): Título original
        
    Returns:
        str: Título limpio
    """
    # Quitar caracteres no alfanuméricos al inicio y final
    title = title.strip()
    title = re.sub(r'^[^\w]+|[^\w]+$', '', title)
    
    # Quitar cantidades o códigos de producto
    title = re.sub(r'^\d+\s*x\s*', '', title)
    title = re.sub(r'^\d+\s*-\s*', '', title)
    
    # Eliminar códigos numéricos o alfanuméricos comunes en catálogos
    title = re.sub(r'\b[A-Z0-9]{5,}\b', '', title)
    
    # Limpiar espacios extras
    title = re.sub(r'\s+', ' ', title).strip()
    
    return title

def normalize_text(text: str) -> str:
    """
    Normaliza un texto para mejorar el procesamiento.
    Args:
        text (str): Texto original
    Returns:
        str: Texto normalizado
    """
    # Reemplazar acentos
    replacements = {
        'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
        'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
        'ñ': 'n', 'Ñ': 'N'
    }
    
    for original, replacement in replacements.items():
        text = text.replace(original, replacement)
    
    return text

def extract_book_metadata(book_data):
    """
    Extrae metadatos de un libro desde la respuesta de Google Books API.
    Args:
        book_data (dict): Datos del libro
    Returns:
        dict: Metadatos del libro
    """
    try:
        volume_info = book_data.get('volumeInfo', {})
        
        # Extraer información básica
        title = volume_info.get('title', 'Título desconocido')
        authors = volume_info.get('authors', ['Autor desconocido'])
        publisher = volume_info.get('publisher', 'Editorial desconocida')
        published_date = volume_info.get('publishedDate', '')
        description = volume_info.get('description', '')
        page_count = volume_info.get('pageCount', 0)
        categories = volume_info.get('categories', [])
        language = volume_info.get('language', '')
        
        # Extraer imágenes
        image_links = volume_info.get('imageLinks', {})
        thumbnail = image_links.get('thumbnail', '')
        
        # Extraer identificadores (ISBN, etc.)
        industry_identifiers = volume_info.get('industryIdentifiers', [])
        isbn = ''
        for identifier in industry_identifiers:
            if identifier.get('type') == 'ISBN_13':
                isbn = identifier.get('identifier', '')
                break
            elif identifier.get('type') == 'ISBN_10' and not isbn:
                isbn = identifier.get('identifier', '')
        
        return {
            'title': title,
            'authors': authors,
            'publisher': publisher,
            'publishedDate': published_date,
            'description': description,
            'pageCount': page_count,
            'categories': categories,
            'language': language,
            'thumbnail': thumbnail,
            'isbn': isbn
        }
        
    except Exception as e:
        logger.error(f"Error al extraer metadatos del libro: {str(e)}")
        return {}