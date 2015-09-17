#!/bin/bash
set +e

cd $HOME
if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_APP_NAME" ]
then
    fail "Missing or empty option APP_NAME, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME" ]
then
    fail "Missing or empty option ENV_NAME, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_KEY" ]
then
    fail "Missing or empty option KEY, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_SECRET" ]
then
    fail "Missing or empty option SECRET, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION" ]
then
    warn "Missing or empty option REGION, defaulting to us-west-2"
    WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION="us-west-2"
fi

if [ -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_DEBUG" ]
then
    warn "Debug mode turned on, this can dump potentially dangerous information to log files."
fi

DEPLOYMENT_DIR="$WERCKER_SOURCE_DIR/build"

AWSEB_ROOT="$WERCKER_STEP_ROOT/eb-cli"
AWSEB_TOOL="$AWSEB_ROOT/bin/eb"

#mkdir -p "/home/ubuntu/.elasticbeanstalk/"
mkdir -p "/home/ubuntu/.aws"
mkdir -p "$DEPLOYMENT_DIR/.elasticbeanstalk/"
if [ $? -ne "0" ]
then
    fail "Unable to make directory.";
fi

cd $DEPLOYMENT_DIR

AWSEB_CREDENTIAL_FILE="/home/ubuntu/.aws/aws_credential_file"
AWSEB_CONFIG_FILE="/home/ubuntu/.aws/config"
AWSEB_EB_CONFIG_FILE="$DEPLOYMENT_DIR/.elasticbeanstalk/config.yml"

debug "Setting up credentials."
cat <<EOT >> $AWSEB_CREDENTIAL_FILE
AWSAccessKeyId=$WERCKER_ELASTIC_BEANSTALK_DEPLOY_KEY
AWSSecretKey=$WERCKER_ELASTIC_BEANSTALK_DEPLOY_SECRET
EOT

debug "Setting up donfig file."
cat <<EOT >> $AWSEB_CONFIG_FILE
[default]
output = json
region = $WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION

[profile eb-cli]
aws_access_key_id = $WERCKER_ELASTIC_BEANSTALK_DEPLOY_KEY
aws_secret_access_key = $WERCKER_ELASTIC_BEANSTALK_DEPLOY_SECRET
EOT

debug "Setting up eb config file."
cat <<EOT >> $AWSEB_EB_CONFIG_FILE
branch-defaults:
  $WERCKER_GIT_BRANCH:
    environment: $WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME
global:
  application_name: $WERCKER_ELASTIC_BEANSTALK_DEPLOY_APP_NAME
  default_platform: 64bit Amazon Linux 2014.03 v1.0.0 running Ruby 2.1 (Puma)
  default_region: $WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION
  profile: eb-cli
  sc: git
EOT
if [ $? -ne "0" ]
then
    fail "Unable to set up config file."
fi

if [ -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_DEBUG" ]
then
    debug "Dumping config file."
    cat $AWSEB_CREDENTIAL_FILE
    cat $AWSEB_CONFIG_FILE
    cat $AWSEB_EB_CONFIG_FILE
fi

$AWSEB_TOOL use $WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME || fail "EB is not working or is not set up correctly."

debug "Checking if eb exists and can connect."
$AWSEB_TOOL status
if [ $? -ne "0" ]
then
    fail "EB is not working or is not set up correctly."
fi

debug "Creating deployment git repo"
git config --global user.email "wercker@workangel.com"
git config --global user.name "wercker"
echo ".elasticbeanstalk/" > .gitignore
git init
git add .
git commit -m "rubbish commit message"

debug "Pushing to AWS eb servers."
$AWSEB_TOOL deploy || true # catach timeout

success 'Successfully pushed to Amazon Elastic Beanstalk'
