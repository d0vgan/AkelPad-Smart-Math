@echo off
setlocal EnableExtensions

rem SmartMath numeric profile gate: runs the width-generic suites for narrow SmFloat/SmInt/SmUInt choices.
rem   1) hard-coded width check (tools\check_type_literals.ps1 -Strict)
rem   2) Basic narrow profile  (-d SM_NARROW_TYPES: Single/Long/ULong)
rem   3) C++ narrow profile    (float/int/unsigned)
rem   4) C++ mixed profile     (double/int/unsigned: mantissa wider than the int)
rem All outputs go to %TEMP%\smartmath_profiles; the repository stays clean.
rem Wide profile (128-bit int, long double) needs emscripten: see internal-mathparser-build-gates.

cd /d "%~dp0"
set "ROOT=%CD%"
set "OUT=%TEMP%\smartmath_profiles"
if not exist "%OUT%" mkdir "%OUT%"
set "FAILED=0"

set "FB_HOME=C:\tools\FreeBASIC"
if exist "%FB_HOME%\bin\win64" (
  set "PATH=%PATH%;%FB_HOME%;%FB_HOME%\bin\win64"
  set "FBC_ARCH=-arch x86_64"
) else (
  set "PATH=%PATH%;%FB_HOME%;%FB_HOME%\bin\win32"
  set "FBC_ARCH="
)

set "VC_ROOT=%ProgramFiles%\Microsoft Visual Studio\2022"
if exist "%VC_ROOT%\Professional\VC\Auxiliary\Build\vcvarsall.bat" (
  call "%VC_ROOT%\Professional\VC\Auxiliary\Build\vcvarsall.bat" amd64 >nul
) else if exist "%VC_ROOT%\Community\VC\Auxiliary\Build\vcvarsall.bat" (
  call "%VC_ROOT%\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64 >nul
) else (
  echo ERROR: Could not find vcvarsall.bat
  exit /b 1
)

echo [1/4] Hard-coded width check ...
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\check_type_literals.ps1" -Strict
if errorlevel 1 (echo FAIL: type literal check & set "FAILED=1") else (echo PASS: type literal check)

echo [2/4] Basic narrow profile ...
fbc %FBC_ARCH% -d SM_NARROW_TYPES "tests\SmokeTest_MathParser.bas" "MathParser.bas" -x "%OUT%\smoke_narrow.exe" >"%OUT%\smoke_narrow.log" 2>&1
if errorlevel 1 (
  echo FAIL: Basic narrow build, see %OUT%\smoke_narrow.log
  set "FAILED=1"
) else (
  "%OUT%\smoke_narrow.exe" >"%OUT%\smoke_narrow.txt" 2>&1
  if errorlevel 1 (echo FAIL: Basic narrow run, see %OUT%\smoke_narrow.txt & set "FAILED=1") else (echo PASS: Basic narrow)
)

echo [3/4] C++ narrow profile (float/int/unsigned) ...
call :CppProfile narrow "/DSMARTMATH_FLOAT_TYPE=float /DSMARTMATH_INT_TYPE=int /DSMARTMATH_UINT_TYPE=unsigned"

echo [4/4] C++ mixed profile (double/int/unsigned) ...
call :CppProfile mixed "/DSMARTMATH_INT_TYPE=int /DSMARTMATH_UINT_TYPE=unsigned"

echo.
if "%FAILED%"=="0" (echo Type profile gates PASSED.) else (echo Type profile gates FAILED.)
exit /b %FAILED%

:CppProfile
set "NAME=%~1"
set "DEFS=%~2"
set "WORK=%OUT%\cpp_%NAME%"
if not exist "%WORK%" mkdir "%WORK%"
cl /nologo /O2 /EHsc /I"%ROOT%\cpp" %DEFS% /Fo"%WORK%\\" "%ROOT%\cpp\tests\Tests_MathParser.cpp" "%ROOT%\cpp\MathParser.cpp" "%ROOT%\cpp\MathParserFactorInt.cpp" "%ROOT%\cpp\MathParserRawResult.cpp" /Fe:"%WORK%\tests.exe" >"%WORK%\build.log" 2>&1
if errorlevel 1 (
  echo FAIL: C++ %NAME% build, see %WORK%\build.log
  set "FAILED=1"
  exit /b 0
)
"%WORK%\tests.exe" >"%WORK%\run.txt" 2>&1
if errorlevel 1 (echo FAIL: C++ %NAME% run, see %WORK%\run.txt & set "FAILED=1") else (echo PASS: C++ %NAME%)
exit /b 0
