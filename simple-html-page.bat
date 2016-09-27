@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET BRANCH=master
IF NOT "%1"=="" (
  SET BRANCH=%1
)

SET TUTORIAL=https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1475^&tag^=1719^&journey^=Hello%%20World^&resources^=1475,1569,1523
SET SETUP_WINDOWS=https://raw.githubusercontent.com/PredixDev/local-setup/!BRANCH!/setup-windows.bat
SET SHELL_SCRIPT=https://raw.githubusercontent.com/PredixDev/guided-tutorials/!BRANCH!/simple-html-page.sh

GOTO START

:CHECK_FAIL
  IF NOT !errorlevel! EQU 0 (
    CALL :MANUAL
  )
GOTO :eof

:MANUAL
  ECHO.
  ECHO You can manually go through the tutorial steps here
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

:GET_DEPENDENCIES
  ECHO Getting Dependencies
  ECHO !SETUP_WINDOWS!
  @powershell -Command "(new-object net.webclient).DownloadFile('!SETUP_WINDOWS!','%TEMP%\setup-windows.bat')"
  ECHO !SHELL_SCRIPT!
  @powershell -Command "(new-object net.webclient).DownloadFile('!SHELL_SCRIPT!','%TEMP%\simple-html-page.sh')"
GOTO :eof

:START
REM to execute this script, copy this develop or master command to a Windows Administrative Command window
REM   @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/develop/simple-html-page.bat','%TEMP%\simple-html-page.bat')"  && "%TEMP%\simple-html-page.bat" develop
REM   @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/master/simple-html-page.bat','%TEMP%\simple-html-page.bat')"  && "%TEMP%\simple-html-page.bat" master

PUSHD "%TEMP%"

ECHO.
ECHO Welcome to the Predix Hello World tutorial.
ECHO --------------------------------------------------------------
ECHO.
ECHO This is an automated script which will guide you through the tutorial.
ECHO.
ECHO Let's start by verifying that you have the required tools installed.
SET /p answer=Should we install the required tools if not already installed?
CALL :VERIFY_ANSWER !answer!
CALL :CHECK_FAIL
IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!

CALL :GET_DEPENDENCIES
ECHO Calling %TEMP%\setup-windows.bat
CALL "%TEMP%\setup-windows.bat" /git /cf
CALL :CHECK_FAIL
IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!

ECHO.
ECHO The required tools have been installed. Now you can proceed with the tutorial.
pause

POPD

PUSHD "%USERPROFILE%"
ECHO Running the %TEMP%\simple-html-page.sh script using Git-Bash
ECHO.
"%PROGRAMFILES%\Git\bin\bash" --login -i -- "%TEMP%\simple-html-page.sh" !BRANCH! --skip-setup
POPD
