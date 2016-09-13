@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET BRANCH=master
IF NOT "%1"=="" (
  SET BRANCH=%1
)

SET TUTORIAL=https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1475^&tag^=1719^&journey^=Hello%%20World
SET RESETVARS=https://raw.githubusercontent.com/PredixDev/local-setup/!BRANCH!/resetvars.vbs
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

:GET_DEPENDENCIES
  ECHO Getting Dependencies
  ECHO !RESETVARS!
  @powershell -Command "(new-object net.webclient).DownloadFile('!RESETVARS!','%TEMP%\resetvars.vbs')"
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
