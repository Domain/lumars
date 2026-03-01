@echo off
REM Build Lua (static and/or dynamic) for Windows
REM Must be run from "Developer Command Prompt for VS 2022 (x64)" or similar
REM Usage: build_lua.bat [version] [mode]
REM   version: Lua version (e.g., 5.1, 5.2, 5.3, 5.4, 5.5). Default: 5.4.6
REM   mode: static (default), dynamic, or all

setlocal enabledelayedexpansion

REM Parse arguments
set LUA_VERSION=%1
set MODE=%2

if "%LUA_VERSION%"=="" set LUA_VERSION=5.4.6
if "%MODE%"=="" set MODE=static

REM Normalize version for library naming (e.g., 5.4.6 -> 54, 5.1.5 -> 51)
for /f "tokens=1,2 delims=." %%a in ("%LUA_VERSION%") do (
    set LUA_MAJOR=%%a
    set LUA_MINOR=%%b
)
set LUA_LIB_NAME=lua%LUA_MAJOR%%LUA_MINOR%

set LUA_URL=https://www.lua.org/ftp/lua-%LUA_VERSION%.tar.gz
set SCRIPT_DIR=%~dp0
set DEPS_DIR=%SCRIPT_DIR%deps
set WORK_DIR=%TEMP%\lua_build_%RANDOM%

echo Building Lua %LUA_VERSION% (mode: %MODE%, lib name: %LUA_LIB_NAME%)
echo Work dir: %WORK_DIR%
echo Deps dir: %DEPS_DIR%\win64

if not exist "%DEPS_DIR%\win64" mkdir "%DEPS_DIR%\win64"

REM Prepare work dir
mkdir "%WORK_DIR%" 2>nul
echo Downloading Lua %LUA_VERSION%...
curl -L -o "%WORK_DIR%\lua-%LUA_VERSION%.tar.gz" "%LUA_URL%"
if errorlevel 1 (
    echo Failed to download Lua source
    exit /b 1
)

cd /d "%WORK_DIR%"
echo Extracting...
tar -xzf "lua-%LUA_VERSION%.tar.gz"
if errorlevel 1 (
    echo Failed to extract archive
    exit /b 1
)

cd /d "lua-%LUA_VERSION%\src"

:BuildStatic
if /I "%MODE%"=="dynamic" goto BuildDynamic
if /I "%MODE%"=="all" goto BuildStaticDo
if /I "%MODE%"=="static" goto BuildStaticDo

echo Unknown mode: %MODE%
echo Usage: build_lua.bat [version] [mode]
echo   version: Lua version (e.g., 5.1, 5.2, 5.3, 5.4, 5.5). Default: 5.4.6
echo   mode: static (default), dynamic, or all
goto Cleanup

:BuildStaticDo
echo Compiling Lua sources with /MT (static CRT)...
del /Q *.obj 2>nul
for %%f in (*.c) do (
    echo Compiling %%f
    cl /c /O2 /W3 /MT /GS- /Gm- /Gy- %%f
    if errorlevel 1 (
        echo Compilation of %%f failed
        exit /b 1
    )
)

echo Creating static library %LUA_LIB_NAME%.lib...
lib /OUT:%LUA_LIB_NAME%.lib *.obj
if errorlevel 1 (
    echo Failed to create static library
    exit /b 1
)

echo Copying %LUA_LIB_NAME%.lib to deps...
copy /Y %LUA_LIB_NAME%.lib "%DEPS_DIR%\win64\%LUA_LIB_NAME%.lib"
if errorlevel 1 (
    echo Failed to copy library
    exit /b 1
)

echo Static build complete. Library: %DEPS_DIR%\win64\%LUA_LIB_NAME%.lib

if /I "%MODE%"=="static" goto Cleanup

:BuildDynamic
echo Compiling Lua sources for DLL with /MD (dynamic CRT)...
del /Q *.obj 2>nul
for %%f in (*.c) do (
    if /I "%%f"=="lua.c" (
        echo Skipping %%f
    ) else (
        echo Compiling %%f
        cl /c /O2 /W3 /MD /GS- /Gm- /Gy- /DLUA_BUILD_AS_DLL %%f
        if errorlevel 1 (
            echo Compilation of %%f failed
            exit /b 1
        )
    )
)

echo Linking %LUA_LIB_NAME%.dll and import library...
link /DLL /OUT:%LUA_LIB_NAME%.dll *.obj /IMPLIB:%LUA_LIB_NAME%.lib
if errorlevel 1 (
    echo Failed to link %LUA_LIB_NAME%.dll
    exit /b 1
)

REM Copy DLL and import library to deps
if exist %LUA_LIB_NAME%.dll (
    copy /Y %LUA_LIB_NAME%.dll "%DEPS_DIR%\win64\%LUA_LIB_NAME%.dll"
)
if exist %LUA_LIB_NAME%.lib (
    copy /Y %LUA_LIB_NAME%.lib "%DEPS_DIR%\win64\%LUA_LIB_NAME%.lib"
)

echo Dynamic build complete. Files copied to %DEPS_DIR%\win64

:Cleanup
echo.
echo =========================================
echo Build finished for Lua %LUA_VERSION% (mode: %MODE%)
echo =========================================
echo.
echo Next: Update dub.sdl with new configuration if needed
echo   dub clean
echo   dub test --config=lua%LUA_MAJOR%%LUA_MINOR%
echo   dub test --config=lua%LUA_MAJOR%%LUA_MINOR%-dynamic
echo.

REM Cleanup temp work dir and return to script dir
cd /d %SCRIPT_DIR%
if exist "%WORK_DIR%" (
    rmdir /s /q "%WORK_DIR%"
)

echo Done.
exit /b 0
