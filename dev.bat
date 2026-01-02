@echo off
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "JAVA_HOME="

for /d %%D in ("C:\Program Files\Java\jdk-21*" "C:\Program Files\Java\temurin-21*" "C:\Program Files\Java\zulu-21*") do (
  if exist "%%~fD\bin\java.exe" (
    set "JAVA_HOME=%%~fD"
    goto :found
  )
)

:found
if not defined JAVA_HOME (
  echo Fehler: Kein Java 21 gefunden. Dieses Template benoetigt JDK 21.
  echo Bitte installiere JDK 21 und setze JAVA_HOME.
  exit /b 1
)

set "PATH=%JAVA_HOME%\bin;%PATH%"
echo Nutze JAVA_HOME=%JAVA_HOME%

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%dev.ps1" %*
