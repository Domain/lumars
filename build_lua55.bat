@echo off
REM Build Lua 5.5 binaries for Windows using Visual Studio
REM This script downloads the Lua 5.5 source and builds it

setlocal enabledelayedexpansion

set LUA_VERSION=5.5.0
set LUA_URL=https://www.lua.org/ftp/lua-%LUA_VERSION%.tar.gz
set SCRIPT_DIR=%~dp0
set DEPS_DIR=%SCRIPT_DIR%deps
set WORK_DIR=%TEMP%\lua_build_%RANDOM%

echo Building Lua 5.5 from source...
echo Working directory: %WORK_DIR%
echo Dependencies directory: %DEPS_DIR%

REM Create deps directories if they don't exist
if not exist "%DEPS_DIR%\win64" mkdir "%DEPS_DIR%\win64"

REM Download using curl
echo Downloading Lua %LUA_VERSION%...
mkdir "%WORK_DIR%" 2>nul
curl -L -o "%WORK_DIR%\lua-%LUA_VERSION%.tar.gz" "%LUA_URL%"

if errorlevel 1 (
    echo Failed to download Lua source
    exit /b 1
)

REM Extract using 7z or tar (Windows 10+)
cd /d "%WORK_DIR%"
if exist "C:\Program Files\7-Zip\7z.exe" (
    "C:\Program Files\7-Zip\7z.exe" x "lua-%LUA_VERSION%.tar.gz"
    "C:\Program Files\7-Zip\7z.exe" x "lua-%LUA_VERSION%.tar"
) else (
    tar -xzf "lua-%LUA_VERSION%.tar.gz"
)

cd /d "lua-%LUA_VERSION%"

REM Build for Windows x86_64 using Visual Studio
echo Building Lua 5.5 for Windows x86_64...
cd src

REM Compile all lua source files
for %%f in (*.c) do (
    echo Compiling %%f
    cl /c /O2 /W3 %%f
)

REM Create library
echo Creating static library...
lib /out:lua55.lib *.obj

REM Copy to deps directory
copy lua55.lib "%DEPS_DIR%\win64\lua55.lib"
echo Done! Created: %DEPS_DIR%\win64\lua55.lib

REM Cleanup
cd /d %WORK_DIR%
cd ..
del /s /q *
cd ..
rmdir /s /q "%WORK_DIR%"

echo.
echo =========================================
echo Lua 5.5 build complete!
echo =========================================
echo Binaries have been placed in %DEPS_DIR%
echo.
echo To use Lua 5.5, build with:
echo   dub build --config=lua55
echo.
pause
