@echo off
set "FB_HOME=C:\tools\FreeBASIC"
set "PATH=%PATH%;%FB_HOME%"
fbc -dll -gen gcc -arch x86_64 -x "SmartMath64.dll" "SmartMath.bas" "SmartMath_Config.bas" "SmartMath_Format.bas" "SmartMath_About.bas" "SmartMath_Menu.bas" "MathParser.bas"
REM pause
