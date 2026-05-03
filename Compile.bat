@echo off

rem Specify the correct path to FreeBASIC here:
set "FB_HOME=C:\tools\FreeBASIC"

if not exist "%FB_HOME%" (
    echo ERROR: FreeBASIC not found in "%FB_HOME%". Please specify the correct path to FreeBASIC in "%~nx0".
    exit /b 1
)
if not exist "%FB_HOME%\bin\win32" (
    echo ERROR: FreeBASIC bin\win32 not found in "%FB_HOME%\bin\win32"
    exit /b 1
)

set "PATH=%PATH%;%FB_HOME%;%FB_HOME%\bin\win32"

fbc -dll -gen gcc "SmartMath.bas" "SmartMath_Config.bas" "SmartMath_Format.bas" "SmartMath_CopyNormalize.bas" "SmartMath_About.bas" "SmartMath_Menu.bas" "MathParser.bas" "SmartMath.rc"
if exist "*.a" del "*.a"
if exist "*.o" del "*.o"
REM pause
