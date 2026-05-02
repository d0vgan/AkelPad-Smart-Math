@echo off
set "FB_HOME=C:\tools\FreeBASIC"
set "PATH=%PATH%;%FB_HOME%"
fbc -dll -gen gcc "SmartMath.bas" "SmartMath_Config.bas" "SmartMath_Format.bas" "SmartMath_CopyNormalize.bas" "SmartMath_About.bas" "SmartMath_Menu.bas" "MathParser.bas"
REM pause