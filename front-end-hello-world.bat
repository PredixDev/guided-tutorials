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
SET VERSION_JSON=https://raw.githubusercontent.com/PredixDev/guided-tutorials/!BRANCH!/version.json

SET TUTORIAL=https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1569^&tag^=1719^&journey^=Hello%%20World^&resources^=1475,1569,1523

SET SHELL_SCRIPT_NAME=front-end-world
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

:VERIFY_ANSWER
  IF "%1"=="" (
    SET /p answer=Specify (yes/no)
  ) ELSE (
    SET answer=%1
  )
  IF NOT "!answer:~0,1!"=="y" IF NOT "!answer:~0,1!"=="Y" EXIT /b 1
GOTO :eof

:INIT
  powershell -Command "(new-object net.webclient).DownloadFile('!VERSION_JSON!','%TEMP%\version.json')"
  powershell -Command "(new-object net.webclient).DownloadFile('!IZON_BAT!','%TEMP%\izon.bat')"

  CALL %TEMP%\izon.bat READ_DEPENDENCY local-setup LOCAL_SETUP_URL LOCAL_SETUP_BRANCH %TEMP%
  SET SETUP_WINDOWS=https://raw.githubusercontent.com/PredixDev/local-setup/!LOCAL_SETUP_BRANCH!/setup-windows.bat
GOTO :eof

:GET_DEPENDENCIES
  ECHO Getting Dependencies

  ECHO !SETUP_WINDOWS!
  powershell -Command "(new-object net.webclient).DownloadFile('!SETUP_WINDOWS!','%TEMP%\setup-windows.bat')"

  ECHO !SHELL_SCRIPT!
  powershell -Command "(new-object net.webclient).DownloadFile('!SHELL_SCRIPT!','%TEMP%\%SHELL_SCRIPT_NAME%.sh')"
GOTO :eof

:START

PUSHD "%TEMP%"

ECHO.
ECHO Welcome to the Predix Front-End Hello World tutorial..
ECHO --------------------------------------------------------------
ECHO.
ECHO This is an automated script which will guide you through the tutorial.
ECHO.
ECHO Let's start by verifying that you have the required tools installed.
SET /p answer=Should we install the required tools if not already installed?
CALL :VERIFY_ANSWER !answer!
CALL :CHECK_FAIL
IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!

CALL :INIT
CALL :CHECK_FAIL
IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!

CALL :GET_DEPENDENCIES
ECHO Calling %TEMP%\setup-windows.bat
CALL "%TEMP%\setup-windows.bat" /git /cf /nodejs /predixcli
CALL :CHECK_FAIL
IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!

ECHO.
ECHO The required tools have been installed. Now you can proceed with the tutorial.
pause

POPD

PUSHD "%USERPROFILE%"
ECHO Running the %TEMP%\%SHELL_SCRIPT_NAME%.sh script using Git-Bash
ECHO.
"%PROGRAMFILES%\Git\bin\bash" --login -i -- "%TEMP%\%SHELL_SCRIPT_NAME%.sh" !BRANCH! --skip-setup
POPD
