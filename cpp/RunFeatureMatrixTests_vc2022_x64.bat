@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo.
echo ==== Matrix combo: C=0 T=0 L=0 ====
set "CL=/DSMARTMATH_COMPLEX_NUMBERS=0 /DSMARTMATH_TIME_VALUES=0 /DSMARTMATH_LAMBDA_FUNCTIONS=0 /DSMARTMATH_FACTORINT=0"
call BuildTests_vc2022_x64.bat || goto :fail
Tests_MathParser.exe || goto :fail

echo.
echo ==== Matrix combo: C=0 T=0 L=1 ====
set "CL=/DSMARTMATH_COMPLEX_NUMBERS=0 /DSMARTMATH_TIME_VALUES=0 /DSMARTMATH_LAMBDA_FUNCTIONS=1"
call BuildTests_vc2022_x64.bat || goto :fail
Tests_MathParser.exe || goto :fail

echo.
echo ==== Matrix combo: C=0 T=1 L=0 ====
set "CL=/DSMARTMATH_COMPLEX_NUMBERS=0 /DSMARTMATH_TIME_VALUES=1 /DSMARTMATH_LAMBDA_FUNCTIONS=0"
call BuildTests_vc2022_x64.bat || goto :fail
Tests_MathParser.exe || goto :fail

echo.
echo ==== Matrix combo: C=0 T=1 L=1 ====
set "CL=/DSMARTMATH_COMPLEX_NUMBERS=0 /DSMARTMATH_TIME_VALUES=1 /DSMARTMATH_LAMBDA_FUNCTIONS=1"
call BuildTests_vc2022_x64.bat || goto :fail
Tests_MathParser.exe || goto :fail

echo.
echo ==== Matrix combo: C=1 T=0 L=0 ====
set "CL=/DSMARTMATH_COMPLEX_NUMBERS=1 /DSMARTMATH_TIME_VALUES=0 /DSMARTMATH_LAMBDA_FUNCTIONS=0"
call BuildTests_vc2022_x64.bat || goto :fail
Tests_MathParser.exe || goto :fail

echo.
echo ==== Matrix combo: C=1 T=0 L=1 ====
set "CL=/DSMARTMATH_COMPLEX_NUMBERS=1 /DSMARTMATH_TIME_VALUES=0 /DSMARTMATH_LAMBDA_FUNCTIONS=1"
call BuildTests_vc2022_x64.bat || goto :fail
Tests_MathParser.exe || goto :fail

echo.
echo ==== Matrix combo: C=1 T=1 L=0 ====
set "CL=/DSMARTMATH_COMPLEX_NUMBERS=1 /DSMARTMATH_TIME_VALUES=1 /DSMARTMATH_LAMBDA_FUNCTIONS=0"
call BuildTests_vc2022_x64.bat || goto :fail
Tests_MathParser.exe || goto :fail

echo.
echo ==== Matrix combo: C=1 T=1 L=1 ====
set "CL=/DSMARTMATH_COMPLEX_NUMBERS=1 /DSMARTMATH_TIME_VALUES=1 /DSMARTMATH_LAMBDA_FUNCTIONS=1"
call BuildTests_vc2022_x64.bat || goto :fail
Tests_MathParser.exe || goto :fail

set "CL="
echo.
echo ALL FEATURE MATRIX COMBINATIONS PASSED.
exit /b 0

:fail
set "CL="
echo.
echo FEATURE MATRIX FAILED.
exit /b 1
