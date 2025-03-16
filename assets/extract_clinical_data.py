import os
import re
import json
import zipfile
from datetime import datetime
import argparse
import logging
from pathlib import Path

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("extraction.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("clinical_extractor")

try:
    from PyPDF2 import PdfReader
    PDF_SUPPORT = True
except ImportError:
    logger.warning("PyPDF2 not installed. PDF support disabled. Please install with 'pip install PyPDF2'")
    PDF_SUPPORT = False

try:
    from bs4 import BeautifulSoup
    HTML_SUPPORT = True
except ImportError:
    logger.warning("BeautifulSoup not installed. HTML support disabled. Please install with 'pip install beautifulsoup4'")
    HTML_SUPPORT = False

# Define the COA categories structure
COA_CATEGORIES = {
    "patientPhysicalStatus": [
        "Class I",
        "Class II",
        "Class III", 
        "Class IV",
        "Class V",
        "Class VI"
    ],
    "specialCases": [
        "Geriatric (65+ years)",
        "Pediatric (total)",
        "Neonate (less than 4 weeks)",
        "Trauma/Emergency (E)"
    ],
    "anatomicalCategories": [
        "Intra-abdominal",
        "Intracranial (Open)",
        "Intracranial (Closed)",
        "Oropharyngeal",
        "Intrathoracic (Heart - Open with CPB)",
        "Intrathoracic (Heart - Open without CPB)",
        "Intrathoracic (Heart - Closed)",
        "Intrathoracic (Lung)",
        "Intrathoracic (Other)",
        "Neck",
        "Neuroskeletal",
        "Vascular"
    ],
    "methodsOfAnesthesia": [
        "General anesthesia",
        "Inhalation induction",
        "Mask management",
        "Supraglottic airway devices (Laryngeal Mask)",
        "Supraglottic airway devices (Other)",
        "Tracheal intubation (Oral)",
        "Tracheal intubation (Nasal)",
        "Alternative tracheal intubation/endoscopic techniques",
        "Emergence from anesthesia"
    ],
    "regionalTechniques": [
        "Spinal (Anesthesia)",
        "Spinal (Pain management)",
        "Epidural (Anesthesia)",
        "Epidural (Pain management)",
        "Peripheral Upper (Anesthesia)",
        "Peripheral Upper (Pain management)",
        "Peripheral Lower (Anesthesia)",
        "Peripheral Lower (Pain management)",
        "Other (Anesthesia)", 
        "Other (Pain management)",
        "Management (Anesthesia)",
        "Management (Pain management)"
    ],
    "obstetrical": [
        "Cesarean delivery",
        "Analgesia for labor"
    ]
}

def extract_text_from_pdf(pdf_path):
    """Extract text from a single PDF file."""
    if not PDF_SUPPORT:
        logger.error("PDF support is disabled. Please install PyPDF2.")
        return ""
    
    try:
        reader = PdfReader(pdf_path)
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        return text
    except Exception as e:
        logger.error(f"Error extracting text from PDF {pdf_path}: {e}")
        return ""

def extract_text_from_html(html_path):
    """Extract text from a single HTML file."""
    if not HTML_SUPPORT:
        logger.error("HTML support is disabled. Please install BeautifulSoup4.")
        return ""
    
    try:
        with open(html_path, 'r', encoding='utf-8') as file:
            html_content = file.read()
        
        soup = BeautifulSoup(html_content, 'html.parser')
        
        # Remove script and style elements
        for script in soup(["script", "style"]):
            script.extract()
        
        # Get text
        text = soup.get_text(separator='\n')
        
        # Break into lines and remove leading and trailing space on each
        lines = (line.strip() for line in text.splitlines())
        # Break multi-headlines into a line each
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        # Remove blank lines
        text = '\n'.join(chunk for chunk in chunks if chunk)
        
        return text
    except Exception as e:
        logger.error(f"Error extracting text from HTML {html_path}: {e}")
        return ""

def get_specialty_from_filename(filename):
    """Extract specialty type from filename."""
    # Remove extension and path
    base_name = os.path.basename(filename)
    name_without_ext = os.path.splitext(base_name)[0]
    
    # Replace underscores with spaces and capitalize
    specialty = name_without_ext.replace('_', ' ')
    
    # Clean up some common patterns
    specialty = re.sub(r'\.html$|\.pdf$', '', specialty, flags=re.IGNORECASE)
    specialty = re.sub(r'surgery$|surgery\s+', '', specialty, flags=re.IGNORECASE).strip()
    
    if not specialty:
        specialty = "general"
    
    return specialty.lower()

def parse_procedure_data(text, specialty):
    """
    Parse the raw text to extract procedure details.
    This is a simplified example and will need to be customized based on your PDF format.
    """
    procedures = []
    
    # Pattern matching for procedure sections
    # This is simplified and will need to be adapted to your specific PDF formats
    procedure_pattern = r'(?:Procedure|PROCEDURE|Operation):\s*([^\n]+)'
    duration_pattern = r'(?:Duration|Time|Procedure time):\s*([^\n]+)'
    asa_pattern = r'(?:ASA|Patient status):\s*([^\n]+)'
    complications_pattern = r'(?:Complications|COMPLICATIONS|Common complications):\s*([^\n]+)'
    
    # This is a very basic extraction - real implementation would need more sophisticated parsing
    procedure_matches = re.finditer(r'(?:Procedure|PROCEDURE|Operation):\s*([^\n]+)', text, re.IGNORECASE)
    
    for i, match in enumerate(procedure_matches):
        procedure_name = match.group(1).strip()
        
        # Try to find the end of this procedure section (start of next procedure or end of text)
        start_pos = match.end()
        next_match = None
        for nm in re.finditer(r'(?:Procedure|PROCEDURE|Operation):\s*([^\n]+)', text[start_pos:], re.IGNORECASE):
            next_match = nm
            break
        
        end_pos = start_pos + next_match.start() if next_match else len(text)
        procedure_text = text[start_pos:end_pos]
        
        # Extract various details using regex
        duration_match = re.search(duration_pattern, procedure_text, re.IGNORECASE)
        duration = duration_match.group(1).strip() if duration_match else "Not specified"
        
        asa_match = re.search(asa_pattern, procedure_text, re.IGNORECASE)
        asa = asa_match.group(1).strip() if asa_match else "Class II"
        
        complications_match = re.search(complications_pattern, procedure_text, re.IGNORECASE)
        complications = [comp.strip() for comp in complications_match.group(1).split(',')] if complications_match else ["Not specified"]
        
        # Determine anatomical location from specialty
        anatomical_location = "Not specified"
        if "abdominal" in specialty:
            anatomical_location = "Intra-abdominal"
        elif "neuro" in specialty or "brain" in specialty:
            anatomical_location = "Intracranial"
        elif "thoracic" in specialty or "cardiac" in specialty:
            anatomical_location = "Intrathoracic"
        elif "vascular" in specialty:
            anatomical_location = "Vascular"
        
        # Basic procedure template
        procedure = {
            "procedureName": procedure_name,
            "estimatedDuration": duration,
            "defaultAssessment": asa,
            "coaCategories": [
                anatomical_location,
                "General anesthesia"
            ],
            "commonTechniques": ["Not specified"],
            "anatomicalLocation": anatomical_location,
            "reference": "Clinical Experience Database",
            "commonComplications": complications,
            "specificDetails": {
                "positioning": "Not specified",
                "monitoring": ["Standard ASA"],
                "airwayManagement": "Not specified",
                "painManagement": ["Multimodal"],
                "fluidManagement": "Not specified",
                "specialConsiderations": "Not specified"
            }
        }
        
        procedures.append(procedure)
        
        # If no procedures were found with the pattern, create a placeholder entry
        if not procedures:
            procedure = {
                "procedureName": f"Unknown {specialty.capitalize()} Procedure",
                "estimatedDuration": "Not specified",
                "defaultAssessment": "Class II",
                "coaCategories": ["Not specified"],
                "commonTechniques": ["Not specified"],
                "anatomicalLocation": "Not specified",
                "reference": "Clinical Experience Database",
                "commonComplications": ["Not specified"],
                "specificDetails": {
                    "positioning": "Not specified",
                    "monitoring": ["Standard ASA"],
                    "airwayManagement": "Not specified",
                    "painManagement": ["Multimodal"],
                    "fluidManagement": "Not specified",
                    "specialConsiderations": "Not specified"
                }
            }
            procedures.append(procedure)
    
    return procedures

def load_existing_json(json_path):
    """Load existing JSON file if it exists."""
    if os.path.exists(json_path):
        try:
            with open(json_path, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError:
            logger.error(f"Error decoding existing JSON file {json_path}")
            return None
    return None

def create_base_json():
    """Create a base JSON structure if no existing file is found."""
    current_date = datetime.now().strftime("%Y-%m-%d")
    
    base_json = {
        "version": "1.0",
        "lastUpdated": current_date,
        "metadata": {
            "source": "Clinical Experience Database",
            "description": "Comprehensive database of clinical experiences for anesthesia practice"
        },
        "coaCategories": COA_CATEGORIES,
        "specialties": {}
    }
    
    return base_json

def update_json_with_procedures(json_data, specialty, procedures):
    """Update the JSON data with new procedures."""
    if not specialty in json_data["specialties"]:
        json_data["specialties"][specialty] = []
    
    # Add new procedures
    for procedure in procedures:
        json_data["specialties"][specialty].append(procedure)
    
    return json_data

def main():
    parser = argparse.ArgumentParser(description='Extract clinical data from PDFs and convert to JSON')
    parser.add_argument('--input', '-i', required=True, help='Input ZIP file or directory containing PDFs/HTMLs')
    parser.add_argument('--output', '-o', default='clinical_experience_database.json', help='Output JSON file path')
    parser.add_argument('--append', '-a', action='store_true', help='Append to existing JSON file instead of creating new one')
    args = parser.parse_args()
    
    # Initialize path variables
    input_path = Path(args.input)
    output_path = Path(args.output)
    extract_dir = Path('extracted_files')
    
    # Create extraction directory if it doesn't exist
    if not extract_dir.exists():
        extract_dir.mkdir(parents=True)
    
    # Determine if input is a ZIP file or directory
    if input_path.is_file() and input_path.suffix.lower() == '.zip':
        logger.info(f"Extracting ZIP file: {input_path}")
        try:
            with zipfile.ZipFile(input_path, 'r') as zip_ref:
                zip_ref.extractall(extract_dir)
        except Exception as e:
            logger.error(f"Error extracting ZIP file: {e}")
            return
        
        source_dir = extract_dir
    elif input_path.is_dir():
        logger.info(f"Using directory: {input_path}")
        source_dir = input_path
    else:
        logger.error(f"Input must be a ZIP file or directory: {input_path}")
        return
    
    # Get list of PDF and HTML files
    pdf_files = list(source_dir.glob('**/*.pdf'))
    html_files = list(source_dir.glob('**/*.html'))
    
    logger.info(f"Found {len(pdf_files)} PDF files and {len(html_files)} HTML files")
    
    # Load existing JSON or create new one
    if args.append and output_path.exists():
        json_data = load_existing_json(output_path)
        if json_data is None:
            logger.warning(f"Could not load existing JSON file {output_path}. Creating new one.")
            json_data = create_base_json()
    else:
        json_data = create_base_json()
    
    # Process PDF files
    for pdf_file in pdf_files:
        if PDF_SUPPORT:
            logger.info(f"Processing PDF file: {pdf_file}")
            text = extract_text_from_pdf(pdf_file)
            specialty = get_specialty_from_filename(pdf_file.name)
            procedures = parse_procedure_data(text, specialty)
            json_data = update_json_with_procedures(json_data, specialty, procedures)
        else:
            logger.warning("Skipping PDF files - PyPDF2 not installed")
            break
    
    # Process HTML files
    for html_file in html_files:
        if HTML_SUPPORT:
            logger.info(f"Processing HTML file: {html_file}")
            text = extract_text_from_html(html_file)
            specialty = get_specialty_from_filename(html_file.name)
            procedures = parse_procedure_data(text, specialty)
            json_data = update_json_with_procedures(json_data, specialty, procedures)
        else:
            logger.warning("Skipping HTML files - BeautifulSoup not installed")
            break
    
    # Update last updated date
    json_data["lastUpdated"] = datetime.now().strftime("%Y-%m-%d")
    
    # Write to output file
    try:
        with open(output_path, 'w') as f:
            json.dump(json_data, f, indent=2)
        logger.info(f"Successfully wrote JSON data to {output_path}")
    except Exception as e:
        logger.error(f"Error writing JSON file: {e}")
    
    # Clean up extracted files if we extracted from ZIP
    if input_path.is_file() and input_path.suffix.lower() == '.zip' and extract_dir.exists():
        logger.info(f"Cleaning up extraction directory: {extract_dir}")
        for file in extract_dir.glob('**/*'):
            if file.is_file():
                file.unlink()
        extract_dir.rmdir()

if __name__ == "__main__":
    main() 