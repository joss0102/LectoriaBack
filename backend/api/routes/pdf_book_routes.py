from flask import Blueprint, jsonify, request
from services.pdf_book_service import PdfBookService
import logging

pdf_book_bp = Blueprint('pdf_book_bp', __name__)
pdf_book_service = PdfBookService()
logger = logging.getLogger('api')

@pdf_book_bp.route('/upload', methods=['POST'])
def upload_pdf():
    """
    Procesa un archivo PDF para buscar información de libros.
    
    Request:
    - Archivo PDF (file)
    - Título del libro (opcional, bookTitle)
    
    Returns:
        dict: Información de libros encontrados
    """
    try:
        # Verificar que se ha recibido un archivo
        if 'file' not in request.files:
            return jsonify({"error": "No se ha enviado un archivo"}), 400
            
        file = request.files['file']
        
        # Verificar que el archivo es un PDF
        if not file.filename.lower().endswith('.pdf'):
            return jsonify({"error": "Solo se aceptan archivos PDF"}), 400
            
        book_title = request.form.get('bookTitle')
        
        # Procesar el PDF para obtener información de libros
        result = pdf_book_service.process_pdf(file, book_title)
        
        return jsonify({"message": result})
        
    except Exception as e:
        logger.error(f"Error procesando PDF: {str(e)}")
        return jsonify({"error": f"Error procesando PDF: {str(e)}"}), 500