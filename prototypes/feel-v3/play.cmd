@echo off
set "GODOT_EXE=godot"
if exist "C:\Users\AUC\opencode-workspace\tools\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=C:\Users\AUC\opencode-workspace\tools\Godot\Godot_v4.7.2-stable_win64.exe"
if defined GODOT set "GODOT_EXE=%GODOT%"
start "" "%GODOT_EXE%" --path "%~dp0."
