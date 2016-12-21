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

TUTORIAL="https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1569&tag=1719&journey=Hello%20World&resources=1475,1569,1523"
PREDIX_SH="https://raw.githubusercontent.com/PredixDev/guided-tutorials/$BRANCH/predix.sh"
SETUP_MAC="https://raw.githubusercontent.com/PredixDev/local-setup/$BRANCH/setup-mac.sh"

function manual() {
  echo ""
  echo "You can manually go through the tutorial steps here"
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
  echo "Did not receive an answer, exiting tutorial"
  echo ""
  exit 1
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

function run_setup() {
  check_internet
  bash <(curl -s -L "$SETUP_MAC") --git --cf --nodejs
}

if $SKIP_SETUP; then
  check_internet
  eval "$(curl -s -L $PREDIX_SH)"
else
  echo "Welcome to the Predix Front-End Hello World tutorial."
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
echo "Step 1. Download the predix-nodejs-starter app"
echo "--------------------------------------------------------------"
if [ -d predix-nodejs-starter ]; then
  echo "The predix-nodejs-starter already exists."
  read -p "Should we delete it and proceed?> " -t 30 answer
  verifyAnswer answer
  echo ""
  rm -rf predix-nodejs-starter
fi
echoAndRun git clone https://github.com/PredixDev/predix-nodejs-starter.git
echoAndRun cd predix-nodejs-starter

echo ""
echo "Step 2. Build the node application"
echo "--------------------------------------------------------------"
echoAndRun npm install

echo ""
echo "Step 3. Give the application a unique name"
echo "--------------------------------------------------------------"
read -p "Enter a prefix for the application name> " -t 30 prefix
prefix=${prefix// /-}
prefix=${prefix//_/-}

app_name=$prefix-predix-nodejs-starter
sed -i -e "s/name: .*predix-nodejs-starter/name: $app_name/" manifest.yml
echo "App name set to: $app_name"

echo ""
echo "Step 4. Sign in to Predix Cloud if not already signed in"
echo "--------------------------------------------------------------"
verifyCfLogin

echo ""
echo "Step 5. Push the app to the cloud"
echo "--------------------------------------------------------------"
echoAndRun cf push

echo ""
echo "Step 6. Using a browser, visit the url to see the app"
echo "--------------------------------------------------------------"
url=$(cf app $app_name | grep urls | awk '{print $2}')
echo "https://$url"
echo "Note: You won't be able to click the links on the html page until you have configured it with UAA, which you will do in a later tutorial."
