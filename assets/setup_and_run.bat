@echo off
echo Clinical Experience Database Extractor Setup
echo ========================================
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
    echo Python is not installed. Opening the Microsoft Store to install Python...
    echo After installation completes, please run this script again.
    echo.
    echo Alternatively, you can download Python from https://www.python.org/downloads/
    timeout /t 5
    start ms-windows-store://pdp/?ProductId=9PJPW5LDXLZ5
    exit /b
)

echo Found Python at: %PYTHON_CMD%
echo Installing required Python packages...
%PYTHON_CMD% -m pip install PyPDF2 beautifulsoup4

echo.
echo ========================================
echo Setup completed successfully!
echo.

:menu
echo What would you like to do?
echo 1. Process a directory of PDF files
echo 2. Process a directory of HTML files
echo 3. Process a specific file directory (PDFs and HTMLs)
echo 4. Append to existing database
echo 5. Exit
echo.

set /p choice=Enter your choice (1-5): 

if "%choice%"=="1" (
    set /p dir=Enter the directory path containing your PDF files: 
    %PYTHON_CMD% extract_clinical_data.py --input "%dir%"
    goto end
)

if "%choice%"=="2" (
    set /p dir=Enter the directory path containing your HTML files: 
    %PYTHON_CMD% extract_clinical_data.py --input "%dir%"
    goto end
)

if "%choice%"=="3" (
    set /p dir=Enter the directory path containing your files: 
    %PYTHON_CMD% extract_clinical_data.py --input "%dir%"
    goto end
)

if "%choice%"=="4" (
    set /p dir=Enter the directory path containing your new files: 
    %PYTHON_CMD% extract_clinical_data.py --input "%dir%" --append
    goto end
)

if "%choice%"=="5" (
    exit /b
)

echo Invalid choice. Please try again.
goto menu

:end
echo.
echo Process completed. Would you like to do something else?
echo.
goto menu 