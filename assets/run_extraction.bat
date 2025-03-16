@echo off
echo Clinical Experience Database Direct Extractor
echo =============================================
echo.

REM Check if Python is installed through various methods
set PYTHON_CMD=

REM Try Microsoft Store Python
set MS_PYTHON=%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe
if exist "%MS_PYTHON%" set PYTHON_CMD="%MS_PYTHON%"

REM Try system Python
where python > nul 2>&1
if %errorlevel% equ 0 set PYTHON_CMD=python

REM Try Python launcher
where py > nul 2>&1
if %errorlevel% equ 0 set PYTHON_CMD=py

if "%PYTHON_CMD%"=="" (
    echo Python is not installed. Please install Python first:
    echo 1. Go to https://www.python.org/downloads/
    echo 2. Download and install Python 3.8 or later
    echo 3. Run this script again
    pause
    exit /b
)

echo Found Python at: %PYTHON_CMD%
echo Installing required Python packages...
%PYTHON_CMD% -m pip install PyPDF2 beautifulsoup4

echo.
echo Starting extraction from C:\Users\mjone\OneDrive\Desktop\Surgical cases
echo This may take a few minutes depending on the number and size of PDF files...
echo.

%PYTHON_CMD% extract_clinical_data.py --input "C:\Users\mjone\OneDrive\Desktop\Surgical cases"

echo.
echo =============================================
echo Extraction complete!
echo The results have been saved to clinical_experience_database.json
echo.
echo Press any key to exit...
pause > nul 