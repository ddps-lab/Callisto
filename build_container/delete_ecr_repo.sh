#!/bin/bash

ECR_URI=$1
REGION=$2
AWSCLI_PROFILE=$3

aws ecr delete-repository --force --repository-name callisto-jupyter-base-notebook --region $REGION --profile $AWSCLI_PROFILE
aws ecr create-repository --repository-name callisto-jupyter-controller --region $REGION --profile $AWSCLI_PROFILE