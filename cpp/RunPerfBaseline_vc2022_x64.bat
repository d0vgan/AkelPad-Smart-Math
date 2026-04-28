@echo off
rem C++-only sequential perf baseline runner (avoids parallel obj-file lock contention).
cd /d "%~dp0"

echo [1/2] Mixed-scalar baseline: 300000 iterations x 5 repeats
call "%~dp0BuildRunPerfHotPath_vc2022_x64.bat" 300000 5
if errorlevel 1 exit /b 1

echo [2/2] Mixed-scalar baseline: 1000000 iterations x 3 repeats
call "%~dp0BuildRunPerfHotPath_vc2022_x64.bat" 1000000 3
if errorlevel 1 exit /b 1

echo Perf baseline runs PASSED.
exit /b 0
