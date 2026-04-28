@echo off

call "%~dp0BuildTestsAnalyze_vc2022_x64.bat"
if errorlevel 1 exit /b 1

call "%~dp0BuildTests_vc2022_x64.bat"
if errorlevel 1 exit /b 1

"%~dp0MathParserTests.exe"
if errorlevel 1 exit /b 1
exit /b 0
