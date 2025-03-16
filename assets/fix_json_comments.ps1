Write-Host "JSON Comment Remover" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""

$jsonFile = "clinical_experience_database.json"
Write-Host "Processing file: $jsonFile" -ForegroundColor Green

# Check if file exists
if (-not (Test-Path $jsonFile)) {
    Write-Host "Error: File not found!" -ForegroundColor Red
    exit 1
}

# Read the file content
$content = Get-Content $jsonFile -Raw

# Remove comment lines (lines starting with // after whitespace)
$noComments = $content -replace "(\r?\n)\s*//.*?(\r?\n)", '$1$2'

# Write fixed content to a new file
$outputFile = "clinical_experience_database_fixed.json"
$noComments | Out-File $outputFile -Encoding utf8

Write-Host ""
Write-Host "Fixed JSON saved to: $outputFile" -ForegroundColor Green
Write-Host "Please verify the file is valid JSON and rename it if needed." 