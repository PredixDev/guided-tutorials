#!/bin/bash

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
    cf predix
  fi
}
