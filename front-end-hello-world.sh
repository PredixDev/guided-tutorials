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
    echo Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy
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

function install_nodejs() {
  brew_install node
  node -v
  brew_install npm
  npm -v

  type bower > /dev/null || npm install -g bower
  echo -ne "\nbower "
  bower -v

  type grunt > /dev/null || npm install -g grunt-cli
  grunt --version
}

function run_setup() {
  check_internet
  check_bash_profile
  install_brew_cask
  install_git
  install_cf
  install_nodejs
}

function verifyCfLogin() {
  set +e
  local targetInfo
  targetInfo=$(cf target)
  set -e

  if [[ "${targetInfo/FAILED}" == "$targetInfo" ]] && [[ "${targetInfo/No org}" == "$targetInfo" ]] && [[ "${targetInfo/No space}" == "$targetInfo" ]]; then
    cf target
  else
    cf predix
  fi
}

function manual() {
  echo ""
  echo "You can manually go through the tutorial steps here"
  echo "https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1569&tag=1719&journey=Hello%20World"
}

function checkExit() {
  if [ $? -ne 0 ]; then
    manual
  fi
}

trap checkExit EXIT

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

echo ""
echo "Step 1. Download the predix-starter-nodejs app"
echo "--------------------------------------------------------------"
git clone https://github.com/PredixDev/predix-nodejs-starter.git
cd predix-nodejs-starter

echo ""
echo "Step 2. Build the node application"
echo "--------------------------------------------------------------"
npm install

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
cf push

echo ""
echo "Step 6. Using a browser, visit the url to see the app"
echo "--------------------------------------------------------------"
url=$(cf app $app_name | grep urls | awk '{print $2}')
echo "https://$url"
echo "Note: You won't be able to click the links on the html page until you have configured it with UAA, which you will do in a later tutorial."
