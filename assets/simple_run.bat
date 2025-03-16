@echo off
echo Simple Clinical Experience Database Extractor
echo =============================================
echo.

echo This script will create a JSON database from your PDF files.
echo.

set /p FOLDER=Please enter the full path to your Surgical cases folder: 

echo.
echo Starting extraction...
echo.

python simple_extraction.py "%FOLDER%"

echo.
echo =============================================
echo Process complete! Check extraction_log.txt for details.
echo.
echo Press any key to exit...
pause > nul 