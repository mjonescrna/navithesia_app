# Load the JSON file
$jsonContent = Get-Content -Path "assets/clinical_experience_database_clean.json" -Raw | ConvertFrom-Json

# Check if Obstetric Management section exists
$obstetricSection = $null
foreach ($part in $jsonContent.parts) {
    if ($part.part_name -eq "Obstetric Management" -or $part.part_name -eq "Obstetric Surgery") {
        $obstetricSection = $part
        break
    }
}

# Create Obstetric Management section if it doesn't exist
if ($null -eq $obstetricSection) {
    $obstetricSection = @{
        part_name = "Obstetric Management"
        cases = @()
    }
    $jsonContent.parts += $obstetricSection
}

# Add the Labor Analgesia case
$newCase1 = @{
    name = "Labor Analgesia"
    physical_status = "ASA I-III"
    position = "Sitting"
    anatomical_category = "N/A"
    anesthesia_type = "Neuraxial Anesthesia"
    anesthesia_procedures = "Epidural"
}
$obstetricSection.cases += $newCase1

# Check if Colorectal Surgery section exists
$colorectalSection = $null
foreach ($part in $jsonContent.parts) {
    if ($part.part_name -eq "Colorectal Surgery") {
        $colorectalSection = $part
        break
    }
}

# Create Colorectal Surgery section if it doesn't exist
if ($null -eq $colorectalSection) {
    $colorectalSection = @{
        part_name = "Colorectal Surgery"
        cases = @()
    }
    $jsonContent.parts += $colorectalSection
}

# Add the Hartmann's Colostomy Reversal case
$newCase2 = @{
    name = "Hartmann's Colostomy Reversal"
    physical_status = "ASA II-III"  # Added reasonable value
    position = "Lithotomy and Trendelenburg"
    anatomical_category = "Intraabdominal"
    anesthesia_type = "General Anesthesia"
    anesthesia_procedures = "Endotracheal Intubation; Regional Anesthesia Lower; Ultrasound-Guided Procedure"
}
$colorectalSection.cases += $newCase2

# Check if Neurosurgery section exists
$neuroSection = $null
foreach ($part in $jsonContent.parts) {
    if ($part.part_name -eq "Neurosurgery") {
        $neuroSection = $part
        break
    }
}

# Create Neurosurgery section if it doesn't exist
if ($null -eq $neuroSection) {
    $neuroSection = @{
        part_name = "Neurosurgery"
        cases = @()
    }
    $jsonContent.parts += $neuroSection
}

# Add the Craniotomy case
$newCase3 = @{
    name = "Craniotomy"
    physical_status = "ASA III-IV"
    position = "Supine with head fixed"
    anatomical_category = "Head - Intracranial"
    anesthesia_type = "General Anesthesia"
    anesthesia_procedures = "Endotracheal Intubation; Arterial Catheter Insertion Placement"
}
$neuroSection.cases += $newCase3

# Save the updated JSON content back to the file
$jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path "assets/clinical_experience_database_clean.json"

# Confirm changes
Write-Host "Added three new cases to the clinical experience database:"
Write-Host "1. Labor Analgesia - Added to Obstetric Management"
Write-Host "2. Hartmann's Colostomy Reversal - Added to Colorectal Surgery"
Write-Host "3. Craniotomy - Added to Neurosurgery" 