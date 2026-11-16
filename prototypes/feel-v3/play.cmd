@echo off
set "GODOT_EXE=godot"
if exist "C:\Users\AUC\opencode-workspace\tools\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=C:\Users\AUC\opencode-workspace\tools\Godot\Godot_v4.7.2-stable_win64.exe"
if defined GODOT set "GODOT_EXE=%GODOT%"
rem Pandora's frames are not stored in the repository: build them from the reference sheet once
set "SHEET=%~dp0assets\references\DS _ DSi - Castlevania_ Order of Ecclesia - Playable Characters - Shanoa.png"
if not exist "%~dp0assets\hero\idle_00.png" if exist "%SHEET%" python "%~dp0tools\build_pandora.py" "%SHEET%"
if not exist "%~dp0assets\hero\idle_00.png" echo Pandora's frames are missing. Put the reference sheet in assets\references and run this again. & pause
start "" "%GODOT_EXE%" --path "%~dp0."
