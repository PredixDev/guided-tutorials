#!/bin/bash

set -e
BRANCH="master"
SKIP_SETUP=false
QUICKSTART_ARGS=""

while (( "$#" )); do
opt="$1"
case $opt in
  -b|--branch)
    BRANCH="$2"
    QUICKSTART_ARGS+=" $1 $2"
    shift
  ;;
  --skip-setup)
    SKIP_SETUP=true
  ;;
  *)
    QUICKSTART_ARGS+=" $1"
  ;;
esac
shift
done

if [[ -z $BRANCH ]]; then
  echo "Usage: $0 -b/--branch <branch> [--skip-setup]"
  exit 1
fi

echo "SKIP_SETUP            : $SKIP_SETUP"
echo "BRANCH                : $BRANCH"
echo "QUICKSTART_ARGS       : $QUICKSTART_ARGS"

IZON_SH="https://raw.githubusercontent.com/PredixDev/izon/1.0.0/izon.sh"
VERSION_JSON="https://raw.githubusercontent.com/PredixDev/guided-tutorials/$BRANCH/version.json"

PREDIX_SCRIPTS=predix-scripts

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

function init() {
  check_internet

  curl -s -O $VERSION_JSON
  eval "$(curl -s -L $IZON_SH)"

  __readDependency "local-setup" LOCAL_SETUP_URL LOCAL_SETUP_BRANCH
  __readDependency $PREDIX_SCRIPTS PREDIX_SCRIPTS_URL PREDIX_SCRIPTS_BRANCH

  SETUP_MAC="https://raw.githubusercontent.com/PredixDev/local-setup/$LOCAL_SETUP_BRANCH/setup-mac.sh"
}

function run_setup() {
  init
  bash <(curl -s -L $SETUP_MAC) --git --cf --nodejs --maven
}

function verifyAnswer() {
  if [[ -z $answer ]]; then
    echo -n "Specify (yes/no)> "
    read answer
  fi
  if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
    answer="y"
  else
    answer="n"
  fi
}

function git_clone_repo() {
  if [ -d $PREDIX_SCRIPTS ]; then
    echo "The $PREDIX_SCRIPTS already exists."
    read -p "Should we delete it?> " answer
    verifyAnswer
    if [ "$answer" == "y" ]; then
      rm -rf $PREDIX_SCRIPTS
      echo ""
      echo "Cloning $PREDIX_SCRIPTS repo ..."
      git clone --depth 1 --branch $PREDIX_SCRIPTS_BRANCH $PREDIX_SCRIPTS_URL $PREDIX_SCRIPTS
    fi
  else
    echo ""
    echo "Cloning $PREDIX_SCRIPTS repo ..."
    git clone --depth 1 --branch $PREDIX_SCRIPTS_BRANCH $PREDIX_SCRIPTS_URL $PREDIX_SCRIPTS
  fi
}

if $SKIP_SETUP; then
  init
else
    echo "Welcome to the Predix Build An Application Quick Start."
    run_setup
    echo ""
    echo "The required tools have been installed. Proceeding with the setting up services and application."
    echo ""
    echo ""
fi

git_clone_repo
$PREDIX_SCRIPTS/bash/quickstart.sh $QUICKSTART_ARGS
