@echo off
REM Check for admin rights and self-elevate if needed
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

setlocal enabledelayedexpansion
title SuperStarOff - Install Photoshop Plugin

echo ===================================================
echo SuperStarOff - Photoshop Plugin Installer
echo ===================================================
echo.

set "SOURCE=%~dp0StarOff.jsx"
set INSTALLED=0

echo Scanning for installed Photoshop versions...
echo.

REM Check each Photoshop version in Program Files (64-bit)
for %%Y in (2026 2025 2024 2023 2022) do (
    set "PS_PATH=C:\Program Files\Adobe\Adobe Photoshop %%Y\Presets\Scripts"
    if exist "!PS_PATH!" (
        echo Found Photoshop %%Y
        copy /Y "%SOURCE%" "!PS_PATH!\StarOff.jsx" >nul 2>&1
        if !errorlevel! equ 0 (
            echo   [OK] Installed to Photoshop %%Y
            set /a INSTALLED=INSTALLED+1
        ) else (
            echo   [FAIL] Installation failed - may need admin rights
        )
    )
)

echo.

if !INSTALLED! gtr 0 (
    echo ===================================================
    echo [OK] Installation complete! Installed to !INSTALLED! Photoshop version[s]
    echo ===================================================
    echo.
    echo How to use:
    echo   1. Restart Photoshop
    echo   2. Open a star field image
    echo   3. Menu: File - Scripts - StarOff
    echo.
    echo Clear Skies! - James
    echo.
) else (
    echo ===================================================
    echo [WARNING] No Photoshop installation found
    echo ===================================================
    echo.
    echo Please ensure Adobe Photoshop is installed in:
    echo   C:\Program Files\Adobe\Adobe Photoshop 20XX\
    echo.
    echo Or manually copy the script:
    echo   From: %SOURCE%
    echo   To: [Photoshop Install Dir]\Presets\Scripts\
    echo.
)

pause