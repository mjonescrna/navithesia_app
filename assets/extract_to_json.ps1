# Clinical Experience Database Extractor
# This PowerShell script automates the process of extracting data from PDFs and creating a JSON database.

Write-Host "Clinical Experience Database Extractor" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue" # Makes downloads faster

# Log function
function Log-Message {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path "extraction_log.txt" -Value $Message
}

# Create log file
Set-Content -Path "extraction_log.txt" -Value "=== Extraction Log $(Get-Date) ==="
Log-Message "Starting extraction process..."

# Create temporary directory for downloads if needed
$tempDir = Join-Path $PSScriptRoot "temp"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Default path for surgical cases
$defaultPath = "C:\Users\mjone\OneDrive\Desktop\Surgical cases"
$surgicalCasesPath = $defaultPath

# Check if the default path exists
if (Test-Path $defaultPath) {
    Log-Message "Found default surgical cases folder at: $defaultPath" -Color "Green"
} else {
    # Ask user for the path
    Log-Message "Default surgical cases folder not found." -Color "Yellow"
    $surgicalCasesPath = Read-Host "Please enter the full path to your Surgical cases folder"
    
    # Verify the path exists
    if (-not (Test-Path $surgicalCasesPath)) {
        Log-Message "ERROR: The specified path does not exist: $surgicalCasesPath" -Color "Red"
        Log-Message "Please run this script again with a valid path."
        Read-Host "Press Enter to exit"
        exit
    }
}

Log-Message "Using surgical cases folder: $surgicalCasesPath" -Color "Green"

# ===== STEP 1: Check for Python =====
Log-Message "Checking for Python..." -Color "Cyan"

$pythonCommand = $null
$pythonVersion = $null

# Try different ways to find Python
$possiblePythonCommands = @(
    "python",
    "python3",
    "py",
    "$env:LOCALAPPDATA\Programs\Python\Python*\python.exe",
    "$env:ProgramFiles\Python*\python.exe",
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe"
)

foreach ($cmd in $possiblePythonCommands) {
    if ($cmd -like "*`**") {
        # Handle wildcards by finding matching files
        $pythonExes = Get-ChildItem -Path $cmd -ErrorAction SilentlyContinue
        foreach ($exe in $pythonExes) {
            try {
                $output = & $exe.FullName --version 2>&1
                if ($output -match "Python (\d+\.\d+\.\d+)") {
                    $pythonCommand = $exe.FullName
                    $pythonVersion = $matches[1]
                    break
                }
            } catch {
                # Continue to the next option
            }
        }
    } else {
        try {
            $output = & $cmd --version 2>&1
            if ($output -match "Python (\d+\.\d+\.\d+)") {
                $pythonCommand = $cmd
                $pythonVersion = $matches[1]
                break
            }
        } catch {
            # Continue to the next option
        }
    }
    
    if ($pythonCommand) {
        break
    }
}

if ($pythonCommand) {
    Log-Message "Found Python $pythonVersion at: $pythonCommand" -Color "Green"
} else {
    Log-Message "Python not found. Will try to download and use portable Python..." -Color "Yellow"
    
    # Download and extract a portable version of Python
    $pythonUrl = "https://www.python.org/ftp/python/3.8.10/python-3.8.10-embed-amd64.zip"
    $pythonZip = Join-Path $tempDir "python.zip"
    $pythonDir = Join-Path $tempDir "python"
    
    try {
        Log-Message "Downloading portable Python..." -Color "Cyan"
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonZip
        
        if (Test-Path $pythonDir) {
            Remove-Item -Path $pythonDir -Recurse -Force
        }
        
        New-Item -ItemType Directory -Path $pythonDir -Force | Out-Null
        
        Log-Message "Extracting Python..." -Color "Cyan"
        Expand-Archive -Path $pythonZip -DestinationPath $pythonDir -Force
        
        $pythonCommand = Join-Path $pythonDir "python.exe"
        
        # Test the extracted Python
        try {
            $output = & $pythonCommand --version 2>&1
            if ($output -match "Python (\d+\.\d+\.\d+)") {
                $pythonVersion = $matches[1]
                Log-Message "Successfully set up portable Python $pythonVersion" -Color "Green"
            } else {
                throw "Could not verify portable Python installation"
            }
        } catch {
            Log-Message "Error testing portable Python: $_" -Color "Red"
            throw "Failed to set up portable Python"
        }
    } catch {
        Log-Message "Failed to download or extract portable Python: $_" -Color "Red"
        Log-Message "Will try to use embedded code instead." -Color "Yellow"
        $pythonCommand = $null
    }
}

# ===== STEP 2: Create the JSON from PDF filenames =====
Log-Message "Starting JSON creation from PDF files..." -Color "Cyan"

if ($pythonCommand) {
    # Use Python script to process PDFs
    Log-Message "Using Python to process PDFs..." -Color "Cyan"
    
    # Create a temporary Python script
    $pythonScript = @"
import os
import re
import json
import datetime
import sys

# Log to console and file
def log(message):
    print(message)

# Constants - COA categories
COA_CATEGORIES = {
    "patientPhysicalStatus": [
        "Class I", "Class II", "Class III", "Class IV", "Class V", "Class VI"
    ],
    "specialCases": [
        "Geriatric (65+ years)", "Pediatric (total)", "Neonate (less than 4 weeks)", "Trauma/Emergency (E)"
    ],
    "anatomicalCategories": [
        "Intra-abdominal", "Intracranial", "Oropharyngeal", "Intrathoracic", "Neck", "Neuroskeletal", "Vascular"
    ],
    "methodsOfAnesthesia": [
        "General anesthesia", "Inhalation induction", "Mask management", 
        "Supraglottic airway devices", "Tracheal intubation", "Alternative techniques"
    ]
}

def get_specialty_from_filename(filename):
    # Remove extension and path
    base_name = os.path.basename(filename)
    name_without_ext = os.path.splitext(base_name)[0]
    
    # Clean up the name
    specialty = name_without_ext.replace('_', ' ')
    specialty = re.sub(r'\.html$|\.pdf$', '', specialty, flags=re.IGNORECASE)
    specialty = re.sub(r'surgery$|surgery\s+', '', specialty, flags=re.IGNORECASE).strip()
    
    if not specialty:
        specialty = "general"
    
    return specialty.lower()

def get_anatomical_location(specialty):
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

def create_json_database(folder_path):
    # Create the base JSON structure
    current_date = datetime.datetime.now().strftime("%Y-%m-%d")
    json_data = {
        "version": "1.0",
        "lastUpdated": current_date,
        "metadata": {
            "source": "Clinical Experience Database",
            "description": "Comprehensive database of clinical experiences for anesthesia practice"
        },
        "coaCategories": COA_CATEGORIES,
        "specialties": {}
    }
    
    # Check if the folder exists
    if not os.path.exists(folder_path):
        log(f"Error: Folder not found: {folder_path}")
        return None
    
    # Process all PDF files in the folder
    pdf_count = 0
    specialty_count = 0
    
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.lower().endswith('.pdf'):
                pdf_path = os.path.join(root, file)
                pdf_count += 1
                
                # Extract specialty from filename
                specialty = get_specialty_from_filename(file)
                procedure_name = os.path.basename(file).replace('.pdf', '')
                
                # Initialize specialty if not exists
                if specialty not in json_data["specialties"]:
                    json_data["specialties"][specialty] = []
                    specialty_count += 1
                
                # Create procedure entry
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
                
                # Add procedure to specialty
                json_data["specialties"][specialty].append(procedure)
    
    log(f"Processed {pdf_count} PDF files across {specialty_count} specialties")
    return json_data

# Main function
def main():
    if len(sys.argv) < 2:
        log("Error: Missing folder path argument")
        return
    
    folder_path = sys.argv[1]
    log(f"Processing folder: {folder_path}")
    
    # Create the JSON database
    json_data = create_json_database(folder_path)
    
    if json_data:
        # Write to file
        output_file = "clinical_experience_database.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2)
        log(f"Successfully created {output_file}")
    else:
        log("Failed to create JSON database")

if __name__ == "__main__":
    main()
"@

    $pythonScriptPath = Join-Path $PSScriptRoot "temp_extractor.py"
    Set-Content -Path $pythonScriptPath -Value $pythonScript
    
    try {
        Log-Message "Running Python script to extract data..." -Color "Cyan"
        & $pythonCommand $pythonScriptPath $surgicalCasesPath
        
        # Check if the JSON file was created
        $jsonPath = Join-Path $PSScriptRoot "clinical_experience_database.json"
        if (Test-Path $jsonPath) {
            Log-Message "Successfully created JSON database at: $jsonPath" -Color "Green"
        } else {
            throw "JSON file was not created"
        }
    } catch {
        Log-Message "Error running Python script: $_" -Color "Red"
        Log-Message "Falling back to PowerShell extraction..." -Color "Yellow"
        $pythonCommand = $null
    } finally {
        # Clean up
        if (Test-Path $pythonScriptPath) {
            Remove-Item -Path $pythonScriptPath -Force
        }
    }
}

# If Python failed, use PowerShell instead
if (-not $pythonCommand -or -not (Test-Path (Join-Path $PSScriptRoot "clinical_experience_database.json"))) {
    Log-Message "Using PowerShell to process PDFs..." -Color "Cyan"
    
    # Create the JSON structure
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    
    $jsonData = @{
        version = "1.0"
        lastUpdated = $currentDate
        metadata = @{
            source = "Clinical Experience Database"
            description = "Comprehensive database of clinical experiences for anesthesia practice"
        }
        coaCategories = @{
            patientPhysicalStatus = @(
                "Class I", "Class II", "Class III", "Class IV", "Class V", "Class VI"
            )
            specialCases = @(
                "Geriatric (65+ years)", "Pediatric (total)", "Neonate (less than 4 weeks)", "Trauma/Emergency (E)"
            )
            anatomicalCategories = @(
                "Intra-abdominal", "Intracranial", "Oropharyngeal", "Intrathoracic", "Neck", "Neuroskeletal", "Vascular"
            )
            methodsOfAnesthesia = @(
                "General anesthesia", "Inhalation induction", "Mask management", 
                "Supraglottic airway devices", "Tracheal intubation", "Alternative techniques"
            )
        }
        specialties = @{}
    }
    
    # Function to extract specialty from filename
    function Get-Specialty {
        param (
            [string]$FileName
        )
        
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
        $specialty = $baseName -replace "_", " "
        $specialty = $specialty -replace "(?i)\.html|\.pdf", ""
        $specialty = $specialty -replace "(?i)surgery\s*$", ""
        $specialty = $specialty.Trim()
        
        if ([string]::IsNullOrWhiteSpace($specialty)) {
            $specialty = "general"
        }
        
        return $specialty.ToLower()
    }
    
    # Function to determine anatomical location
    function Get-AnatomicalLocation {
        param (
            [string]$Specialty
        )
        
        if ($Specialty -match "abdominal") {
            return "Intra-abdominal"
        } elseif ($Specialty -match "neuro|brain") {
            return "Intracranial"
        } elseif ($Specialty -match "thoracic|cardiac") {
            return "Intrathoracic"
        } elseif ($Specialty -match "vascular") {
            return "Vascular"
        } elseif ($Specialty -match "oral|dental") {
            return "Oropharyngeal"
        } elseif ($Specialty -match "neck|ent") {
            return "Neck"
        } elseif ($Specialty -match "ortho") {
            return "Neuroskeletal"
        } else {
            return "Not specified"
        }
    }
    
    # Process PDFs with PowerShell
    $pdfCount = 0
    $specialtyCount = 0
    
    try {
        Log-Message "Finding PDF files..." -Color "Cyan"
        $pdfFiles = Get-ChildItem -Path $surgicalCasesPath -Recurse -Filter "*.pdf" -ErrorAction Stop
        
        Log-Message "Found $($pdfFiles.Count) PDF files" -Color "Green"
        
        foreach ($pdf in $pdfFiles) {
            $pdfCount++
            
            # Get specialty from filename
            $specialty = Get-Specialty -FileName $pdf.Name
            
            # Create specialty if it doesn't exist
            if (-not $jsonData.specialties.$specialty) {
                $jsonData.specialties.$specialty = @()
                $specialtyCount++
            }
            
            # Create procedure entry
            $procedureName = [System.IO.Path]::GetFileNameWithoutExtension($pdf.Name)
            $anatomicalLocation = Get-AnatomicalLocation -Specialty $specialty
            
            $procedure = @{
                procedureName = $procedureName
                estimatedDuration = "Not specified"
                defaultAssessment = "Class II"
                coaCategories = @(
                    "General anesthesia"
                )
                commonTechniques = @("Standard techniques")
                anatomicalLocation = $anatomicalLocation
                reference = "Clinical Experience Database"
                commonComplications = @("Standard complications")
                specificDetails = @{
                    positioning = "Standard positioning"
                    monitoring = @("Standard monitoring")
                    airwayManagement = "Standard management"
                    painManagement = @("Multimodal")
                    fluidManagement = "Standard management"
                    specialConsiderations = "None"
                }
            }
            
            # Add procedure to specialty
            $jsonData.specialties.$specialty += $procedure
        }
        
        Log-Message "Processed $pdfCount PDF files across $specialtyCount specialties" -Color "Green"
        
        # Convert to JSON and save
        $jsonPath = Join-Path $PSScriptRoot "clinical_experience_database.json"
        $jsonData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
        
        if (Test-Path $jsonPath) {
            Log-Message "Successfully created JSON database at: $jsonPath" -Color "Green"
        } else {
            throw "JSON file was not created"
        }
    } catch {
        Log-Message "Error processing PDFs with PowerShell: $_" -Color "Red"
        throw "Failed to create JSON database"
    }
}

# ===== STEP 3: Clean up =====
if (Test-Path $tempDir) {
    try {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Log-Message "Warning: Failed to clean up temporary files" -Color "Yellow"
    }
}

Log-Message "=============================================" -Color "Cyan"
Log-Message "Process completed successfully!" -Color "Green"
Log-Message "The clinical experience database has been created at:" -Color "Green"
Log-Message "$(Join-Path $PSScriptRoot "clinical_experience_database.json")" -Color "Green"
Log-Message "=============================================" -Color "Cyan"

Write-Host
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 