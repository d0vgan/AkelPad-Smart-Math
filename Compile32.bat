@echo off
set "FB_HOME=C:\tools\FreeBASIC"
set "PATH=%PATH%;%FB_HOME%;%FB_HOME%\bin\win32"
windres -F pe-i386 -c 65001 -I "%FB_HOME%\inc\win\rc" -i SmartMath.rc -o SmartMath_res.o
if errorlevel 1 exit /b 1
fbc -dll -gen gcc -arch 386 -x "SmartMath32.dll" "SmartMath.bas" "SmartMath_Config.bas" "SmartMath_Format.bas" "SmartMath_CopyNormalize.bas" "SmartMath_About.bas" "SmartMath_Menu.bas" "MathParser.bas" "SmartMath_res.o"
REM pause
