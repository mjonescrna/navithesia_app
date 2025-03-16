import os
import re
import json
import datetime
import sys

# Simple logging to console and file
log_file = open("extraction_log.txt", "w")

def log(message):
    print(message)
    log_file.write(message + "\n")
    log_file.flush()

# Check Python version
log(f"Running with Python {sys.version}")
log("Starting extraction process")

# Constants
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
        "Intracranial",
        "Oropharyngeal",
        "Intrathoracic",
        "Neck",
        "Neuroskeletal",
        "Vascular"
    ],
    "methodsOfAnesthesia": [
        "General anesthesia",
        "Inhalation induction",
        "Mask management",
        "Supraglottic airway devices",
        "Tracheal intubation",
        "Alternative techniques"
    ]
}

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

def manual_pdf_extract(folder_path):
    """Create structured JSON entries based on PDF filenames."""
    results = {}
    
    try:
        # Check if folder exists
        if not os.path.exists(folder_path):
            log(f"Error: Folder not found: {folder_path}")
            return None
        
        # List all PDF files
        pdf_files = []
        for root, dirs, files in os.walk(folder_path):
            for file in files:
                if file.lower().endswith('.pdf'):
                    pdf_files.append(os.path.join(root, file))
        
        log(f"Found {len(pdf_files)} PDF files")
        
        # Process each PDF file
        for pdf_file in pdf_files:
            specialty = get_specialty_from_filename(pdf_file)
            log(f"Processing file: {pdf_file} (Specialty: {specialty})")
            
            if specialty not in results:
                results[specialty] = []
            
            # Create a placeholder entry based on the filename
            procedure_name = os.path.basename(pdf_file).replace('.pdf', '')
            
            procedure = {
                "procedureName": procedure_name,
                "estimatedDuration": "Not specified",
                "defaultAssessment": "Class II",
                "coaCategories": [
                    "General anesthesia"
                ],
                "commonTechniques": ["Standard techniques"],
                "anatomicalLocation": get_anatomical_location(specialty),
                "reference": "Clinical Experience Database",
                "commonComplications": ["Standard complications"],
                "specificDetails": {
                    "positioning": "Standard positioning",
                    "monitoring": ["Standard monitoring"],
                    "airwayManagement": "Standard management",
                    "painManagement": ["Multimodal"],
                    "fluidManagement": "Standard management",
                    "specialConsiderations": "None"
                }
            }
            
            results[specialty].append(procedure)
        
        return results
    
    except Exception as e:
        log(f"Error in manual_pdf_extract: {str(e)}")
        return None

def get_anatomical_location(specialty):
    """Determine anatomical location from specialty."""
    if "abdominal" in specialty:
        return "Intra-abdominal"
    elif "neuro" in specialty or "brain" in specialty:
        return "Intracranial"
    elif "thoracic" in specialty or "cardiac" in specialty:
        return "Intrathoracic"
    elif "vascular" in specialty:
        return "Vascular"
    elif "oral" in specialty or "dental" in specialty:
        return "Oropharyngeal"
    elif "neck" in specialty or "ent" in specialty:
        return "Neck"
    elif "ortho" in specialty:
        return "Neuroskeletal"
    else:
        return "Not specified"

def create_base_json():
    """Create a base JSON structure."""
    current_date = datetime.datetime.now().strftime("%Y-%m-%d")
    
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

def main():
    # Get input directory
    if len(sys.argv) > 1:
        input_dir = sys.argv[1]
    else:
        input_dir = input("Enter the directory path containing your PDF files: ")
    
    log(f"Processing directory: {input_dir}")
    
    # Extract data from PDFs
    specialties_data = manual_pdf_extract(input_dir)
    
    if not specialties_data:
        log("No data extracted. Exiting.")
        return
    
    # Create base JSON structure
    json_data = create_base_json()
    
    # Add extracted data
    json_data["specialties"] = specialties_data
    
    # Write to output file
    output_file = "clinical_experience_database.json"
    try:
        with open(output_file, 'w') as f:
            json.dump(json_data, f, indent=2)
        log(f"Successfully wrote JSON data to {output_file}")
    except Exception as e:
        log(f"Error writing JSON file: {str(e)}")
    
    log("Process completed")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log(f"Unhandled error: {str(e)}")
    finally:
        log_file.close() 