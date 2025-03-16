@echo off
echo Creating Clinical Experience Database JSON File
echo ==============================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0simple_json_creator.ps1"

echo.
echo Press any key to exit...
pause > nul 