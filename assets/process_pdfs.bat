@echo off
echo Clinical Experience Database Extractor
echo ======================================
echo.

echo This will process your PDF files directly without requiring input.
echo Directory: C:\Users\mjone\OneDrive\Desktop\Surgical cases
echo.
echo Processing... (This may take a few minutes)
echo.

python run_extraction_direct.py

echo.
echo Press any key to exit...
pause > nul 