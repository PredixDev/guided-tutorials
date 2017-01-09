#!/bin/bash
set -e

BRANCH="master"
SKIP_SETUP=false

while (( "$#" )); do

if [[ $1 == "--skip-setup" ]]; then
  SKIP_SETUP=true
else
  BRANCH=$1
fi

shift

done

TUTORIAL="https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1475&tag=1719&journey=Hello%20World&resources=1475,1569,1523"
PREDIX_SH="https://raw.githubusercontent.com/PredixDev/guided-tutorials/$BRANCH/predix.sh"
SETUP_MAC="https://raw.githubusercontent.com/PredixDev/local-setup/$BRANCH/setup-mac.sh"

function manual() {
  echo ""
  echo "Exiting tutorial. You can manually go through the tutorial steps here"
  echo "$TUTORIAL"
  echo ""
}

function checkExit() {
  if [ $? -ne 0 ]; then
    manual
  fi
}

trap checkExit EXIT

function verifyAnswer() {
  if [[ -z $answer ]]; then
    echo -n "Specify (yes/no)> "
    read answer
  fi
  if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
    return
  fi
  exit 1
}

function check_internet() {
  set +e
  echo ""
  echo "Checking internet connection..."
  curl "http://google.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy"
    echo "If you are behind a corporate proxy, set the 'http_proxy' and 'https_proxy' environment variables."
    exit 1
  fi
  echo "OK"
  echo ""
  set -e
}

function run_setup() {
  check_internet
  bash <(curl -s -L "$SETUP_MAC") --git --cf
}

if $SKIP_SETUP; then
  check_internet
  eval "$(curl -s -L $PREDIX_SH)"
else
  echo "Welcome to the Predix Hello World tutorial."
  echo "--------------------------------------------------------------"
  echo ""
  echo "This is an automated script which will guide you through the tutorial."
  echo ""
  echo "Let's start by verifying that you have the required tools installed."
  read -p "Should we install the required tools if not already installed?> " -t 30 answer
  verifyAnswer answer
  echo ""

  run_setup
  eval "$(curl -s -L $PREDIX_SH)"

  echo ""
  echo "The required tools have been installed. Now you can proceed with the tutorial."
  pause
fi

echo ""
echo "Step 1. Sign in to Predix Cloud if not already signed in"
echo "--------------------------------------------------------------"
verifyCfLogin

echo ""
echo "Step 2. Download the Predix Hello World web application"
echo "--------------------------------------------------------------"
if [ -d Predix-HelloWorld-WebApp ]; then
  echo "The Predix-HelloWorld-WebApp already exists."
  read -p "Should we delete it and proceed?> " -t 30 answer
  verifyAnswer answer
  echo ""
  rm -rf Predix-HelloWorld-WebApp
fi
echoAndRun git clone https://github.com/PredixDev/Predix-HelloWorld-WebApp.git
echoAndRun cd Predix-HelloWorld-WebApp

echo ""
echo "Step 3. Give the application a unique name"
echo "--------------------------------------------------------------"
echo "We will give the application a unique name by editing the manifest file (manifest.yml)."
echo "This file contains all the information about the application."
echo ""
read -p "Enter a suffix for the application name> " -t 30 suffix
suffix=${suffix// /-}
suffix=${suffix//_/-}

app_name=Predix-HelloWorld-WebApp-$suffix
sed -i -e "s/name: .*Predix-HelloWorld-WebApp.*$/name: $app_name/" manifest.yml
echo "Application name set to: $app_name"
echo "This is what the manifest file looks like"
echoAndRun cat manifest.yml
echo ""
echo "Take a moment to study the contents of the manifest file."
pause

echo ""
echo "Step 4. Push the app to the cloud"
echo "--------------------------------------------------------------"
echoAndRun cf push

echo ""
echo "Step 5. Using a browser, visit the URL to see the app"
echo "--------------------------------------------------------------"
url=$(cf app $app_name | grep urls | awk '{print $2}')
echo "You have successfully pushed your first Predix application."
echo "Enter the URL below in a browser to view the application."
echo ""
echo "https://$url"
echo ""
