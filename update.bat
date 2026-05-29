@echo off
title Kirsch Scheme Builder - Update
setlocal enabledelayedexpansion

set "REPO_OWNER=manfredzimmer"
set "REPO_NAME=Kirsch-Scheme-Builder"
set "BRANCH=main"

set "SCRIPT_DIR=%~dp0"
set "LOCAL_VERSION=%SCRIPT_DIR%version.txt"
set "LOCAL_HTML=%SCRIPT_DIR%index.html"

set "TEMP_DIR=%TEMP%\kirsch-update"
set "REMOTE_VERSION_FILE=%TEMP_DIR%\version.txt"
set "NEW_HTML=%SCRIPT_DIR%index.html.new"
set "NEW_VERSION=%TEMP_DIR%\version.new"

set "POWERSHELL=powershell -NoProfile -Command"

cls
echo.
echo ========================================
echo  Kirsch Scheme Builder - Update
echo ========================================
echo.
echo Checking for updates...
echo.

if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

%POWERSHELL% "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/%REPO_OWNER%/%REPO_NAME%/%BRANCH%/version.txt' -OutFile '%REMOTE_VERSION_FILE%' -UseBasicParsing -ErrorAction Stop } catch { exit 1 }}"

if %ERRORLEVEL% NEQ 0 (
    echo [FEHLER] Keine Internetverbindung oder GitHub nicht erreichbar.
    echo         Bitte ueberpruefe deine Internetverbindung.
    echo.
    pause
    exit /b 1
)

if not exist "%REMOTE_VERSION_FILE%" (
    echo [FEHLER] Konnte Versionsinformationen nicht abrufen.
    echo.
    pause
    exit /b 1
)

set "LOCAL_VER="
if exist "%LOCAL_VERSION%" (
    set /p LOCAL_VER=<"%LOCAL_VERSION%"
)

set /p REMOTE_VER=<"%REMOTE_VERSION_FILE%"

echo  Aktuelle Version:  %LOCAL_VER%
echo  Verfuegbare Version: %REMOTE_VER%
echo.

if "%LOCAL_VER%"=="%REMOTE_VER%" (
    echo Du hast bereits die neueste Version ^(%REMOTE_VER%^).
    echo.
    pause
    exit /b 0
)

if "%LOCAL_VER%"=="" (
    echo Erstmalige Einrichtung. Lade Kirsch Scheme Builder herunter...
) else (
    echo Update verfuegbar: %LOCAL_VER% -^> %REMOTE_VER%
)
echo.

echo [1/2] Lade index.html herunter...
%POWERSHELL% "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/%REPO_OWNER%/%REPO_NAME%/%BRANCH%/index.html' -OutFile '%NEW_HTML%' -UseBasicParsing -ErrorAction Stop } catch { exit 1 }}"

if %ERRORLEVEL% NEQ 0 (
    echo [FEHLER] Konnte index.html nicht herunterladen.
    echo.
    pause
    exit /b 1
)

echo [2/2] Lade version.txt herunter...
%POWERSHELL% "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/%REPO_OWNER%/%REPO_NAME%/%BRANCH%/version.txt' -OutFile '%NEW_VERSION%' -UseBasicParsing -ErrorAction Stop } catch { exit 1 }}"

if %ERRORLEVEL% NEQ 0 (
    echo [FEHLER] Konnte version.txt nicht herunterladen.
    echo.
    pause
    exit /b 1
)

echo.
echo Wende Update an...

move /Y "%NEW_HTML%" "%LOCAL_HTML%" >nul
move /Y "%NEW_VERSION%" "%LOCAL_VERSION%" >nul

rmdir /S /Q "%TEMP_DIR%" 2>nul

echo.
echo Update erfolgreich abgeschlossen!
echo.

echo Starte Kirsch Scheme Builder...
start "" "%LOCAL_HTML%"

exit /b 0
