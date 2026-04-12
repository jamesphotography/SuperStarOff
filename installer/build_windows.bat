@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo SuperStarOff - Windows Installer Build
echo ===================================================
echo.

REM Get the installer directory (where this script is)
set "INSTALLER_DIR=%~dp0"
REM Remove trailing backslash
set "INSTALLER_DIR=%INSTALLER_DIR:~0,-1%"

REM Get project root (parent of installer dir)
for %%I in ("%INSTALLER_DIR%\..") do set "PROJECT_ROOT=%%~fI"

set "DIST_DIR=%PROJECT_ROOT%\dist\superstaroff"
set "JSX_FILE=%PROJECT_ROOT%\src\慧眼去星.jsx"
set "VERSION=1.1.2"

echo Project Root: %PROJECT_ROOT%
echo Installer Dir: %INSTALLER_DIR%
echo Dist Dir: %DIST_DIR%
echo.

REM Step 1: Check PyInstaller output
echo === Step 1: Check build files ===

if not exist "%DIST_DIR%\superstaroff.exe" (
    echo [ERROR] Cannot find PyInstaller output
    echo Please run first: pyinstaller superstaroff_windows.spec --noconfirm
    pause
    exit /b 1
)
echo [OK] superstaroff.exe exists

if not exist "%PROJECT_ROOT%\src\慧眼去星.jsx" (
    echo [ERROR] Cannot find JSX file in %PROJECT_ROOT%\src\
    pause
    exit /b 1
)
echo [OK] JSX file exists: %JSX_FILE%
echo.

REM Step 2: Copy extra files to dist folder
echo === Step 2: Copy extra files ===

if not exist "%DIST_DIR%\scripts" mkdir "%DIST_DIR%\scripts"

copy /Y "%JSX_FILE%" "%DIST_DIR%\scripts\" >nul
if %errorlevel% equ 0 (
    echo [OK] Copied JSX script
) else (
    echo [ERROR] Failed to copy JSX script
)

copy /Y "%INSTALLER_DIR%\install_to_photoshop.bat" "%DIST_DIR%\scripts\" >nul 2>&1
copy /Y "%INSTALLER_DIR%\uninstall_from_photoshop.bat" "%DIST_DIR%\scripts\" >nul 2>&1
echo [OK] Copied batch scripts
echo.

REM Step 3: Check Inno Setup
echo === Step 3: Check Inno Setup ===

set "ISCC_PATH="

REM Check if iscc is in PATH
where iscc >nul 2>&1
if %errorlevel% equ 0 (
    set "ISCC_PATH=iscc"
    goto :found_iscc
)

REM Check common install locations
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set "ISCC_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    goto :found_iscc
)

if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set "ISCC_PATH=C:\Program Files\Inno Setup 6\ISCC.exe"
    goto :found_iscc
)

echo [WARNING] Inno Setup compiler (ISCC.exe) not found
echo.
echo Please install Inno Setup from: https://jrsoftware.org/isinfo.php
echo.
echo After installing, either:
echo   1. Add Inno Setup to your PATH, or
echo   2. Run manually in Inno Setup GUI: Open SuperStarOff.iss and click Build
echo.
pause
exit /b 1

:found_iscc
echo [OK] Inno Setup found: %ISCC_PATH%
echo.

REM Step 4: Compile installer
echo === Step 4: Compile installer ===

if not exist "%PROJECT_ROOT%\installer_output" mkdir "%PROJECT_ROOT%\installer_output"

"%ISCC_PATH%" "%INSTALLER_DIR%\SuperStarOff.iss"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Compilation failed
    pause
    exit /b 1
)

echo.
echo ===================================================
echo [SUCCESS] Build complete!
echo ===================================================
echo.
echo Version: %VERSION%
echo Output: %PROJECT_ROOT%\installer_output\SuperStarOff-Installer-v%VERSION%.exe
echo.
echo ===================================================

pause