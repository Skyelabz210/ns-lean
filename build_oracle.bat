@echo off
cd /d "C:\Users\hackf\Projects\CRAM Explorer\cram_explorer_apr5_2026\workspace"
C:\Users\hackf\.cargo\bin\cargo build -p oracle_tools > "%TEMP%\build_oracle.txt" 2>&1
if %ERRORLEVEL%==0 (echo BUILD_OK) else (echo BUILD_FAIL)
type "%TEMP%\build_oracle.txt"
