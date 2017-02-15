#!/bin/bash

#common functions called by guided tutorials
function pause() {
  read -n1 -r -p "Press any key to continue..."
  echo ""
}

function verifyCfLogin() {
  set +e
  local targetInfo
  targetInfo=$(cf target)
  set -e

  if [[ "${targetInfo/FAILED}" == "$targetInfo" ]] && [[ "${targetInfo/No org}" == "$targetInfo" ]] && [[ "${targetInfo/No space}" == "$targetInfo" ]]; then
    cf target
    echo ""
    echo "Looks like you are already logged in."
    pause
  else
    echo "Please login..."
    cf predix
  fi
}

function verifyPxLogin() {
  set +e
  local targetInfo
  targetInfo=$(predix target)
  set -e

  if [[ "${targetInfo/FAILED}" == "$targetInfo" ]] && [[ "${targetInfo/No org}" == "$targetInfo" ]] && [[ "${targetInfo/No space}" == "$targetInfo" ]]; then
    predix target
    echo ""
    echo "Looks like you are already logged in."
    pause
  else
    echo "Please login..."
    predix login
  fi
}

function echoAndRun() {
  echo $@
  $@
}

function check_internet() {
  set +e
  echo ""
  echo "Checking internet connection..."
  curl "http://www.ge.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy"
    echo "If you are behind a corporate proxy, set the 'http_proxy' and 'https_proxy' environment variables."
    exit 1
  fi
  echo "OK"
  echo ""
  set -e
}
