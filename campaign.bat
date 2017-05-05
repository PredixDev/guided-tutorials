@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET FILE_NAME=%0
SET BRANCH=master

:GETOPTS
  IF /I [%1] == [-b] SET BRANCH=%2& SHIFT
  IF /I [%1] == [--branch] SET BRANCH=%2& SHIFT
  SHIFT & IF NOT [%1]==[] GOTO :GETOPTS
GOTO :AFTERGETOPTS

CALL :GETOPTS %*
:AFTERGETOPTS

IF [!BRANCH!]==[] (
  ECHO "Usage: %FILE_NAME% -b/--branch <branch>"
  EXIT /b 1
)

SET IZON_BAT=https://raw.githubusercontent.com/PredixDev/izon/1.0.0/izon.bat
SET IZON_SH=https://raw.githubusercontent.com/PredixDev/izon/1.0.0/izon.sh
SET VERSION_JSON=https://raw.githubusercontent.com/PredixDev/guided-tutorials/!BRANCH!/version.json

SET TUTORIAL=https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1569^&tag^=1719^&journey^=Hello%%20World^&resources^=1475,1569,1523

SET SHELL_SCRIPT_NAME=campaign
SET SHELL_SCRIPT=https://raw.githubusercontent.com/PredixDev/guided-tutorials/!BRANCH!/%SHELL_SCRIPT_NAME%.sh

GOTO START

:CHECK_FAIL
  IF NOT !errorlevel! EQU 0 (
    CALL :MANUAL
  )
GOTO :eof

:MANUAL
  ECHO.
  ECHO.
  ECHO Exiting tutorial.  You can manually go through the tutorial steps here
  ECHO !TUTORIAL!
GOTO :eof

:CHECK_PERMISSIONS
    echo Administrative permissions required. Detecting permissions...

    net session >nul 2>&1
    if %errorLevel% == 0 (
        echo Success: Administrative permissions confirmed.
    ) else (
        echo Failure: Current permissions inadequate.  This script installs tools, ensure you are launching Windows Command window by Right clicking and choosing 'Run as Administrator'.
        EXIT /b 1
    )
GOTO :eof

:INIT
  ECHO Let's start by verifying that you have the required tools installed.
  SET /p answer=Should we install the required tools if not already installed? (Git, Cloud Foundry CLI, Node.js)
  IF "!answer!"=="" (
    SET /p answer=Specify yes/no -
  )
  IF "!answer:~0,1!"=="y" SET doInstall=Y
  IF "!answer:~0,1!"=="Y" echo doInstall=Y

  if "!doInstall!"=="Y" (
    CALL :CHECK_PERMISSIONS
    IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!

    CALL :GET_DEPENDENCIES

    ECHO Calling %TEMP%\setup-windows.bat
    CALL "%TEMP%\setup-windows.bat" /git /cf /nodejs
    ECHO errorlevel=!errorlevel!
    IF NOT !errorlevel! EQU 0 (
      ECHO.
      ECHO "Unable to install tools.  Is there a proxy server?  Perhaps if you go on a regular internet connection (turning off any proxy variables), the tools portion of the install will succeed."
      EXIT /b !errorlevel!
    )
    ECHO.
    ECHO The required tools have been installed. Now you can proceed with the tutorial.
    pause
  )

GOTO :eof

:GET_DEPENDENCIES
  ECHO Getting Dependencies

  powershell -Command "(new-object net.webclient).DownloadFile('!VERSION_JSON!','%TEMP%\version.json')"
  powershell -Command "(new-object net.webclient).DownloadFile('!IZON_BAT!','%TEMP%\izon.bat')"

  CALL %TEMP%\izon.bat READ_DEPENDENCY local-setup LOCAL_SETUP_URL LOCAL_SETUP_BRANCH %TEMP%
  ECHO "LOCAL_SETUP_BRANCH=!LOCAL_SETUP_BRANCH!"
  SET SETUP_WINDOWS=https://raw.githubusercontent.com/PredixDev/local-setup/!LOCAL_SETUP_BRANCH!/setup-windows.bat
  rem SET SETUP_WINDOWS=https://raw.githubusercontent.com/PredixDev/local-setup/!LOCAL_SETUP_BRANCH!/setup-windows.bat

  ECHO !SETUP_WINDOWS!
  powershell -Command "(new-object net.webclient).DownloadFile('!SETUP_WINDOWS!','%TEMP%\setup-windows.bat')"

GOTO :eof

:START

PUSHD "%TEMP%"

ECHO.
ECHO Welcome to the Predix Campaign tutorial.
ECHO --------------------------------------------------------------
ECHO.
ECHO This is an automated script which will guide you through the tutorial.
ECHO.

CALL :INIT
CALL :CHECK_FAIL
IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!

POPD

ECHO Copy !SHELL_SCRIPT! to %TEMP%
powershell -Command "(new-object net.webclient).DownloadFile('!SHELL_SCRIPT!','%TEMP%\%SHELL_SCRIPT_NAME%.sh')"

PUSHD "%USERPROFILE%"
ECHO Running the %TEMP%\%SHELL_SCRIPT_NAME%.sh script using Git-Bash
ECHO.
"%PROGRAMFILES%\Git\bin\bash" --login -i -- "%TEMP%\%SHELL_SCRIPT_NAME%.sh" -b !BRANCH! --skip-setup
POPD
