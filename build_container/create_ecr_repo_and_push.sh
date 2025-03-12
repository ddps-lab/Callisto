#!/bin/bash

ECR_URI=$1
REGION=$2
AWSCLI_PROFILE=$3

# Create ECR repository
aws ecr create-repository --repository-name callisto-jupyter-base-notebook --region $REGION --profile $AWSCLI_PROFILE
aws ecr create-repository --repository-name callisto-ddb-jupyter-api --region $REGION --profile $AWSCLI_PROFILE

aws ecr get-login-password --region $REGION --profile $AWSCLI_PROFILE | sudo docker login --username AWS --password-stdin $ECR_URI

# Jupyter Base Notebook
cd ./callisto_jupyter_base_notebook
docker build --platform linux/amd64 -t $ECR_URI/callisto-jupyter-base-notebook .
docker push $ECR_URI/callisto-jupyter-base-notebook:latest
cd -

# Callisto Jupyter Controller
cd ../IaC/deploy_db_api/lambda_codes/callisto-ddb-jupyter-api
docker build --platform linux/amd64 -t $ECR_URI/callisto-ddb-jupyter-api .
docker push $ECR_URI/callisto-ddb-jupyter-api:latest
cd -
