#!/bin/bash

# This script runs the userpass authentication demo as part of the Dopr demo run locally from a laptop.
# This script should be located under:
# /Users/beau/labs/beaulabs/mydemos/vault_examples/local_vault_instance/vaultscripts
#
# The Dopr main script can be found under:
# /Users/beau/labs/beaulabs/dopr
#
# version: 0.1
# date: 10 June 2019

clear

# Start with showing policies. These are needed for authentication
echo "ENABLE AND LIST POLCIES"
echo "--------------------------------------------------------------"
echo ""
echo "Before enabling authentication, you plan your policies that will be used to grant a role and permissions."
echo ""
echo "An example role could be a simple as only allowing access to certain secrets."
echo ""
echo "EXAMPLE POLICY:"
echo "---------------"
echo ""
cat demofiles/base_example.hcl
echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
echo ""
echo ""
echo "To load the policy into vault use the following:"
echo ""
echo "COMMAND: vault policy write base demofiles/base.hcl"
echo ""
echo ""
echo "$TCOLOR vault policy write base demofiles/base.hcl" | $TYPE
echo ""
tput sgr0

vault policy write base demofiles/base.hcl

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

echo "LIST AND CHECK POLICIES"
echo "--------------------------------------------------------------"
echo ""
echo "Once the policy has been written, check availability..."
echo ""
echo "COMMAND: vault policy list"
echo ""
echo ""
echo "$TCOLOR vault policy list" | $TYPE
echo ""
tput sgr0

vault policy list

echo ""
echo ""
echo "To review the policy:"
echo ""
echo "COMMAND: vault policy read \<name of policy\>"
echo ""
echo ""
echo "$TCOLOR vault policy read base" | $TYPE
echo ""
tput sgr0

vault policy read base

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Show current auth methods that are enabled and enable userpass auth
echo "ENABLE USER PASSWORD AUTHENTICATION"
echo "--------------------------------------------------------------"
echo ""
echo "Similar to the secrets engine, you enable an authentication method."
echo ""
echo "As discussed, Vault has multiple authentication methods. We first check to see what is enabled."
echo ""
echo ""
echo "COMMAND: vault auth list"
echo ""
echo ""
echo "$TCOLOR vault auth list" | $TYPE
echo ""
tput sgr0

vault auth list

echo ""
echo ""
echo "Currently there is only the token authentication available. We'll enable the userpass method."
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
echo ""
echo ""
echo "COMMAND: vault auth enable userpass"
echo ""
echo ""
echo "$TCOLOR vault auth enable userpass" | $TYPE
echo ""
tput sgr0

vault auth enable userpass

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
echo ""
clear
echo "LIST AVAILABLE SECRETS ENGINES AVAILABLE FOR USE NOW"
echo "--------------------------------------------------------------"
echo ""
echo "Confirm what authentication methods are available."
echo ""
echo "COMMAND: vault auth list"
echo ""
echo "$TCOLOR vault auth list" | $TYPE
echo ""
tput sgr0

vault auth list

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Create a user for the demo
echo "CREATE A USER TO INTERACT WITH VAULT"
echo "--------------------------------------------------------------"
echo ""
echo "Up until now we've been interacting with Vault via the root account."
echo "This is not a best practice, and is only for initial configuraiton, demo or emergencies."
echo ""
echo "Create a user that can consume Vault and assign a role to define authorization."
echo ""
echo "COMMAND: vault write auth/userpass/users/<user_name> password=\"<a password>\" policies=\"<a policy name>\""
echo ""
echo "$TCOLOR vault write auth/userpass/users/beaker password=\"meep\" policies=\"default\"" | $TYPE
echo ""
tput sgr0

vault write auth/userpass/users/beaker password="meep" policies="default"

echo ""
echo ""
echo "$TCOLOR vault write auth/userpass/users/bunsen password=\"honeydew\" policies=\"base\"" | $TYPE
echo ""
tput sgr0

vault write auth/userpass/users/bunsen password="honeydew" policies="base"

echo ""
echo ""
echo "You should now be able to authenticate to the UI. You can also authenticate via CLI/API using these"
echo "credentials, with which upon a successful login, Vault will issue a token for use with API calls"
echo "or CLI commands that can then be used to access secrets or funtions of Vault."
echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Login to Vault via username authentication just created
echo "LOGIN INTO VAULT WITH NEW USER"
echo "--------------------------------------------------------------"
echo ""
echo "Example logging in to Vault via CLI."
echo ""
echo "COMMAND: vault login -method=userpass username=<user_name> password=\"<password>\""
echo ""
echo ""
echo "$TCOLOR vault login -method=userpass username=beaker password=\"meep\"" | $TYPE
echo ""
tput sgr0

vault login -method=userpass username=beaker password="meep"

echo ""
echo ""
echo "Example logging in to Vault via API."
echo ""
echo "$TCOLOR curl --request POST --data '{\"password\": \"honeydew\"}' $VAULT_ADDR/v1/auth/userpass/login/bunsen | jq" | $TYPE
echo ""
tput sgr0

curl --header --request POST --data '{"password": "honeydew"}' $VAULT_ADDR/v1/auth/userpass/login/bunsen | jq

echo ""
echo ""
echo "This concludes the username authentication component of the demo."
read -rsn1 -p "Press any key to return to menu..."
