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
PREDIX_SCRIPT_DIR_NAME=predix-scripts
PREDIX_SCRIPT_REPO=https://github.com/PredixDev/$PREDIX_SCRIPT_DIR_NAME.git
CAMP_APP_REPO_NAME="campaign-nodejs-starter"
CAMP_APP_GIT_HUB_URL="https://github.build.ge.com/adoption/$CAMP_APP_REPO_NAME.git"

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
  git_clone_repo
  bash <(curl -s -L "$SETUP_MAC") --git --cf --nodejs
}

function git_clone_repo() {
  echo ""

  if [ ! -d "$PREDIX_SCRIPT_DIR_NAME" ]; then
    echo "Cloning predix script repo ..."
    git clone $PREDIX_SCRIPT_REPO
  else
      echo "predix script repo found reusing it..."
  fi

}

function promptCfLogin() {
  cfLogin=$(cf target | grep 'Not logged in.' | awk '{print $1$2}')
  if [ '${cfLogin}' == 'Notlogged' ]; then
    echo "To Login to Cloud foundry select the following when prompted"
    echo ". Select Basic >> 1"
    echo ". Email address"
    echo ". Password"
    echo ". Org"
    echo ". Space (optional)"
    pause
    cf predix
  else
    verifyCfLogin
  fi

}


function createUaaClient()
{
    adminUaaToken=$( __getUaaAdminToken "$1" )
    if [ ${#adminUaaToken} -lt 3 ]; then
      echo "Failed to get a token from \"$1\""
    else
      echo "Got UAA admin token $adminUaaToken"
      #echo "Making CURL GET request to create UAA Client ID \"$UAA_CLIENTID_GENERIC\"..."
      responseCurl=`curl -s "$1/oauth/clients" -H "Pragma: no-cache" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Authorization: $adminUaaToken" --data-binary '{"client_id":"'$UAA_CLIENTID_GENERIC'","client_secret":"'$UAA_CLIENTID_GENERIC_SECRET'","scope":["acs.policies.read","acs.policies.write","acs.attributes.read","'$2.zones.$3.user'","uaa.none","openid"],"authorized_grant_types":["client_credentials","authorization_code","refresh_token","password"],"authorities":["openid","uaa.none","uaa.resource","'$2.zones.$3.user'"],"autoapprove":["openid"]}'`
      echo $responseCurl

      if [ ${#responseCurl} -lt 3 ]; then
        echo "Failed to make request to create UAA Client with $1"
      else
        # If the response has a attribute for "error" ,
        # AND not a value of "Client already exists: $UAA_CLIENTID_GENERIC" for attribute "error_description" then fail
        errorAttribute=$( __jsonval "$responseCurl" "error" )
        errorDescriptionAttribute=$( __jsonval "$responseCurl" "error_description" )

        if [ ${#errorAttribute} -gt 3 ]; then
          if [ "$errorDescriptionAttribute" != "Client already exists: $UAA_CLIENTID_GENERIC" ]; then
            echo "The request failed to successfully create or reuse the Client ID"
          else
          echo "Successfully re-using existing Client ID: \"$UAA_CLIENTID_GENERIC\""
          fi
        else
        echo "Successfully created new Client ID: \"$UAA_CLIENTID_GENERIC\""
        fi
      fi
    fi
}

if $SKIP_SETUP; then
  check_internet
  git_clone_repo
  eval "$(curl -s -L $PREDIX_SH)"

else
  echo "Welcome to the Predix Campaign tutorial."
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

campaignstartBaseDir=$(pwd)
campaignstartRootDir=$campaignstartBaseDir/$PREDIX_SCRIPT_DIR_NAME/bash
echo " in here $campaignstartBaseDir $campaignstartRootDir"
campaignstartLogDir="$campaignstartRootDir/log"
predixServicesLogDir=$campaignstartLogDir
SUMMARY_TEXTFILE="$campaignstartLogDir/predix-services-summary.txt"
source "$campaignstartRootDir/scripts/error_handling_funcs.sh"
source "$campaignstartRootDir/scripts/files_helper_funcs.sh"
source "$campaignstartRootDir/scripts/curl_helper_funcs.sh"
source "$campaignstartRootDir/scripts/predix_funcs.sh"

# Creating a logfile if it doesn't exist
if ! [ -d "$campaignstartLogDir" ]; then
  mkdir "$campaignstartLogDir"
  chmod 744 "$campaignstartLogDir"
  touch "$campaignstartLogDir/quickstartlog.log"
fi

echo ""
echo "Step 1. Sign in to Predix Cloud using cli."
echo "--------------------------------------------------------------"
promptCfLogin

echo ""
echo "Step 2. Git clone and push the Application to setup services."
echo "--------------------------------------------------------------"
read -p "Enter a prefix for the application/services name> " -t 30 prefix
INSTANCE_PREPENDER=${prefix// /-}
INSTANCE_PREPENDER=${prefix//_/-}
source "$campaignstartRootDir/scripts/variables.sh"
APP_NAME=$INSTANCE_PREPENDER-$CAMP_APP_REPO_NAME
if [ ! -d "$CAMP_APP_REPO_NAME" ]; then
  echo "Cloning $CAMP_APP_GIT_HUB_URL repo ..."
  git clone $CAMP_APP_GIT_HUB_URL $CAMP_APP_REPO_NAME
else
    echo "$APP_NAME  found reusing it..."
fi
cd $CAMP_APP_REPO_NAME
cf push $APP_NAME
cd ..
echo ""
echo ""
echo "Application deployed, continue with next step to add UAA and Asset."
echo ""
echo ""
pause

echo ""
echo "Step 3. Creates Predix UAA and Asset service instances."
echo "--------------------------------------------------------------"
echo "Creating an instance of the UAA service"
echo ""

# Create instance of Predix UAA Service
__try_create_service $UAA_SERVICE_NAME $UAA_PLAN $UAA_INSTANCE_NAME "{\"adminClientSecret\":\"$UAA_ADMIN_SECRET\"}" "Predix UAA"

UAA_INSTANCE_GUID=$(cf service $UAA_INSTANCE_NAME  --guid)
UAA_INSTANCE_DOMAIN="predix-uaa.run.aws-usw02-pr.ice.predix.io"
UAA_URL="https://$UAA_INSTANCE_GUID.$UAA_INSTANCE_DOMAIN"
TRUSTED_ISSUER_ID="$UAA_URL/oauth/token"

echo "Creating an instance of the Asset service"

#Create instance of Predix Asset Service
__try_create_service $ASSET_SERVICE_NAME $ASSET_SERVICE_PLAN $ASSET_INSTANCE_NAME "{\"trustedIssuerIds\":[\"$TRUSTED_ISSUER_ID\"]}" "Predix Asset"

ASSET_INSTANCE_GUID=$(cf service $ASSET_INSTANCE_NAME  --guid)

## push and bind an app
cf bind-service $APP_NAME $UAA_INSTANCE_NAME
cf bind-service $APP_NAME $ASSET_INSTANCE_NAME

echo "Details for the service created"
cf env $APP_NAME
echo ""
echo ""
echo "Asset and UAA service created, continue with next step to configure a client on UAA."
echo ""
echo ""
pause

echo ""
echo "Step 4. Set up UAA client"
echo "--------------------------------------------------------------"
createUaaClient "$UAA_URL" $ASSET_SERVICE_NAME "$ASSET_INSTANCE_GUID"

echo ""
echo "Details Client setup"
echo "UAA URL = $UAA_URL"
echo "UAA APPLICATION CLIENTID = $UAA_CLIENTID_GENERIC"
echo "UAA APPLICATION CLIENT SECRET = $UAA_CLIENTID_GENERIC_SECRET"
echo 'UAA APPLICATION GRANT TYPES = ["client_credentials","authorization_code","refresh_token","password"]'
echo 'UAA APPLICATION CLIENT SCOPES" = ["acs.policies.read","acs.policies.write","acs.attributes.read","'$ASSET_SERVICE_NAME.zones.$ASSET_INSTANCE_GUID.user'","uaa.none","openid"]'
echo 'UAA APPLICATION CLIENT AUTHORITIES" = ["openid","uaa.none","uaa.resource","'$ASSET_SERVICE_NAME.zones.$ASSET_INSTANCE_GUID.user'"]'
echo ""
echo ""
echo "UAA client configuration completed, continue with next step to add model to asset service."
echo ""
echo ""

pause

echo ""
echo "Step 5. Add Asset model."
echo "--------------------------------------------------------------"
# Get the Asset URI and generate Asset body from the enviroment variables (for use when querying and posting data)
if ASSET_URL=$(cf env $APP_NAME | grep -m 100 uri | grep asset | awk -F"\"" '{print $4}'); then
	__append_new_line_log "Asset URI copied from environment variables! $assetURI" "$predixServicesLogDir"
else
	__error_exit "There was an error getting Asset URI..." "$predixServicesLogDir"
fi
echo $ASSET_URL
ASSET_DATA_FILE=$CAMP_APP_REPO_NAME/WTG.json
echo $ASSET_DATA_FILE
createAsset "$UAA_URL" "$ASSET_URL" "$ASSET_INSTANCE_GUID" "@$ASSET_DATA_FILE"
echo "Asset upload done completed !!"
echo ""
echo ""
echo "Asset Model added, continue with final step to deploy/restage the application."
echo ""
pause

echo ""
echo "Step 6. Restage $APP_NAME "
echo "--------------------------------------------------------------"
echo ""

appuserName=$(cf target | grep User: | awk '{print $2}')

cf set-env $APP_NAME "username" $appuserName

cf restage $APP_NAME
apphost=$(cf app $APP_NAME | grep urls: | awk '{print $2;}')
echo ""
echo "Congratulations."
echo "Application successfully deployed at https://$apphost. Please open the application on the browser."
echo "To claim your Tshirt, please vist the deployed application."