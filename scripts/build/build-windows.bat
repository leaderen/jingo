@echo off
REM ============================================================================
REM JinGo Windows Build Script
REM ============================================================================
REM Usage: build-windows.bat [clean] [debug]
REM   clean - Clean previous build
REM   debug - Build in Debug mode
REM ============================================================================

echo ========================================
echo JinGo VPN - Windows Build
echo ========================================
echo.

REM Execute the shell script using MSYS2 bash
D:\msys64\usr\bin\bash.exe "%~dp0build-windows.sh" %*

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Build completed!
echo.
pause
