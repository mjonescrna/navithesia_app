# Simple JSON Creator for Clinical Experience Database
# This script creates a basic JSON structure without Python dependencies

Write-Host "Simple JSON Creator for Clinical Experience Database" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host

# Define output file
$outputFile = "clinical_experience_database.json"

# Basic JSON structure
$jsonBase = @{
    "metadata" = @{
        "version" = "1.0"
        "last_updated" = (Get-Date -Format "yyyy-MM-dd")
        "description" = "Clinical Experience Database for Anesthesia Procedures"
    }
    "coa_categories" = @{
        "patient_physical_status" = @(
            "ASA_I", "ASA_II", "ASA_III", "ASA_IV", "ASA_V", "ASA_VI", "ASA_E"
        )
        "special_cases" = @(
            "pediatric_neonatal", "pediatric_infant", "pediatric_child", "geriatric", 
            "obstetrical", "organ_transplant_recipient", "trauma"
        )
        "anatomical_categories" = @(
            "head", "neck", "thorax", "abdomen", "extremities", "perineum"
        )
        "methods_of_anesthesia" = @(
            "general", "regional", "monitored_anesthesia_care", "local_standby"
        )
    }
    "specialties" = @{}
}

# Scan surgical case folder for PDF file names if provided
$surgicalCaseFolder = Read-Host "Enter the path to your surgical cases folder (or press Enter to skip)"

if ($surgicalCaseFolder -and (Test-Path $surgicalCaseFolder)) {
    Write-Host "Scanning folder for procedure names..." -ForegroundColor Green
    
    # Get all PDF files
    $pdfFiles = Get-ChildItem -Path $surgicalCaseFolder -Filter "*.pdf"
    
    # Process each PDF file name to create a specialty entry
    foreach ($pdf in $pdfFiles) {
        # Extract specialty name from filename (remove .pdf extension and clean up)
        $specialtyName = $pdf.BaseName -replace "\s+", "_" -replace "[^\w\d_]", "" | ToLower
        
        # Create specialty object with placeholder procedure
        $procedureName = $pdf.BaseName -replace "Surgery", "" -replace ".pdf", "" -replace "^\s+|\s+$", ""
        
        # Add to specialties object
        $jsonBase.specialties[$specialtyName.ToLower()] = @{
            "procedures" = @(
                @{
                    "name" = "$procedureName Procedure"
                    "estimated_duration" = "Not specified"
                    "default_assessment" = "ASA_II"
                    "coa_categories" = @{
                        "patient_physical_status" = @("ASA_II", "ASA_III")
                        "special_cases" = @()
                        "anatomical_categories" = @()
                        "methods_of_anesthesia" = @("general")
                    }
                    "common_techniques" = @("Not specified")
                    "anatomical_location" = "Not specified"
                    "reference" = "Clinical Experience Database"
                    "common_complications" = @("Not specified")
                    "positioning" = "Not specified"
                    "monitoring" = "Standard ASA monitoring"
                    "airway_management" = "Not specified"
                    "pain_management" = "Multimodal analgesia"
                    "fluid_management" = "Balanced crystalloid solution"
                    "special_considerations" = "Not specified"
                }
            )
        }
        
        Write-Host "Added specialty: $($pdf.BaseName)" -ForegroundColor Green
    }
}

# Convert to JSON
$json = $jsonBase | ConvertTo-Json -Depth 10

# Save to file
$json | Out-File -FilePath $outputFile -Encoding utf8

Write-Host
Write-Host "JSON file created successfully: $outputFile" -ForegroundColor Green
Write-Host "The file contains basic structure and placeholder data based on your PDFs." -ForegroundColor Yellow
Write-Host "You can now edit this file directly or use it as a starting point." -ForegroundColor Yellow
Write-Host
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 