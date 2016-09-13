@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set BRANCH=%1
GOTO START

:SETUP
  CALL :GET_DEPENDENCIES
  ECHO calling install-basics.bat
  CALL install-basics.bat %BRANCH%
  CALL :CHECK_FAIL
  ECHO.
GOTO :eof

:CHECK_FAIL
  IF NOT !errorlevel! EQU 0 (
    CALL :MANUAL
  )
GOTO :eof

:MANUAL
  ECHO.
  ECHO You can manually go through the tutorial steps here
  ECHO https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1475^&tag^=1719^&journey^=Hello%%20World
GOTO :eof

:GET_DEPENDENCIES
  ECHO Getting Dependencies
  ECHO https://raw.githubusercontent.com/PredixDev/guided-tutorials/%BRANCH%/install-basics.bat
  @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/%BRANCH%/install-basics.bat','install-basics.bat')" 
  ECHO https://raw.githubusercontent.com/PredixDev/guided-tutorials/%BRANCH%/simple-html-page.sh
  @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/%BRANCH%/simple-html-page.sh','simple-html-page.sh')" 
GOTO :eof


:START
  REM to execute this script, copy this develop or master command to a Windows Administrative Command window
  REM   @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/develop/simple-html-page.bat','simple-html-page.bat')"  && simple-html-page.bat develop
  REM   @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/master/simple-html-page.bat','simple-html-page.bat')"  && simple-html-page.bat master
PUSHD "%~dp0"

ECHO.
ECHO Welcome to the Predix Hello World tutorial.
ECHO --------------------------------------------------------------
ECHO.

CALL :SETUP
IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!
CALL predix.bat :RELOAD_ENV

ECHO.
ECHO The required tools have been installed. Now you can proceed with the tutorial.
pause

"%PROGRAMFILES%\Git\bin\bash" --login -i -- simple-html-page.sh --skip-setup

POPD

