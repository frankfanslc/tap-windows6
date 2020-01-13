@echo off

set CROSSCERT=digicert-high-assurance-ev.crt
set TIMESTAMP_SERVER=http://timestamp.digicert.com

set TAPDIR=%~dp0

if [%1]==[] goto USAGE

::
:: Build the TAP driver
::

echo Building the TAP driver

python buildtap.py -b --sdk=wdk

IF %ERRORLEVEL% NEQ 0 goto ERROR

echo Signing and timestamping the driver

:: Sign the cat file
signtool sign /tr %TIMESTAMP_SERVER% /td sha256 /fd sha256 /sha1 "%1" /v /ac %TAPDIR%\%CROSSCERT% %TAPDIR%\dist\amd64\tapmullvad0901.cat

IF %ERRORLEVEL% NEQ 0 goto ERROR

::
:: Build a CAB file for submission to the MS Hardware Dev Center
::

echo Building CAB file

>"dist\tap-windows6-amd64.ddf" (
    echo .OPTION EXPLICIT     ; Generate errors
    echo .Set CabinetFileCountThreshold=0
    echo .Set FolderFileCountThreshold=0
    echo .Set FolderSizeThreshold=0
    echo .Set MaxCabinetSize=0
    echo .Set MaxDiskFileCount=0
    echo .Set MaxDiskSize=0
    echo .Set CompressionType=MSZIP
    echo .Set Cabinet=on
    echo .Set Compress=on
    echo .Set CabinetNameTemplate=tap-windows6-amd64.cab
    echo .Set DestinationDir=Package
    echo .Set DiskDirectoryTemplate=dist
    echo %TAPDIR%dist\amd64\OemVista.inf
    echo %TAPDIR%dist\amd64\tapmullvad0901.cat
    echo %TAPDIR%dist\amd64\tapmullvad0901.sys
)

makecab /f "dist\tap-windows6-amd64.ddf"

IF %ERRORLEVEL% NEQ 0 goto ERROR

echo Signing and timestamping the CAB file

:: Sign the CAB file
signtool sign /tr %TIMESTAMP_SERVER% /td sha256 /fd sha256 /sha1 "%1" /v %TAPDIR%\dist\tap-windows6-amd64.cab

IF %ERRORLEVEL% NEQ 0 goto ERROR

exit /b 0

:USAGE

echo Usage: %0 ^<cert_sha1_hash^>
exit /b 1

:ERROR

exit /b 1
