@echo off
set "FB_HOME=C:\tools\FreeBASIC"
set "PATH=%PATH%;%FB_HOME%;%FB_HOME%\bin\win32"
set "OUT_DIR=%~dp0AkelFiles\Plugs64"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
windres -F pe-x86-64 -c 65001 -I "%FB_HOME%\inc\win\rc" -i SmartMath.rc -o "%OUT_DIR%\SmartMath_res.o"
if errorlevel 1 exit /b 1
fbc -dll -gen gcc -arch x86_64 -x "%OUT_DIR%\SmartMath.dll" -strip -O 2 -Wc -Os "SmartMath.bas" "SmartMath_Config.bas" "SmartMath_Format.bas" "SmartMath_CopyNormalize.bas" "SmartMath_About.bas" "SmartMath_Menu.bas" "MathParser.bas" "%OUT_DIR%\SmartMath_res.o"
if exist "%OUT_DIR%\*.a" del "%OUT_DIR%\*.a"
if exist "%OUT_DIR%\*.o" del "%OUT_DIR%\*.o"
REM pause
