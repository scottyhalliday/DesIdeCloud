#!/bin/bash

# #################################################################################################
# NOTE: Variables below are AWS specific variables.  These need to be updated for your specific
#       project for changes to apply
# #################################################################################################
#
CODE_DEPLOY_APP_NAME=DemoApp
CODE_DEPLOY_DEVELOPMENT_GROUP=Development
S3_BUCKET=deside-cloud
S3_KEY=code-deploy/demoCode.tar
#
# #################################################################################################


# Check the environment variables to make sure that the AWS credentials have been set
if [[ -v "AWS_ACCESS_KEY_ID" ]] && [[ -v "AWS_SECRET_ACCESS_KEY" ]]
then
    echo "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY found!"
else
    echo "AWS credentials not set in environment.  Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
    echo "Quitting...."
    exit
fi

# Assemble full S3 path from bucket and key
S3_FULLPATH="s3://$S3_BUCKET/$S3_KEY"

# Push the latest code changes into the s3 bucket and register the revision
resp=$(aws deploy push --application-name $CODE_DEPLOY_APP_NAME --ignore-hidden-files --s3-location $S3_FULLPATH --source .)

# Get the file revision eTag and version provided by AWS response
IFS=', ' read -r -a array <<< $resp

for element in "${array[@]}"
do
    if [[ $element == *"eTag="* ]]
    then
        eTag=$(echo $element | sed 's/eTag=//')
    fi

    if [[ $element == *"version="* ]]
    then
        version=$(echo $element | sed 's/version=//')
    fi
done

# Tell AWS to deploy the code
aws deploy create-deployment --application-name $CODE_DEPLOY_APP_NAME --s3-location bucket=$S3_BUCKET,key=$S3_KEY,bundleType=tar,eTag=$eTag,version=$version --deployment-group-name=$CODE_DEPLOY_DEVELOPMENT_GROUP

