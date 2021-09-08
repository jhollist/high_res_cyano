@echo off
setlocal

for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
rem Windows 8.1
if "%version%" == "6.3" goto INSTALLUSB
rem Windows 8
if "%version%" == "6.2" goto INSTALLUSB
rem Windows 7
if "%version%" == "6.1" goto INSTALLUSB

goto INSTALLFTDI

:INSTALLUSB
set /p PROMPTINSTALLUSB=Install Satlink3 and XLink 500/100 USB drivers (y/[n])?
if /i "%PROMPTINSTALLUSB%" neq "y" goto INSTALLFTDI
"Sutron Link Driver Installer Win7.exe"

:INSTALLFTDI
set /p PROMPTINSTALLFTDI=Install FTDI USB drivers for GPRS/CDMA/IridiumLink (y/[n])?
if /i "%PROMPTINSTALLFTDI%" neq "y" goto END
start CDM21216_Setup.exe

:END
endlocal
