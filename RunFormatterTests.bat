@echo off
setlocal

rem Formatter regression tests (SmartMath_Format.bas). Run from repo root.
set "FB_HOME=C:\tools\FreeBASIC"
set "PATH=%PATH%;%FB_HOME%"

echo ==========================================
echo SmartMath formatter regression tests
echo ==========================================
echo.
echo [1/2] Compiling FormatterRegressionTests.exe ...
fbc "FormatterTest_Globals.bas" "FormatterRegressionTests.bas" "SmartMath_Format.bas" -x "FormatterRegressionTests.exe"
if errorlevel 1 goto :compile_failed

echo.
echo [2/2] Running FormatterRegressionTests.exe ...
echo.
"FormatterRegressionTests.exe"
set "TEST_EXIT=%ERRORLEVEL%"

echo.
if not "%TEST_EXIT%"=="0" goto :tests_failed

echo Formatter tests PASSED.
exit /b 0

:compile_failed
echo.
echo Compilation failed.
exit /b 1

:tests_failed
echo Formatter tests FAILED (exit code %TEST_EXIT%).
exit /b %TEST_EXIT%
