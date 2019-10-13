#!/bin/bash

# This script runs the Okta MFA authentication demo as part of the Dopr demo run locally from a laptop.
# This script should be located under:
# /Users/beau/labs/beaulabs/mydemos/vault_examples/local_vault_instance/vaultscripts
#
# The Dopr main script can be found under:
# /Users/beau/labs/beaulabs/dopr
#
# version: 0.1
# date: 10 June 2019

clear

# Enable the Okta authentication method
echo "ENABLE THE OKTA AUTHENTICATION METHOD FOR VAULT ACCESS"
echo "--------------------------------------------------------------"
echo ""
echo "To utilize Okta as an authentication method you must first enable it."
echo ""
echo "COMMAND: vault auth enable okta"
echo ""
echo ""
echo "$TCOLOR vault auth enable okta" | $TYPE
echo ""
tput sgr0

vault auth enable okta

echo ""
echo ""
echo "Once enabled, you can list all currently avaialble auth methods via:"
echo ""
echo "COMMAND: vault auth list"
echo ""
echo "$TCOLOR vault auth list" | $TYPE
echo ""

vault auth list

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Configure Vault to communicate to Okta
echo "CONFIGURE VAULT TO BE ABLE TO COMMUNICATE WITH OKTA"
echo "--------------------------------------------------------------"
echo ""
echo "Vault must be able to communicate with Okta to send the authentication request."
echo ""
echo "COMMAND: vault write auth/okta/config base_url=okta.com organization=<org value> token=<token value>"
echo ""
echo "$TCOLOR vault write auth/okta/config base_url=okta.com organization=dev-578305 token=\$OKTATOKEN" | $TYPE
echo ""
tput sgr0

vault write auth/okta/config base_url=okta.com organization=dev-578305 token=$OKTATOKEN

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Configure the appropriate policy to be attached based on group membership
echo "MAP AN OKTA GROUP TO A VAULT POLICY"
echo "--------------------------------------------------------------"
echo ""
echo "Vault makes use of the Okta groups to quickly set policies upon successful authentication."
echo "In this example, we have an Okta group named Vault. We will attach the base policy to the user"
echo "when they are member of the Vault group."
echo ""
echo "COMMAND: vault write auth/okta/groups/<group> policies=<desired policy>"
echo ""
echo ""
echo "$TCOLOR vault write auth/okta/groups/vault policies=\"base\"" | $TYPE
echo ""
tput sgr0

vault write auth/okta/groups/vault policies="base"

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

echo "UTILIZE OKTA MFA TO AUTHENTICATE TO VAULT"
echo "--------------------------------------------------------------"
echo ""
echo "Once Vault has been configured to communicate with Okta, users can then select that method"
echo "for login authentication to Vault."
echo ""
echo "Open a browser tab and go to the Vault UI login page."
echo ""
echo ""
echo "This concludes the Okta authentication method component of the demo."
echo ""
echo ""
read -rsn1 -p "Press any key to return to menu..."

# Additional commands to build in:
# Authenticate to Vault via Okta via API

# curl --request POST --data '{"password": "'$OKTAPASSWORD'"}' https://127.0.0.1:8200/v1/auth/okta/login/beau@hashicorp.com

# Authenticate to Vault via Okta via API and parse json

# curl --request POST --data '{"password": "'$OKTAPASSWORD'"}' https://127.0.0.1:8200/v1/auth/okta/login/beau@hashicorp.com | jq

# Authenticate to Vault via Okta via API and parse json to just token

# curl --request POST --data '{"password": "'$OKTAPASSWORD'"}' https://127.0.0.1:8200/v1/auth/okta/login/beau@hashicorp.com | jq -r .auth.client_token
