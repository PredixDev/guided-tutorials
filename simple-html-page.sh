#!/bin/bash
set -e

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

function prefix_to_path() {
  if [[ ":$PATH:" != *":$1:"* ]]; then
    echo 'export PATH="$1${PATH:+":$PATH"}"' >> ~/.bash_profile
    source ~/.bash_profile
  fi
}

function check_internet() {
  set +e
  echo ""
  echo "Checking internet connection..."
  curl "http://google.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy"
    exit 1
  fi
  echo "OK"
  echo ""
  set -e
}

function check_bash_profile() {
  # Ensure bash profile exists
  if [ ! -e ~/.bash_profile ]; then
    printf "#!/bin/bash\n" >> ~/.bash_profile
  fi

  # This is required for brew to work
  prefix_to_path /usr/local/bin
}

function install_brew_cask() {
  # Install brew and cask
  if which brew > /dev/null; then
    echo "brew already installed, tapping cask"
  else
    echo "Installing brew and cask"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  brew tap caskroom/cask
}

function brew_install() {
  echo "--------------------------------------------------------------"
  TOOL=$1
  COMMAND=$1
  if [ $# -eq 2 ]; then
    COMMAND=$2
  fi

  if which $COMMAND > /dev/null; then
    echo "$TOOL already installed"
  else
    echo "Installing $TOOL"
    brew install $TOOL
  fi
}

function install_git() {
  brew_install git
  git --version
}

function install_cf() {
  brew tap cloudfoundry/tap
  brew_install cf-cli cf
  cf -v

  # Install CF Predix plugin
  set +e
  cf plugins | grep Predix > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    set -e
    cf install-plugin -f https://github.com/PredixDev/cf-predix/releases/download/1.0.0/predix_osx
  fi
  set -e
}

function run_setup() {
  check_internet
  check_bash_profile
  install_brew_cask
  install_git
  install_cf
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

function manual() {
  echo ""
  echo "You can manually go through the tutorial steps here"
  echo "https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1475&tag=1719&journey=Hello%20World"
}

function checkExit() {
  if [ $? -ne 0 ]; then
    manual
  fi
}

function pause() {
  read -n1 -r -p "Press any key to continue..."
  echo ""
}

trap checkExit EXIT

if ! [[ "$1" == "--skip-setup" ]]; then
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
git clone https://github.com/PredixDev/Predix-HelloWorld-WebApp.git
cd Predix-HelloWorld-WebApp

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
cat manifest.yml
echo ""
echo "Take a moment to study the contents of the manifest file."
pause

echo ""
echo "Step 4. Push the app to the cloud"
echo "--------------------------------------------------------------"
cf push

echo ""
echo "Step 5. Using a browser, visit the URL to see the app"
echo "--------------------------------------------------------------"
url=$(cf app $app_name | grep urls | awk '{print $2}')
echo "You have successfully pushed your first Predix application."
echo "Enter the URL below in a browser to view the application."
echo ""
echo "https://$url"
