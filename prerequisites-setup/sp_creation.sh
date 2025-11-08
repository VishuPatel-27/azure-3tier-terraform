#!/bin/bash

#########################################################################
# Script to create Azure Service Principal,                             #
# assign it the Contributor role and azure Key Vault administrator role #
# on a specified subscription.                                          #
#                                                                       #
#                                                                       #
# Prerequisite: Azure login credentials                                 #
# Author: Vishu Patel                                                   #
# Version: v1.0                                                         #
# Date: 5th November 2025                                               #
#########################################################################

# Enable debug mode to print each command before executing it
set -x
# Exit immediately if a command exits with a non-zero status
set -e 
set -o pipefail

# Get the subscription ID of the currently logged-in Azure account
SUBSCRIPTION_ID=$(az account show --query id --output tsv | tr -d '\r')

# Create the service principal and assign roles
# Create Service Principal with Contributor role
# Assign Key Vault Administrator role
SP_OUTPUT=$(az ad sp create-for-rbac --name "terraform-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID")

# Wait for Azure AD to register the service principal
sleep 20

# Get the object ID of the created service principal
SP_OBJECT_ID=$(az ad sp list --display-name "terraform-sp" --query "[].id" --output tsv)

az role assignment create \
  --assignee-object-id $SP_OBJECT_ID \
  --assignee-principal-type ServicePrincipal \
  --role "Key Vault Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Export the service principal details as environment variables
export ARM_CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.appId')
export ARM_CLIENT_SECRET=$(echo $SP_OUTPUT | jq -r '.password')
export ARM_TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenant')
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID

# login using the service principal

sleep 30

# setting up subscription for the service principal
az account set --subscription $SUBSCRIPTION_ID

az login --service-principal \
  --username $ARM_CLIENT_ID \
  --password $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

