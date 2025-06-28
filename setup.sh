#!/bin/bash

# Create directories
mkdir -p app/python-k8s-app
mkdir -p app/lambda
mkdir -p terraform/modules/vpc
mkdir -p terraform/environments/dev

# Create empty files for python app
touch app/python-k8s-app/app.py
touch app/python-k8s-app/requirements.txt
touch app/python-k8s-app/Dockerfile
touch app/python-k8s-app/k8s-deployment.yaml

# Create empty files for lambda
touch app/lambda/lambda_function.py
touch app/lambda/requirements.txt

# Create empty files for terraform vpc module
touch terraform/modules/vpc/main.tf
touch terraform/modules/vpc/variables.tf
touch terraform/modules/vpc/outputs.tf

# Create terraform dev environment files
touch terraform/environments/dev/main.tf
touch terraform/environments/dev/variables.tf
touch terraform/environments/dev/terraform.tfvars
touch terraform/environments/dev/outputs.tf

echo "Directories and files created successfully."
