#!/bin/bash
set -e

SKIP_SETUP=false
BRANCH="master"

while (( "$#" )); do
opt="$1"
case $opt in
  -b|--branch)
    BRANCH="$2"
    shift
  ;;
  --skip-setup)
    SKIP_SETUP=true
  ;;
esac
shift
done

if [[ -z $BRANCH ]]; then
  echo "Usage: $0 -b/--branch <branch> [--skip-setup]"
  exit 1
fi

IZON_SH="https://raw.githubusercontent.com/PredixDev/izon/1.0.0/izon.sh"
VERSION_JSON="https://raw.githubusercontent.com/PredixDev/guided-tutorials/$BRANCH/version.json"
PREDIX_SH="https://raw.githubusercontent.com/PredixDev/guided-tutorials/$BRANCH/predix.sh"

TUTORIAL="https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1569&tag=1719&journey=Hello%20World&resources=1475,1569,1523"

PREDIX_NODEJS_STARTER="predix-nodejs-starter"

function manual() {
  echo ""
  echo ""
  echo "Exiting tutorial.  You can manually go through the tutorial steps here"
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

function init() {
  check_internet

  curl -s -O $VERSION_JSON
  eval "$(curl -s -L $IZON_SH)"

  __readDependency "local-setup" LOCAL_SETUP_URL LOCAL_SETUP_BRANCH
  __readDependency $PREDIX_NODEJS_STARTER PREDIX_NODEJS_STARTER_URL PREDIX_NODEJS_STARTER_BRANCH

  SETUP_MAC="https://raw.githubusercontent.com/PredixDev/local-setup/$LOCAL_SETUP_BRANCH/setup-mac.sh"
}

function run_setup() {
  init
  bash <(curl -s -L "$SETUP_MAC") --git --cf --nodejs --predixcli
}

if $SKIP_SETUP; then
  init
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
echo "Step 1. Download the $PREDIX_NODEJS_STARTER app"
echo "--------------------------------------------------------------"
if [ -d $PREDIX_NODEJS_STARTER ]; then
  echo "The $PREDIX_NODEJS_STARTER already exists."
  read -p "Should we delete it and proceed?> " -t 30 answer
  verifyAnswer answer
  echo ""
  rm -rf $PREDIX_NODEJS_STARTER
fi
echoAndRun git clone --depth 1 --branch $PREDIX_NODEJS_STARTER_BRANCH $PREDIX_NODEJS_STARTER_URL $PREDIX_NODEJS_STARTER
echoAndRun cd $PREDIX_NODEJS_STARTER

echo ""
echo "Step 2. Build the node application"
echo "--------------------------------------------------------------"
echoAndRun npm install
echo "test" > .cfignore
sed '/passport-predix-oauth.git/d' package.json > package1.json
mv package1.json package.json
echo "npm install complete"

echo ""
echo "Step 3. Give the application a unique name"
echo "--------------------------------------------------------------"
read -p "Enter a prefix for the application name>" -t 30 prefix
prefix=${prefix// /-}
prefix=${prefix//_/-}

app_name=$prefix-$PREDIX_NODEJS_STARTER
sed -i -e "s/name: .*$PREDIX_NODEJS_STARTER/name: $app_name/" manifest.yml
echo "App name set to: $app_name"

echo ""
echo "Step 4. Sign in to Predix Cloud if not already signed in"
echo "--------------------------------------------------------------"
verifyPxLogin

echo ""
echo "Step 5. Push the app to the cloud"
echo "--------------------------------------------------------------"
echoAndRun predix push

echo ""
echo "Step 6. Using a browser, visit the url to see the app"
echo "--------------------------------------------------------------"
url=$(predix app $app_name | grep urls | awk '{print $2}')
echo "https://$url"
