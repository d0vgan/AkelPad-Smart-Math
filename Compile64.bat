@echo off
rem fbc flags (see also Compile32.bat):
rem   -strip     Passes -s to ld: remove symbol table / relocation info from the PE (smaller file).
rem   -O 2       FreeBASIC compiler optimization level on its IR before emitting C (-gen gcc).
rem   -Wc -Os    GCC: optimize for size.
rem   -Wc -O2    GCC: optimize for speed.
rem 32-bit DLL can be slightly larger than 64-bit for the same source: more stack spills / different
rem tuning in libgcc+runtime, x87 vs SSE paths, and x64 sometimes shrinking hot code via extra GPRs.
set "FB_HOME=C:\tools\FreeBASIC"
set "PATH=%PATH%;%FB_HOME%;%FB_HOME%\bin\win32"
set "OUT_DIR=%~dp0AkelFiles\Plugs64"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
windres -F pe-x86-64 -c 65001 -I "%FB_HOME%\inc\win\rc" -i SmartMath.rc -o "%OUT_DIR%\SmartMath_res.o"
if errorlevel 1 exit /b 1
fbc -dll -gen gcc -arch x86_64 -x "%OUT_DIR%\SmartMath.dll" -strip -O 2 -Wc -O2 "SmartMath.bas" "SmartMath_Config.bas" "SmartMath_Format.bas" "SmartMath_CopyNormalize.bas" "SmartMath_About.bas" "SmartMath_Menu.bas" "MathParser.bas" "%OUT_DIR%\SmartMath_res.o"
if exist "%OUT_DIR%\*.a" del "%OUT_DIR%\*.a"
if exist "%OUT_DIR%\*.o" del "%OUT_DIR%\*.o"
REM pause
