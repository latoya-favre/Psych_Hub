@echo off
setlocal
cd /d "%~dp0"
py -m pip install -r requirements.txt
if errorlevel 1 goto :error
py -m PyInstaller --clean --noconfirm StratificationOptimizationEngine.spec
if errorlevel 1 goto :error
echo.
echo Build complete: dist\StratificationOptimizationEngine.exe
pause
exit /b 0
:error
echo.
echo Build failed. Review the messages above.
pause
exit /b 1
