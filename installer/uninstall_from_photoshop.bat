@echo off
setlocal enabledelayedexpansion
title SuperStarOff - Uninstall Photoshop Plugin

echo Removing SuperStarOff plugin from Photoshop...

REM Remove script from each Photoshop version
for %%Y in (2026 2025 2024 2023 2022) do (
    set "SCRIPT_PATH=%ProgramFiles%\Adobe\Adobe Photoshop %%Y\Presets\Scripts\StarOff.jsx"
    if exist "!SCRIPT_PATH!" (
        del /F /Q "!SCRIPT_PATH!" >nul 2>&1
        echo Removed from Photoshop %%Y
    )
)

echo Done