call %* 
@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
exit /b

:VERIFY_ANSWER
  IF "%1"=="" (
    SET /p answer=Specify (yes/no)
  ) ELSE (
    SET answer=%1
  )
  IF NOT "!answer:~0,1!"=="y" IF NOT "!answer:~0,1!"=="Y" EXIT /b 1
GOTO :eof

:RELOAD_ENV
  resetvars.vbs
  CALL "%TEMP%\resetvars.bat" >$null
GOTO :eof

:CHECK_INTERNET_CONNECTION
  ECHO Checking internet connection...
  @powershell -Command "(new-object net.webclient).DownloadString('http://www.google.com')" >$null 2>&1
  IF NOT !errorlevel! EQU 0 (
    ECHO Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy
    EXIT /b !errorlevel!
  )
  ECHO OK
GOTO :eof

:GET_WINDOWS_FILES
  REM   @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/master/install-basics.bat','install-basics.bat')" >$null 2>&1
  ECHO Getting Files...
  @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/master/resetvars.vbs','resetvars.vbs')" >$null 2>&1
  @powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/master/predix.bat','predix.bat')" >$null 2>&1
  IF NOT !errorlevel! EQU 0 (
    ECHO Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy
    EXIT /b !errorlevel!
  )
  ECHO OK
GOTO :eof

:INSTALL_CHOCO
  where choco >$null 2>&1
  IF NOT !errorlevel! EQU 0 (
    ECHO Installing chocolatey...
    @powershell -NoProfile -ExecutionPolicy unrestricted -Command "(iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))) >$null 2>&1" && SET PATH="%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    CALL :CHECK_FAIL
    CALL :RELOAD_ENV
  )
GOTO :eof

:INSTALL_CF
  CALL :CHOCO_INSTALL cloudfoundry-cli cf

  SETLOCAL
  IF EXIST "%ProgramFiles(x86)%" (
    SET filename=predix_win64.exe
  ) ELSE (
  SET filename=predix_win32.exe
  )
  ( cf plugins | findstr "Predix" >$null 2>&1 ) || cf install-plugin -f https://github.com/PredixDev/cf-predix/releases/download/1.0.0/!filename!
  ENDLOCAL

  IF NOT !errorlevel! EQU 0 (
    ECHO If you are behind a corporate proxy, set the 'http_proxy' and 'https_proxy' environment variables.
    ECHO Commands to set proxy:
    ECHO set http_proxy="http://<proxy-host>:<proxy-port>"
    ECHO set https_proxy="http://<proxy-host>:<proxy-port>"
    EXIT /b !errorlevel!
  )
GOTO :eof

:CHOCO_INSTALL
  SETLOCAL
  SET tool=%1
  SET cmd=%1
  IF NOT "%2"=="" (
    SET cmd=%2
  )
  where !cmd! >$null 2>&1
  IF NOT !errorlevel! EQU 0 (
    choco install -y --allow-empty-checksums %1
    CALL :CHECK_FAIL
    CALL :RELOAD_ENV
  ) ELSE (
    ECHO %1 already installed
    ECHO.
  )
ENDLOCAL & GOTO :eof

:CHECK_FAIL
  IF NOT !errorlevel! EQU 0 (
    CALL :MANUAL
    EXIT /b !errorlevel!
  )
GOTO :eof

:SETUP
  REM These are bare minimum for all Predix tutorials
  CALL :CHECK_INTERNET_CONNECTION
  CALL :CHECK_FAIL
  CALL :INSTALL_CHOCO
  CALL :CHECK_FAIL
  CALL :CHOCO_INSTALL git
  CALL :CHECK_FAIL
  CALL :INSTALL_CF
  CALL :CHECK_FAIL
GOTO :eof





