#!/bin/bash

ECR_URI="741926482963.dkr.ecr.ap-northeast-2.amazonaws.com"
REGION="ap-northeast-2"
# AWSCLI_PROFILE=$3

# # Create ECR repository
# aws ecr create-repository --repository-name callisto-jupyter-base-notebook --region $REGION
# aws ecr create-repository --repository-name callisto-ddb-jupyter-api --region $REGION

aws ecr get-login-password --region $REGION | sudo docker login --username AWS --password-stdin $ECR_URI

# Jupyter Base Notebook
cd ./callisto_jupyter_base_notebook
sudo docker build --platform linux/amd64 -t $ECR_URI/callisto-jupyter-base-notebook .
sudo docker push $ECR_URI/callisto-jupyter-base-notebook:latest
cd -

# Callisto Jupyter Controller
cd ../IaC/deploy_db_api/lambda_codes/callisto-ddb-jupyter-api
sudo docker build --platform linux/amd64 -t $ECR_URI/callisto-ddb-jupyter-api .
sudo docker push $ECR_URI/callisto-ddb-jupyter-api:latest
cd -
