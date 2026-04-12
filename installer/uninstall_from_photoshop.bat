@echo off
setlocal enabledelayedexpansion
title SuperStarOff - Uninstall Photoshop Plugin

echo Removing SuperStarOff plugin from Photoshop...

REM Remove script and config from each Photoshop version
for %%Y in (2026 2025 2024 2023 2022) do (
    set "SCRIPTS_DIR=%ProgramFiles%\Adobe\Adobe Photoshop %%Y\Presets\Scripts"
    set "JSX_PATH=!SCRIPTS_DIR!\慧眼去星.jsx"
    set "CFG_PATH=!SCRIPTS_DIR!\config.json"
    if exist "!JSX_PATH!" (
        del /F /Q "!JSX_PATH!" >nul 2>&1
        echo Removed JSX from Photoshop %%Y
    )
    if exist "!CFG_PATH!" (
        del /F /Q "!CFG_PATH!" >nul 2>&1
        echo Removed config from Photoshop %%Y
    )
)

echo Done