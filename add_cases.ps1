# Load the JSON file
$jsonContent = Get-Content -Path "assets/clinical_experience_database_clean.json" -Raw | ConvertFrom-Json

# Check if Orthopedic Surgery section exists
$orthoSection = $null
foreach ($part in $jsonContent.parts) {
    if ($part.part_name -eq "Orthopedic Surgery") {
        $orthoSection = $part
        break
    }
}

# Create Orthopedic Surgery section if it doesn't exist
if ($null -eq $orthoSection) {
    $orthoSection = @{
        part_name = "Orthopedic Surgery"
        cases = @()
    }
    $jsonContent.parts += $orthoSection
}

# Add the Total Knee Arthroplasty case
$newCase1 = @{
    name = "Total Knee Arthroplasty (TKA)"
    physical_status = "ASA II-III"
    position = "Supine"
    anatomical_category = "Extremities - Lower (Knee)"
    anesthesia_type = "Spinal Anesthesia with Sedation or General Anesthesia"
    anesthesia_procedures = "Spinal block with sedation or endotracheal intubation if general; adjunct regional block: adductor canal block and IPACK block"
}
$orthoSection.cases += $newCase1

# Check if Cardiac Surgery section exists
$cardiacSection = $null
foreach ($part in $jsonContent.parts) {
    if ($part.part_name -eq "Cardiac Surgery") {
        $cardiacSection = $part
        break
    }
}

# Create Cardiac Surgery section if it doesn't exist
if ($null -eq $cardiacSection) {
    $cardiacSection = @{
        part_name = "Cardiac Surgery"
        cases = @()
    }
    $jsonContent.parts += $cardiacSection
}

# Add the CABG case
$newCase2 = @{
    name = "Coronary Artery Bypass Graft (CABG)"
    physical_status = "ASA III-IV"
    position = "Supine"
    anatomical_category = "Intrathoracic - Heart"
    anesthesia_type = "General Anesthesia"
    anesthesia_procedures = "Endotracheal intubation; central line; arterial line; TEE; cardiopulmonary bypass"
}
$cardiacSection.cases += $newCase2

# Check if Thoracic Surgery section exists
$thoracicSection = $null
foreach ($part in $jsonContent.parts) {
    if ($part.part_name -eq "Thoracic Surgery") {
        $thoracicSection = $part
        break
    }
}

# Create Thoracic Surgery section if it doesn't exist
if ($null -eq $thoracicSection) {
    $thoracicSection = @{
        part_name = "Thoracic Surgery"
        cases = @()
    }
    $jsonContent.parts += $thoracicSection
}

# Add the VATS Lobectomy case
$newCase3 = @{
    name = "Video-Assisted Thoracoscopic Surgery (VATS) Lobectomy"
    physical_status = "ASA II-III"
    position = "Lateral decubitus"
    anatomical_category = "Intrathoracic - Lung"
    anesthesia_type = "General Anesthesia with One-Lung Ventilation"
    anesthesia_procedures = "Endotracheal intubation with double-lumen tube or bronchial blocker; arterial line; thoracic epidural or paravertebral block"
}
$thoracicSection.cases += $newCase3

# Save the updated JSON content back to the file
$jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path "assets/clinical_experience_database_clean.json"

# Confirm changes
Write-Host "Added three new cases to the clinical experience database:"
Write-Host "1. Total Knee Arthroplasty (TKA) - Added to Orthopedic Surgery"
Write-Host "2. Coronary Artery Bypass Graft (CABG) - Added to Cardiac Surgery"
Write-Host "3. Video-Assisted Thoracoscopic Surgery (VATS) Lobectomy - Added to Thoracic Surgery" 