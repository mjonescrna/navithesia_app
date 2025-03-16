import sys
import os
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("extraction_log.txt", mode="w"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("direct_extraction")

def main():
    try:
        # Import the main extraction script
        logger.info("Starting direct extraction process")
        
        # The target directory containing PDFs
        pdf_dir = r"C:\Users\mjone\OneDrive\Desktop\Surgical cases"
        
        if not os.path.exists(pdf_dir):
            logger.error(f"Directory not found: {pdf_dir}")
            return False
            
        logger.info(f"Processing PDF files from: {pdf_dir}")
        
        # Import the extraction module
        try:
            from extract_clinical_data import (
                extract_text_from_pdf, 
                get_specialty_from_filename,
                parse_procedure_data,
                create_base_json,
                update_json_with_procedures
            )
        except ImportError as e:
            logger.error(f"Failed to import extraction module: {e}")
            return False
            
        # Create base JSON structure
        json_data = create_base_json()
        
        # Process all PDF files in the directory
        pdf_files = list(Path(pdf_dir).glob("*.pdf"))
        logger.info(f"Found {len(pdf_files)} PDF files to process")
        
        for pdf_path in pdf_files:
            logger.info(f"Processing: {pdf_path.name}")
            try:
                # Extract text from PDF
                text = extract_text_from_pdf(str(pdf_path))
                
                # Get specialty from filename
                specialty = get_specialty_from_filename(pdf_path.name)
                
                # Parse procedure data
                procedures = parse_procedure_data(text, specialty)
                
                # Update JSON with procedures
                if procedures:
                    logger.info(f"Extracted {len(procedures)} procedures from {pdf_path.name}")
                    update_json_with_procedures(json_data, specialty, procedures)
                else:
                    logger.warning(f"No procedures extracted from {pdf_path.name}")
                    
            except Exception as e:
                logger.error(f"Error processing {pdf_path.name}: {e}")
        
        # Save the JSON file
        output_file = "clinical_experience_database.json"
        with open(output_file, "w", encoding="utf-8") as f:
            import json
            json.dump(json_data, f, indent=2, ensure_ascii=False)
            
        logger.info(f"JSON file created successfully: {output_file}")
        return True
        
    except Exception as e:
        logger.error(f"Extraction failed: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

if __name__ == "__main__":
    success = main()
    
    if success:
        print("\nExtraction completed successfully! The JSON file has been created.")
    else:
        print("\nExtraction encountered errors. Please check the extraction_log.txt file for details.")
        
    print("\nPress Enter to exit...")
    input() 