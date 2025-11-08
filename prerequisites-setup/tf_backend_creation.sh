#!/bin/bash

#########################################################################
# Script to create resources on Azure for terraform state file storage. #
# This includes creating a resource group, storage account, and         #
# container for the terraform state file.                               #
#                                                                       #                                         
# Prerequisite: Azure login with appropriate permissions                #
# Author: Vishu Patel                                                   #
# Version: v1.0                                                         #
# Date: 5th November 2025                                               #
#########################################################################

# Enable debug mode to print each command before executing it
set -x
# Exit immediately if a command exits with a non-zero status
set -e
set -o pipefail

# variables
LOCATION="canadacentral"
RG_NAME="tfstate-rg"
STORAGE_ACCOUNT_NAME="tfstatestorageaccimv27"
STORAGE_CONTAINER_NAME="tfstatestoragecontainerimv27"

# Create Resource Group for Terraform state
az group create --name $RG_NAME --location $LOCATION 

# Create Storage Account
az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RG_NAME --sku Standard_LRS --encryption-services blob

# Create Storage Container
az storage container create --name $STORAGE_CONTAINER_NAME  --account-name $STORAGE_ACCOUNT_NAME


