@echo off
setlocal

rem SmartMath parser smoke tests runner
rem Usage:
rem   1) Double-click RunSmokeTests.bat
rem   2) Or run from terminal in project root: RunSmokeTests.bat

set "FB_HOME=C:\tools\FreeBASIC"
set "PATH=%PATH%;%FB_HOME%"

echo ==========================================
echo SmartMath parser smoke tests
echo ==========================================
echo.
echo [1/3] Compiling SmokeTest_MathParser.bas ...
fbc "SmokeTest_MathParser.bas" "MathParser.bas" -x "SmokeTest_MathParser.exe"
if errorlevel 1 goto :compile_failed

echo.
echo [2/3] Running SmokeTest_MathParser.exe ...
echo.
"SmokeTest_MathParser.exe"
set "TEST_EXIT=%ERRORLEVEL%"

echo.
echo [3/3] Done.
if not "%TEST_EXIT%"=="0" goto :tests_failed

echo Smoke tests PASSED.
exit /b 0

:compile_failed
echo.
echo Compilation failed.
exit /b 1

:tests_failed
echo Smoke tests FAILED (exit code %TEST_EXIT%).
exit /b %TEST_EXIT%
