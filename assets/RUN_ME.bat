@echo off
echo Starting Clinical Experience Database Extractor...
echo This will create a JSON file from your PDF files.
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0extract_to_json.ps1"

echo.
if errorlevel 1 (
    echo There was an error running the script.
    echo Please check extraction_log.txt for details.
    echo.
    echo You can try running the script directly by right-clicking on extract_to_json.ps1 and selecting "Run with PowerShell"
) else (
    echo Process completed. The JSON file has been created.
)

echo.
echo Press any key to exit...
pause > nul