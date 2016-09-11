@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

GOTO START

:SETUP
  CALL predix.bat :SETUP
  CALL predix.bat :GET_WINDOWS_FILES
GOTO :eof

:MANUAL
  ECHO.
  ECHO You can manually go through the tutorial steps here
  ECHO https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1475^&tag^=1719^&journey^=Hello%%20World
GOTO :eof

:START
  PUSHD "%~dp0"

  ECHO Welcome to the Predix Windows Basics installer.
  ECHO --------------------------------------------------------------
  ECHO.
  ECHO This is an automated script which will guide you through the tutorial.
  ECHO.
  ECHO Let's start by verifying that you have the required tools installed.
  SET /p answer=Should we install the required tools if not already installed?
  CALL :VERIFY_ANSWER !answer!
  CALL :CHECK_FAIL
  IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!
  ECHO.

  CALL :SETUP
  CALL :RELOAD_ENV

  ECHO.
  ECHO The required tools have been installed. Now you can proceed with the tutorial.
  ECHO Press any key to continue...
  pause

  POPD

