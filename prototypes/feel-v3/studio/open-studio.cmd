@echo off
setlocal
for %%I in ("%~dp0..") do set "STUDIO_PROJECT=%%~fI"
set "STUDIO_BUILD=%STUDIO_PROJECT%\build\windows\new-vania-studio-m3.exe"
if not exist "%STUDIO_PROJECT%\studio\catalog.json" goto :make_library
if not exist "%STUDIO_PROJECT%\studio\library\." goto :make_library
goto :launch

:make_library
for %%I in ("%STUDIO_PROJECT%\..\..") do set "STUDIO_REPO=%%~fI"
where.exe node.exe >nul 2>&1
if errorlevel 1 goto :library_failed
pushd "%STUDIO_REPO%" || goto :library_failed
node tools\asset_library.mjs
set "STUDIO_LIBRARY_STATUS=%ERRORLEVEL%"
popd
if not "%STUDIO_LIBRARY_STATUS%"=="0" goto :library_failed

:launch
if exist "%STUDIO_BUILD%" (
  start "" "%STUDIO_BUILD%" -- "--builder-workspace=%STUDIO_PROJECT%"
  exit /b
)
if not defined GODOT_EXE (
  for %%I in ("%STUDIO_PROJECT%\..\..\..\..\tools\Godot\Godot_v4.7.2-stable_win64_console.exe") do set "GODOT_EXE=%%~fI"
)
if exist "%GODOT_EXE%" (
  start "" "%GODOT_EXE%" --path "%STUDIO_PROJECT%"
  exit /b
)
echo Studio could not find the Windows build or Godot. Set GODOT_EXE to the Godot executable.
pause
exit /b 1

:library_failed
echo Studio could not build the asset library. Check that Node.js is installed and on PATH.
pause
exit /b 1
