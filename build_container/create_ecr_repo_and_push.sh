#!/bin/bash

ECR_URI=$1
REGION=$2
AWSCLI_PROFILE=$3

# Create ECR repository
aws ecr create-repository --repository-name callisto-jupyter-base-notebook --region $REGION --profile $AWSCLI_PROFILE
aws ecr create-repository --repository-name callisto-jupyter-controller --region $REGION --profile $AWSCLI_PROFILE

aws ecr get-login-password --region $REGION --profile $AWSCLI_PROFILE | docker login --username AWS --password-stdin $ECR_URI

# Jupyter Base Notebook
docker pull jupyter/base-notebook
docker tag jupyter/base-notebook $ECR_URI/callisto-jupyter-base-notebook
docker push $ECR_URI/callisto-jupyter-base-notebook:latest

# Callisto Jupyter Controller
cd ../apis/callisto_jupyter_controller
docker build -t $ECR_URI/callisto-jupyter-controller .
docker push $ECR_URI/callisto-jupyter-controller:latest
cd -
