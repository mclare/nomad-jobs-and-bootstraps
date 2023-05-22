#!/bin/bash
/*
# Wednesday April 19, 2023
# AutoGPT bootstrap script in nomad environment
# https://github.com/Significant-Gravitas/Auto-GPT#-installation
#
# Starts AutoGPT in a GoTTY web session

echo "################################"
date
echo "################################"

echo "Updating system"
apt update
apt install -y screen nano chromium-driver ca-certificates
# Install utilities
apt install -y curl jq wget git

# Abandoned attempt to install geckodriver

    #echo "################################"
    #date
    #echo "\n################################"
    #echo "Installing geckodriver $GECKODRIVER_VERSION for web searches"

    # Firefox Set the URL and filename for the binary
    #URL="https://github.com/mozilla/geckodriver/releases/download/$GECKODRIVER_VERSION/geckodriver-$GECKODRIVER_VERSION-linux-aarch64.tar.gz"
    #FILENAME="geckodriver-$GECKODRIVER_VERSION-linux-aarch64.tar.gz"

    # Download the binary
    #wget "$URL" -O "$FILENAME"

    # Extract the binary
    #tar -xvf "$FILENAME"

    # Move the binary to /usr/local/bin/ (this assumes that /usr/local/bin/ is in the system path)
    #mv geckodriver /usr/local/bin/
    #chmod +x /usr/local/bin/geckodriver

    # Verify the installation by checking the version
    #geckodriver --version

    #mkdir -p ~/.wdm/
    #cp $COMMON_DIR/drivers.json ~/.wdm/drivers.json
    #chmod -w ~/.wdm/drivers.json

echo "################################"
date
echo "################################"

cd $COMMON_DIR
DIR="$COMMON_DIR/Auto-GPT/"

if [ -d "$DIR" ]; then
    echo "Directory $DIR exists"
    echo "Using git to pull latest changes"
    cd $DIR
    git pull
else
    echo "Directory $DIR does not exist"
    echo "Cloning Auto-GPT from github"
    git clone https://github.com/Torantulino/Auto-GPT.git
    cd $DIR
fi
echo "################################"
date
echo "################################"
#   echo "Fix for sourcery issue https://github.com/Significant-Gravitas/Auto-GPT/issues/1445"
#   grep -v sourcery requirements.txt  > requirements-local.txt
#   pip install -r requirements-local.txt

echo "Installing requirements with pip"
pip install --upgrade pip
pip install -r requirements.txt

echo "Done intial setting up python environment\n"
echo "################################"
date
echo "################################"
echo "Getting GOTTY for ARM"


#wget https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_arm.tar.gz

#ARCH=$(uname -m)
#GOTTY_VERSION="1.0.1"
#wget "{https://github.com/sorenisanerd/gotty/releases/download/$GOTTY_VERSION/gotty_$GOTTY_VERSION_linux_$ARCH.tar.gz gotty-$ARCH.tar.gz}" 
#tar -xvzf gotty-$ARCH.tar.gz

wget "https://github.com/sorenisanerd/gotty/releases/download/$GOTTY_VERSION/gotty_linux_arm.tar.gz" 
tar -xvzf gotty_linux_arm.tar.gz

chmod +x gotty

echo "################################"
date
echo "################################"
echo "Setting up environment variables"
cp .env.template .env
# OpenAI stuff
################################################################################
if [ -n "$OPENAI_API_KEY" ]; then
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> .env
fi
if [ -n "$AUTO_GPT_API_KEY" ]; then
    echo "AUTO_GPT_API_KEY=$AUTO_GPT_API_KEY" >> .env
fi
if [ -n "$SMART_LLM_MODEL" ]; then
    echo "SMART_LLM_MODEL=$SMART_LLM_MODEL" >> .env
fi
if [ -n "$FAST_LLM_MODEL" ]; then
    echo "FAST_LLM_MODEL=$FAST_LLM_MODEL" >> .env
fi
if [ -n "$EXECUTE_LOCAL_COMMANDS" ]; then
    echo "EXECUTE_LOCAL_COMMANDS=$EXECUTE_LOCAL_COMMANDS" >> .env
fi
if [ -n "$RESTRICT_TO_WORKSPACE" ]; then
    echo "RESTRICT_TO_WORKSPACE=$RESTRICT_TO_WORKSPACE" >> .env
fi
if [ -n "$TEMPERATURE" ]; then
    echo "TEMPERATURE=$TEMPERATURE" >> .env
fi
if [ -n "$FAST_TOKEN_LIMIT" ]; then
    echo "FAST_TOKEN_LIMIT=$FAST_TOKEN_LIMIT" >> .env
fi
if [ -n "$SMART_TOKEN_LIMIT" ]; then
    echo "SMART_TOKEN_LIMIT=$SMART_TOKEN_LIMIT" >> .env
fi
# Image Provider for image actions
################################################################################
if [ -n "$IMAGE_PROVIDER" ]; then
    echo "IMAGE_PROVIDER=$IMAGE_PROVIDER" >> .env
fi
if [ -n "$IMAGE_SIZE" ]; then
    echo "IMAGE_SIZE=$IMAGE_SIZE" >> .env
fi
# GIT Provider for repository actions
################################################################################
if [ -n "$GITHUB_API_KEY" ]; then
    echo "GITHUB_API_KEY=$GITHUB_API_KEY" >> .env
fi
if [ -n "$GITHUB_USERNAME" ]; then
    echo "GITHUB_USERNAME=$GITHUB_USERNAME" >> .env
fi
if [ -n "$GITHUB_API_KEY" ]; then
    echo "GITHUB_API_KEY=$GITHUB_API_KEY" >> .env
fi
# Google - web searches
################################################################################
if [ -n "$GOOGLE_API_KEY" ]; then
    echo "GOOGLE_API_KEY=$GOOGLE_API_KEY" >> .env
fi
if [ -n "$CUSTOM_SEARCH_ENGINE_ID" ]; then
    echo "CUSTOM_SEARCH_ENGINE_ID=$CUSTOM_SEARCH_ENGINE_ID" >> .env
fi
if [ -n "$USE_WEB_BROWSER" ]; then
    echo "USE_WEB_BROWSER=$USE_WEB_BROWSER" >> .env
fi

echo "################################"
date
echo "################################"
echo "Installing weaviate-client"
pip install weaviate-client

echo "## Weaviate Memory Backend Setup ##" >> .env
if [[ -n "${MEMORY_BACKEND}" ]]; then
    echo "MEMORY_BACKEND=$MEMORY_BACKEND" >> .env
fi
if [[ -n "${WEAVIATE_HOST}" ]]; then
    echo "WEAVIATE_HOST=$WEAVIATE_HOST" >> .env
fi
if [[ -n "${WEAVIATE_PORT}" ]]; then
    echo "WEAVIATE_PORT=$WEAVIATE_PORT" >> .env
fi
if [[ -n "${WEAVIATE_PROTOCOL}" ]]; then
    echo "WEAVIATE_PROTOCOL=$WEAVIATE_PROTOCOL" >> .env
fi

if [[ -n "${WEAVIATE_USERNAME}" ]]; then
    echo "WEAVIATE_USERNAME=$WEAVIATE_USERNAME" >> .env
fi
if [[ -n "${WEAVIATE_PASSWORD}" ]]; then
    echo "WEAVIATE_PASSWORD=$WEAVIATE_PASSWORD" >> .env
fi
if [[ -n "${WEAVIATE_API_KEY}" ]]; then
    echo "WEAVIATE_API_KEY=$WEAVIATE_API_KEY" >> .env
fi

if [[ -n "${WEAVIATE_API_KEY}" ]]; then
    echo "WEAVIATE_API_KEY=$WEAVIATE_API_KEY" >> .env
fi
if [[ -n "${WEAVIATE_EMBEDDED_PATH}" ]]; then
    echo "WEAVIATE_EMBEDDED_PATH=$WEAVIATE_EMBEDDED_PATH" >> .env
fi
if [[ -n "${USE_WEAVIATE_EMBEDDED}" ]]; then
    echo "USE_WEAVIATE_EMBEDDED=$USE_WEAVIATE_EMBEDDED" >> .env
fi
if [[ -n "${MEMORY_INDEX}" ]]; then
    echo "MEMORY_INDEX=$MEMORY_INDEX" >> .env
fi
# Set Plugins
################################################################################
if [[ -n "${ALLOWLISTED_PLUGINS}" ]]; then
    echo "ALLOWLISTED_PLUGINS=$ALLOWLISTED_PLUGINS" >> .env
fi
if [[ -n "${DENYLISTED_PLUGINS}" ]]; then
    echo "DENYLISTED_PLUGINS=$DENYLISTED_PLUGINS" >> .env
fi
if [[ -n "${NEWSAPI_API_KEY}" ]]; then
    echo "NEWSAPI_API_KEY=$NEWSAPI_API_KEY" >> .env
fi

echo "################################"
date
echo "################################"
echo "Running tests"

python3 tests.py

#python3 -m autogpt

echo "################################"
date
echo "################################"

echo "AutoGPT evniroment ready"

cd $DIR

#!/bin/bash

if [ -e "./plugins/__PUT_PLUGIN_ZIPS_HERE__" ]; then
    echo "./plugins/__PUT_PLUGIN_ZIPS_HERE__ File exists!"
    rm ./plugins/__PUT_PLUGIN_ZIPS_HERE__
    curl -L -o ./plugins/Auto-GPT-Plugins.zip https://github.com/Significant-Gravitas/Auto-GPT-Plugins/archive/refs/heads/master.zip

else
    echo "No __PUT_PLUGIN_ZIPS_HERE__ folder. Not adding plugins."
fi


cd $DIR
chomd +x run.sh
echo "Starting AutoGPT with GOTTY on port 8080"
#../gotty -w -p 8080 python3 -m autogpt
../gotty -w -p 8080 ./run.sh



    #echo "Launch a shell and navigate to $DIR"
    #echo "Then run: screen  -- then run     python3 -m autogpt"
    #echo "################################"
    #echo "To detach from the screen session, press Ctrl+A then Ctrl+D"
    #echo "To reattach to the screen session, run: screen -r"
    #echo "To exit the screen session, press Ctrl+A then Ctrl+K"
    #echo "To list all screen sessions, run: screen -ls"
    #echo "################################"
    #while true; do date; sleep 30; done;