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
<<<<<<< HEAD
sudo docker build --platform linux/amd64 -t $ECR_URI/callisto-jupyter-base-notebook .
sudo docker push $ECR_URI/callisto-jupyter-base-notebook:latest
=======
docker build --platform linux/amd64 -t $ECR_URI/callisto-jupyter-base-notebook .
docker push $ECR_URI/callisto-jupyter-base-notebook:latest
>>>>>>> 2cba161d6b36c5a702303cc8e46aa2379ace53ce
cd -

# Callisto Jupyter Controller
cd ../IaC/deploy_db_api/lambda_codes/callisto-ddb-jupyter-api
<<<<<<< HEAD
sudo docker build --platform linux/amd64 -t $ECR_URI/callisto-ddb-jupyter-api .
sudo docker push $ECR_URI/callisto-ddb-jupyter-api:latest
=======
docker build --platform linux/amd64 -t $ECR_URI/callisto-ddb-jupyter-api .
docker push $ECR_URI/callisto-ddb-jupyter-api:latest
>>>>>>> 2cba161d6b36c5a702303cc8e46aa2379ace53ce
cd -
