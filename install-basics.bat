@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET BRANCH=%1
GOTO START

:MANUAL
  ECHO.
  ECHO Okay.  You can manually install tools by following links in the Setup section.
  ECHO.
GOTO :eof

:CHECK_FAIL
  IF NOT !errorlevel! EQU 0 (
    CALL :MANUAL
  )
GOTO :eof

:GET_DEPENDENCIES
  ECHO https://raw.githubusercontent.com/PredixDev/guided-tutorials/%BRANCH%/resetvars.vbs
  @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/%BRANCH%/resetvars.vbs','resetvars.vbs')" 
  ECHO https://raw.githubusercontent.com/PredixDev/guided-tutorials/%BRANCH%/predix.bat
  @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/%BRANCH%/predix.bat','predix.bat')" 
GOTO :eof

:START
  REM to execute this script, copy this develop or master command to a Windows Administrative Command window
  REM   @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/develop/install-basics.bat','install-basics.bat')"  && install-basics.bat develop
  REM   @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/master/install-basics.bat','install-basics.bat')"  && install-basics.bat master
  
  PUSHD "%~dp0"
  
  ECHO.
  ECHO.
  ECHO Welcome to the Predix Windows Basics installer.
  ECHO --------------------------------------------------------------
  ECHO.
  ECHO Getting Dependencies
  CALL :GET_DEPENDENCIES
  ECHO.
  SET /p answer=Should we install the required tools if not already installed?
  CALL predix.bat :VERIFY_ANSWER !answer!
  ECHO. 
  CALL :CHECK_FAIL
  IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!a
  CALL predix.bat :STD_SETUP
  IF NOT !errorlevel! EQU 0   EXIT /b !errorlevel!
  CALL predix.bat :RELOAD_ENV
  IF NOT !errorlevel! EQU 0   EXIT /b !errorlevel!
  
  ECHO.
  ECHO The basic tools have been installed.
  pause

  POPD
