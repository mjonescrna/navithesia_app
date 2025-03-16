# Clinical Experience Database Extractor

This tool automates the extraction of information from PDF and HTML files containing surgical procedure data and converts it into a structured JSON format for the clinical experience database.

## Features

- Extracts text from both PDF and HTML files
- Automatically detects surgical specialties from filenames
- Parses procedure information including duration, ASA classification, and complications
- Integrates with COA clinical experience categories
- Can create a new JSON database or append to an existing one
- Supports batch processing via ZIP files or directories

## Requirements

- Python 3.6 or later
- Required Python packages:
  - PyPDF2 (for PDF processing)
  - BeautifulSoup4 (for HTML processing)

## Installation

1. Ensure you have Python installed on your system.
2. Install the required packages:

```bash
pip install PyPDF2 beautifulsoup4
```

## Usage

### Basic Usage

```bash
python extract_clinical_data.py --input /path/to/pdfs --output clinical_experience_database.json
```

### Command Line Options

- `--input` or `-i`: Input ZIP file or directory containing PDFs/HTMLs (required)
- `--output` or `-o`: Output JSON file path (default: clinical_experience_database.json)
- `--append` or `-a`: Append to existing JSON file instead of creating a new one

### Examples

Process a directory of PDF files:
```bash
python extract_clinical_data.py --input C:\Users\username\Documents\SurgicalPDFs
```

Process a directory of HTML files:
```bash
python extract_clinical_data.py --input C:\Users\username\Documents\SurgicalHTMLs
```

Process a ZIP file containing PDFs:
```bash
python extract_clinical_data.py --input surgical_procedures.zip
```

Append to an existing JSON database:
```bash
python extract_clinical_data.py --input new_procedures --output clinical_experience_database.json --append
```

## Customization

The script includes a basic text extraction and parsing system that may need to be customized based on your specific PDF/HTML formats. You can modify the `parse_procedure_data()` function to refine the extraction logic for your particular documents.

## Limitations

- The current implementation uses basic regex patterns for extraction
- Complex PDF formatting or tables may not be perfectly captured
- The extraction accuracy depends on the consistency of the input files

## Troubleshooting

If you encounter issues:

1. Check the `extraction.log` file for detailed error messages
2. Ensure your PDF/HTML files are properly formatted
3. Try converting PDFs to HTML if the PDF extraction is not working well
4. Adjust the regex patterns in `parse_procedure_data()` to match your document structure

## Notes for Future Improvement

- Add support for OCR for scanned PDFs
- Implement more sophisticated text analysis methods
- Add a web interface for interactive extraction
- Support for more input and output formats 