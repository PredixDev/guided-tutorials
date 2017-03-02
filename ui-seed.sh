#!/bin/bash
set -e

#source ./predix.sh
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

TUTORIAL="https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=2226&tag=2100&journey=Predix%20UI%20Seed&resources=2101,2225,2226"
PREDIX_SCRIPTS="predix-scripts"
PREDIX_SEED="predix-seed"

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
  # Need to include this function here, can't assume that users have cloned the whole repo.
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
  # pull down version.json, since customers may not clone this repo.
  curl -s -O $VERSION_JSON
  eval "$(curl -s -L $IZON_SH)"

  __readDependency "local-setup" LOCAL_SETUP_URL LOCAL_SETUP_BRANCH
  __readDependency $PREDIX_SCRIPTS PREDIX_SCRIPTS_URL PREDIX_SCRIPTS_BRANCH
  # TODO: do we need this for seed repo?
  #__readDependency $PREDIX_SEED PREDIX_SEED_URL PREDIX_SEED_BRANCH
  SETUP_MAC="https://raw.githubusercontent.com/PredixDev/local-setup/$LOCAL_SETUP_BRANCH/setup-mac.sh"
}

function run_setup() {
  init
  echo "grabbing local-setup and running it: $SETUP_MAC"
  bash <(curl -s -L "$SETUP_MAC") --git --cf --nodejs
}

function promptCfLogin() {
  cfLogin=$(cf target | grep 'User' | awk '{print $1}')
  if [ "${cfLogin}" == "User:" ]; then
    verifyCfLogin
  else
    echo "To Login to Cloud foundry select the following when prompted"
    echo ". Choose option Basic >> 1"
    echo ". Email address"
    echo ". Password"
    echo ". Org"
    echo ". Space (optional)"
    pause
    cf predix
  fi
}

function git_clone_scripts_repo() {
  echo ""
  if [ ! -d "$PREDIX_SCRIPTS" ]; then
    echo "Cloning predix script repo ..."
    git clone --depth 1 --branch $PREDIX_SCRIPTS_BRANCH $PREDIX_SCRIPTS_URL
  else
      echo "Predix scripts repo found reusing it..."
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
      responseCurl=`curl -s "$1/oauth/clients" -H "Pragma: no-cache" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Authorization: $adminUaaToken" --data-binary '{"client_id":"'$UAA_CLIENTID_GENERIC'","client_secret":"'$UAA_CLIENTID_GENERIC_SECRET'","scope":["uaa.none","openid"],"authorized_grant_types":["client_credentials","authorization_code"],"authorities":["openid","uaa.none","uaa.resource","'$2.zones.$3.user'"],"autoapprove":["openid"]}'`
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

function showAssetInSeed()
{
  __find_and_replace "/\* // asset-nav-item" "" "public/elements/seed-app/seed-app.html" "$seedStartLogDir"
  __find_and_replace "// end asset-nav-item \*/" "" "public/elements/seed-app/seed-app.html" "$seedStartLogDir"

  __find_and_replace "<!-- mock-asset-service -->" "<!-- mock-asset-service" "public/elements/views/simple-asset-view.html" "$seedStartLogDir"
  __find_and_replace "<!-- end mock-asset-service -->" "end mock-asset-service -->" "public/elements/views/simple-asset-view.html" "$seedStartLogDir"
  __find_and_replace "<!-- real-asset-service" "<!-- real-asset-service -->" "public/elements/views/simple-asset-view.html" "$seedStartLogDir"
  __find_and_replace "end real-asset-service -->" "<!-- end real-asset-service -->" "public/elements/views/simple-asset-view.html" "$seedStartLogDir"
}

function updateFrontEndConfigs()
# Updates manifest.yml and server/localConfig.json in an app
{
  local BASE64_CLIENT_CREDENTIAL=$(echo -n "$UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET" | base64)
  #    a) Modify the name of the applications
  __find_and_replace "- name: .*" "- name: $APP_NAME" "manifest.yml" "$seedStartLogDir"

  # TODO:   b) Modify the learning path
  #__find_and_replace "cloudbasics .*" "cloudbasics : false" "server/learningpaths/learningpaths.js" "$seedStartLogDir"
  #__find_and_replace "authorization .*" "authorization : true" "server/learningpaths/learningpaths.js" "$seedStartLogDir"

  #    c) Add the services to bind to the application
  __find_and_replace "\#services:" "services:" "manifest.yml" "$seedStartLogDir"
  __find_and_append_new_line "services:" "  - $UAA_INSTANCE_NAME" "manifest.yml" "$seedStartLogDir"
  # TODO: __find_and_append_new_line "services:" "- $TIMESERIES_INSTANCE_NAME" "manifest.yml" "$seedStartLogDir"
  __find_and_append_new_line "services:" "  - $ASSET_INSTANCE_NAME" "manifest.yml" "$seedStartLogDir"

  #    d) Set the clientid and base64ClientCredentials
  __find_and_replace "\#clientId: .*" "clientId: $UAA_CLIENTID_GENERIC" "manifest.yml" "$seedStartLogDir"
  __find_and_replace "\#base64ClientCredential: .*" "base64ClientCredential: $BASE64_CLIENT_CREDENTIAL" "manifest.yml" "$seedStartLogDir"

  #    e) Set the timeseries and asset information to query the services
  #__find_and_replace "\#assetMachine: .*" "assetMachine: $ASSET_TYPE" "manifest.yml" "$seedStartLogDir"
  #__find_and_replace "\#tagname: .*" "tagname: $ASSET_TAG_NOSPACE" "manifest.yml" "$seedStartLogDir"
  #__find_and_replace "\#windServiceURL: .*" "windServiceURL: https://$WINDDATA_SERVICE_URL" "manifest.yml" "$seedStartLogDir"

  # Edit the applications server/localConfig.json file
  __find_and_replace ".*uaaURL\":.*" "    \"uaaURL\": \"$UAA_URL\"," "server/localConfig.json" "$seedStartLogDir"
  #__find_and_replace ".*timeseriesZoneId\":.*" "    \"timeseries_zone\": \"$TIMESERIES_ZONE_ID\"," "server/localConfig.json" "$seedStartLogDir"
  __find_and_replace ".*assetZoneId\":.*" "    \"assetZoneId\": \"$ASSET_INSTANCE_GUID\"," "server/localConfig.json" "$seedStartLogDir"
  #__find_and_replace ".*tagname\":.*" "    \"tagname\": \"$ASSET_TAG_NOSPACE\"," "server/localConfig.json" "$seedStartLogDir"
  __find_and_replace ".*clientId\":.*" "    \"clientId\": \"$UAA_CLIENTID_GENERIC\"," "server/localConfig.json" "$seedStartLogDir"
  __find_and_replace ".*base64ClientCredential\":.*" "    \"base64ClientCredential\": \"$BASE64_CLIENT_CREDENTIAL\"," "server/localConfig.json" "$seedStartLogDir"
  # Add the required Timeseries and Asset URIs
  __find_and_replace ".*assetURL\":.*" "    \"assetURL\": \"$ASSET_URL\"," "server/localConfig.json" "$seedStartLogDir"
  #__find_and_replace ".*timeseriesURL\":.*" "    \"timeseriesURL\": \"$TIMESERIES_QUERY_URI\"," "server/localConfig.json" "$seedStartLogDir"
  #if [[ "$USE_WINDDATA_SERVICE" == "1" ]]; then
  #  __find_and_replace ".*windServiceURL\": .*" "    \"windServiceURL\": \"https://$WINDDATA_SERVICE_URL\"" "server/localConfig.json" "$seedStartLogDir"
  #fi
  #__find_and_replace ".*cloudbasics\" :.*" "    \"cloudbasics\": false," "server/learningpaths/learningpaths.js" "$seedStartLogDir"
  #__find_and_replace ".*authorization\" :.*" "    \"authorization\": true," "server/learningpaths/learningpaths.js" "$seedStartLogDir"
}

if $SKIP_SETUP; then
  init
  eval "$(curl -s -L $PREDIX_SH)"
else
  echo "Welcome to the Predix UI Seed tutorial."
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

# download and import predix-scripts
git_clone_scripts_repo

seedStartBaseDir=$(pwd)
seedStartRootDir=$seedStartBaseDir/$PREDIX_SCRIPTS/bash
seedStartLogDir="$seedStartRootDir/log"
predixServicesLogDir=$seedStartLogDir
SUMMARY_TEXTFILE="$seedStartLogDir/predix-services-summary.txt"
source "$seedStartRootDir/scripts/error_handling_funcs.sh"
source "$seedStartRootDir/scripts/files_helper_funcs.sh"
source "$seedStartRootDir/scripts/curl_helper_funcs.sh"
source "$seedStartRootDir/scripts/predix_funcs.sh"

# Creating a logfile if it doesn't exist
if ! [ -d "$seedStartLogDir" ]; then
  mkdir "$seedStartLogDir"
  chmod 744 "$seedStartLogDir"
  touch "$seedStartLogDir/quickstartlog.log"
fi

echo ""
echo "Step 1. Sign in to Predix Cloud using cli."
echo "--------------------------------------------------------------"
promptCfLogin

echo ""
echo "Step 2. Git clone and push the predix-seed app."
echo "--------------------------------------------------------------"
read -p "Enter a prefix for the application/services name> " -t 30 prefix
INSTANCE_PREPENDER=${prefix// /-}
INSTANCE_PREPENDER=${prefix//_/-}
source "$seedStartRootDir/scripts/variables.sh"
APP_NAME=$INSTANCE_PREPENDER-$PREDIX_SEED

if [ ! -d "$PREDIX_SEED" ]; then
  echo "Cloning $PREDIX_SEED_URL repo ..."
  git clone --depth 1 --branch master https://github.com/predixdev/predix-seed $PREDIX_SEED
else
    echo "$PREDIX_SEED found reusing it..."
fi

cd $PREDIX_SEED
npm install && bower install
gulp dist
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

## bind services to the app, so we can read VCAPS env variables
cf bind-service $APP_NAME $UAA_INSTANCE_NAME
cf bind-service $APP_NAME $ASSET_INSTANCE_NAME
echo "Details for the service created"
cf env $APP_NAME
echo ""
echo ""
echo "Asset and UAA service created, continue with next step to configure a client on UAA."
pause

echo ""
echo "Step 4. Set up UAA client and user"
echo "--------------------------------------------------------------"
createUaaClient "$UAA_URL" $ASSET_SERVICE_NAME "$ASSET_INSTANCE_GUID"
__addUaaUser "$UAA_URL"

echo ""
echo "Details of UAA setup"
echo "UAA URL = $UAA_URL"
echo "UAA APPLICATION CLIENTID = $UAA_CLIENTID_GENERIC"
echo "UAA APPLICATION CLIENT SECRET = $UAA_CLIENTID_GENERIC_SECRET"
echo 'UAA APPLICATION GRANT TYPES = ["client_credentials","authorization_code"]'
echo 'UAA APPLICATION CLIENT SCOPES" = ["uaa.none","openid"]'
echo 'UAA APPLICATION CLIENT AUTHORITIES" = ["openid","uaa.none","uaa.resource","'$ASSET_SERVICE_NAME.zones.$ASSET_INSTANCE_GUID.user'"]'
echo "UAA USER NAME = $UAA_USER_NAME"
echo "UAA USER PASSWORD = $UAA_USER_PASSWORD"
echo ""
echo ""
echo "UAA client configuration completed, continue with next step to add model to asset service."
pause

echo ""
echo "Step 5. Add Asset model."
echo "--------------------------------------------------------------"
# Get the Asset URI and generate Asset body from the enviroment variables (for use when querying and posting data)
if ASSET_URL=$(cf env $APP_NAME | grep -m 100 uri | grep asset | awk -F"\"" '{print $4}'); then
	__append_new_line_log "Asset URL copied from environment variables! $ASSET_URL" "$predixServicesLogDir"
else
	__error_exit "There was an error getting Asset URI..." "$predixServicesLogDir"
fi
ASSET_DATA_FILE=$PREDIX_SEED/server/sample-data/predix-asset/compressor-2017.json
echo $ASSET_DATA_FILE
createAsset "$UAA_URL" "$ASSET_URL" "$ASSET_INSTANCE_GUID" "@$ASSET_DATA_FILE"
echo "Asset upload completed !!"
echo ""
echo ""
echo "Asset Model added, continue with final step to deploy/restage the application."
echo ""
pause

echo ""
echo "Step 6. Push $APP_NAME with updated configuration"
echo "--------------------------------------------------------------"
echo ""
cd $PREDIX_SEED
updateFrontEndConfigs
showAssetInSeed
gulp dist
cf push $APP_NAME
cd ..
echo ""
echo "Success!"
apphost=$(cf app $APP_NAME | grep urls: | awk '{print $2;}')

# Automagically open the application in browser, based on OS
case "$(uname -s)" in

   Darwin)
     # OSX
     open https://$apphost
     ;;

   CYGWIN*|MINGW32*|MINGW64*|MSYS*)
     # Windows
     start "" https://$apphost
     ;;

esac
echo "Your Predix UI Seed app was successfully deployed at https://$apphost."
