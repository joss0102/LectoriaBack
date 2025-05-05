import pdfplumber
import re
from typing import Optional
import requests
import logging
from services.book_service import BookService

logger = logging.getLogger('api')

class PdfBookService:
    """
    Servicio para procesar archivos PDF y buscar información de libros.
    """
    def __init__(self):
        self.book_service = BookService()
        self.google_books_api_url = "https://www.googleapis.com/books/v1/volumes"
        
    def process_pdf(self, file, book_title: Optional[str] = None):
        """
        Procesa PDF para extraer información de libros, incluso en facturas
        
        Args:
            file: Archivo PDF cargado
            book_title (str, optional): Título del libro para buscar directamente
            
        Returns:
            dict: Datos de libros encontrados
        """
        logger.info(f"Procesando PDF: {file.filename}")
        
        # Si se proporciona un título, buscar directamente
        if book_title:
            logger.info(f"Buscando libro por título: {book_title}")
            return self._search_book_in_google_books(book_title)
            
        # Extraer texto del PDF
        text = self._extract_text_from_pdf(file)
        titles = self._find_potential_book_titles(text)
        
        logger.info(f"Títulos potenciales encontrados: {len(titles)}")
        
        # Buscar todos los títulos potenciales y combinar resultados
        all_items = []
        found_titles = set()  # Para evitar duplicados
        
        for title in titles:
            logger.debug(f"Buscando información para: '{title}'")
            book_data = self._search_book_in_google_books(title)
            if book_data.get('items'):
                # Para cada libro encontrado, verificamos que no esté duplicado
                for item in book_data.get('items', []):
                    book_title = item.get('volumeInfo', {}).get('title', '')
                    if book_title and book_title.lower() not in found_titles:
                        found_titles.add(book_title.lower())
                        all_items.append(item)
        
        # Construir un resultado combinado con todos los libros encontrados
        if all_items:
            return {"items": all_items}
        
        # Si no hay resultados después de intentar con todos los títulos
        return {"items": []}

    def _extract_text_from_pdf(self, file):
        """
        Extrae texto de PDF con manejo de errores
        
        Args:
            file: Archivo PDF
            
        Returns:
            str: Texto extraído del PDF
        """
        try:
            with pdfplumber.open(file) as pdf:
                return "\n".join(page.extract_text() or "" for page in pdf.pages)
        except Exception as e:
            logger.error(f"Error leyendo PDF: {str(e)}")
            raise ValueError(f"Error leyendo PDF: {str(e)}")

    def _find_potential_book_titles(self, text: str) -> list:
        """
        Busca posibles títulos de libros en texto
        
        Args:
            text (str): Texto del PDF
            
        Returns:
            list: Lista de posibles títulos de libros
        """
        # Dividir el texto en líneas para análisis por línea
        lines = [line.strip() for line in text.split('\n') if line.strip()]
        
        # Identificar cabeceras de tabla (útil para facturas)
        header_indicators = ['descripción', 'producto', 'concepto', 'artículo', 'item', 'título', 'cantidad', 'importe', 'precio']
        header_pattern = re.compile('|'.join(header_indicators), re.IGNORECASE)
        
        # Identificar líneas que probablemente sean metadatos de la factura
        metadata_pattern = re.compile(r'factura|cliente|datos|calle|cp|email|teléfono|total|subtotal|iva|fecha|vencimiento|emisión|método|pago|observaciones', re.IGNORECASE)
        
        # Identificar líneas que son probablemente precios
        price_pattern = re.compile(r'^\s*\d+(?:[.,]\d{1,2})?\s*€?\s*$')
        
        potential_titles = []
        in_product_section = False
        
        # Primera pasada: Identificar secciones de productos en la factura
        for i, line in enumerate(lines):
            if header_pattern.search(line):
                in_product_section = True
                continue
            
            if in_product_section and not metadata_pattern.search(line.lower()):
                # Procesar línea como posible producto (título de libro)
                # Limpiar precios y cantidades al final de la línea
                cleaned_line = re.sub(r'\s+\d+(?:[.,]\d{1,2})?\s*€?\s*$', '', line)
                cleaned_line = re.sub(r'^\s*\d+\s*x\s*', '', cleaned_line)  # Quitar cantidades del inicio
                
                # Si después de limpiar aún queda texto sustancial
                if len(cleaned_line) >= 5 and len(cleaned_line) <= 150:
                    potential_titles.append(cleaned_line.strip())
        
        # Segunda pasada: Si no encontramos nada en secciones de productos, buscar líneas que probablemente sean títulos
        if not potential_titles:
            for line in lines:
                # Evitar líneas que son claramente metadatos o precios
                if metadata_pattern.search(line.lower()) or price_pattern.match(line):
                    continue
                    
                # Considerar como título potencial si:
                # - Tiene una longitud razonable para ser un título
                # - No es solo números o caracteres especiales
                # - No está en mayúsculas completas (probablemente un encabezado)
                if (5 <= len(line) <= 150 and 
                    not re.match(r'^[\d\W]+$', line) and 
                    not line.isupper() and
                    not re.match(r'^\s*\d+\s*$', line)):
                    
                    # Limpiar la línea de posibles precios al final
                    cleaned_line = re.sub(r'\s+\d+(?:[.,]\d{1,2})?\s*€?\s*$', '', line)
                    potential_titles.append(cleaned_line.strip())
        
        # Tercera estrategia: Buscar líneas que coincidan con patrones comunes de títulos
        title_patterns = [
            # Título seguido de precio o cantidad
            r'([A-Z][a-zá-úñ]+(?: [a-zá-úñ]+){1,10}(?: [A-Z][a-zá-úñ]+){0,3})\s+\d+(?:[.,]\d{1,2})?',
            
            # Formato típico de libro con artículos iniciales
            r'(?:[Ee]l|[Ll]a|[Ll]os|[Ll]as|[Uu]n|[Uu]na) [a-zá-úñ]+(?: [a-zá-úñ]+){1,10}',
            
            # Título seguido de autor o editorial
            r'([A-Z][a-zá-úñ]+(?: [a-zá-úñ]+){1,10})(?: - | por )([A-Z][a-zá-úñ]+(?: [a-zá-úñ]+){1,5})'
        ]
        
        for pattern in title_patterns:
            matches = re.findall(pattern, text)
            for match in matches:
                if isinstance(match, tuple):
                    match = match[0]  # Tomar el primer grupo si es una tupla
                
                if 5 <= len(match) <= 150:
                    potential_titles.append(match.strip())
        
        # Eliminar duplicados mientras preservamos el orden
        unique_titles = []
        seen = set()
        for title in potential_titles:
            title_lower = title.lower()
            if title_lower not in seen:
                seen.add(title_lower)
                unique_titles.append(title)
        
        # Filtrado final: eliminar títulos que parezcan ser información de la factura
        filtered_titles = [
            title for title in unique_titles 
            if not re.search(r'\b(factura|cliente|datos|calle|total|subtotal|iva)\b', title.lower())
        ]
        
        return filtered_titles

    def _search_book_in_google_books(self, book_name):
        """
        Busca información de un libro en la API de Google Books.
        
        Args:
            book_name (str): Nombre del libro a buscar
            
        Returns:
            dict: Información del libro encontrada en Google Books
        """
        try:
            logger.debug(f"Consultando Google Books API para: '{book_name}'")
            params = {"q": book_name}
            response = requests.get(self.google_books_api_url, params=params)

            if response.status_code == 200:
                return response.json()

            # Intentar con el título sin acentos si falla
            book_name_without_accents = (book_name.replace("á", "a").replace("é", "e")
                                        .replace("í", "i").replace("ó", "o").replace("ú", "u"))
            params["q"] = book_name_without_accents
            response = requests.get(self.google_books_api_url, params=params)

            if response.status_code == 200:
                return response.json()
            else:
                logger.warning(f"Error al consultar Google Books API: {response.status_code}")
                return {"items": []}
                
        except Exception as e:
            logger.error(f"Error al buscar libro en Google Books: {str(e)}")
            return {"items": []}