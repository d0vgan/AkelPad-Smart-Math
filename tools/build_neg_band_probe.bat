@echo off
setlocal
set "FB_HOME=C:\tools\FreeBASIC"
set "PATH=%PATH%;%FB_HOME%;%FB_HOME%\bin\win64"
cd /d "%~dp0.."
fbc -strip -O 2 "tools\NegBandProbe.bas" "MathParser.bas" -x "tools\NegBandProbe.exe"
exit /b %ERRORLEVEL%
