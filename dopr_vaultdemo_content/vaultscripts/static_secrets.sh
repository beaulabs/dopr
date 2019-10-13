#!/bin/bash

# This script runs the static secrets demo as part of the Dopr demo run locally from a laptop.
# This script should be located under:
# /Users/beau/labs/beaulabs/mydemos/vault_examples/local_vault_instance/vaultscripts
#
# The Dopr main script can be found under:
# /Users/beau/labs/beaulabs/dopr
#
# version: 0.1
# date: 10 June 2019

clear

# Enable the K/V secrets engine
echo "ENABLE THE K/V SECRETS ENGINE"
echo "--------------------------------------------------------------"
echo ""
echo "Before Vault can \"do stuff\", a secrets engine must be enabled."
echo "Engines are enabled at a specified path. In this case we'll enable"
echo "a static secrets key-vaule engine at the path \"labsecrets\"."
echo ""
echo "COMMAND: vault secrets enable -path=\"<name of secrets>\" kv"
echo ""
echo ""
echo "$TCOLOR vault secrets enable -path="labsecrets" kv" | $TYPE
echo ""
tput sgr0

vault secrets enable -path="labsecrets" kv

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Show the two methods of how to engage with Vault: CLI or API
echo "ENGAGE WITH VAULT VIA CLI"
echo "--------------------------------------------------------------"
echo "Two different methods to write a secret to Vault: CLI and API"
echo ""
echo "To run commands via CLI you must authenticate to Vault first via: vault login <method> : where method could be a token, or username or other enabled authorization mechanism."
echo ""
echo "CLI COMMAND: vault kv put <secrets engine>/<secret name> <key>=<value>"
echo ""
echo "EXAMPLE: vault kv put labsecrets/apikeys/googlemain apikey=\"master-api-key-111111\""
echo ""
echo ""
echo "$TCOLOR vault kv put labsecrets/apikeys/googlemain apikey="master-api-key-111111"" | $TYPE
tput sgr0

vault kv put labsecrets/apikeys/googlemain apikey="master-api-key-111111"

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
echo ""
clear
echo "ENGAGE WITH VAULT USING API"
echo "--------------------------------------------------------------"
echo ""
echo "Vault API uses standard HTTP verbs: GET, PUT, POST, LIST, UPDATE etc..."
echo ""
echo "API COMMAND: curl --header \"X-Vault-Token: <vault token>\" --request POST --data '{\"<key>\": \"<vaule>\"}'"
echo ""
echo "EXAMPLE: curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"\<key\>": "\<value\>"}' $VAULT_ADDR/v1/<secrets engine>/<location>/<secret> | jq"
echo ""
echo ""
echo "$TCOLOR curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"gvoiceapikey": "walkie-talkie-222222"}' $VAULT_ADDR/v1/labsecrets/apikeys/googlevoice | jq" | $TYPE
echo ""
tput sgr0

curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"gvoiceapikey": "walkie-talkie-222222"}' $VAULT_ADDR/v1/labsecrets/apikeys/googlevoice | jq

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Run through several CLI commands // also sets up the environment for later use
clear
echo "ADDITIONAL EXAMPLES OF INTERACTION WITH VAULT VIA CLI"
echo "--------------------------------------------------------------"
echo ""
echo "Some quick examples of the Vault CLI in action: "
echo ""
echo "POST SECRET: vault kv put labsecrets/webapp username="beaker" password="meepmeepmeep""
echo ""
echo ""
echo "$TCOLOR vault kv put labsecrets/webapp username="beaker" password="meepmeepmeep"" | $TYPE
tput sgr0

vault kv put labsecrets/webapp username="beaker" password="meepmeepmeep"

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
echo ""
echo ""
echo ""
echo "RETRIEVE SECRET: vault kv get labsecrets/webapp"
echo ""
echo ""
echo "$TCOLOR vault kv get labsecrets/webapp" | $TYPE
tput sgr0

vault kv get labsecrets/webapp

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
echo ""
echo ""
echo ""
echo "RETRIEVE SECRET BY FIELD: vault kv get -field=password labsecrets/webapp"
echo ""
echo ""
echo "$TCOLOR vault kv get -field=password labsecrets/webapp" | $TYPE
tput sgr0

vault kv get -field=password labsecrets/webapp

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
echo ""
echo ""
echo ""
echo "PULL VIA JSON IF NEEDED: vault kv get -format=json labsecrets/webapp | jq -r .data.password"
echo ""
echo ""
echo "$TCOLOR vault kv get -format=json labsecrets/webapp | jq -r .data.password" | $TYPE
tput sgr0

vault kv get -format=json labsecrets/webapp | jq -r .data.password

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
echo ""
echo ""
echo ""
echo "LOAD SECRET VIA FILE PAYLOAD: vault kv put <secrets engine>/<location> @<name of file>.json"
echo "Loading via payload file in CLI is recommended, or ensure history is not being recorded."
echo ""
echo "EXAMPLE PAYLOAD:"
echo "data.json"
cat demofiles/data.json
echo ""
echo ""
echo "$TCOLOR vault kv put labsecrets/labinfo @./demofiles/data.json" | $TYPE
tput sgr0

vault kv put labsecrets/labinfo @./demofiles/data.json

# Insert some additional secrets for use later in demo / hide action
vault kv put labsecrets/lab_keypad code="12345" >/dev/null
vault kv put labsecrets/lab_room room="A113" >/dev/null

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Run through several API
echo "ADDITIONAL EXAMPLES OF INTERACTION WITH VAULT VIA API"
echo "--------------------------------------------------------------"
echo ""
echo "Some quick examples of the Vault API in action: "
echo ""
echo "WRITE A SECRET VIA API: curl --header "X-Vault-Token: \$VAULT_TOKEN" --request POST --data '{"\<key\>": "\<value\>"}' \$VAULT_ADDR/v1/<secrets engine>/<location>/<secret> | jq"
echo ""
echo ""
echo "$TCOLOR curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"gmapapikey": "where-am-i-??????"}' $VAULT_ADDR/v1/labsecrets/apikeys/googlemaps | jq" | $TYPE
tput sgr0

curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"gmapapikey": "where-am-i-??????"}' $VAULT_ADDR/v1/labsecrets/apikeys/googlemaps | jq

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
echo ""
echo ""
echo ""
echo "READ A SECRET VIA API: curl --header "X-Vault-Token: \$VAULT_TOKEN" $VAULT_ADDR/v1/labsecrets/apikeys/googlemaps | jq "
echo ""
echo ""
echo "$TCOLOR curl --header "X-Vault-Token: \$VAULT_TOKEN" $VAULT_ADDR/v1/labsecrets/apikeys/googlemaps | jq " | $TYPE
tput sgr0

curl --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/labsecrets/apikeys/googlemaps | jq

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
echo ""
echo ""
echo ""
echo "READ A SECRET VIA API AND PARSE JSON: curl -s --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/labsecrets/apikeys/googlemaps | jq  -r .data.gmapapikey"
echo ""
echo "$TCOLOR curl -s --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/labsecrets/apikeys/googlemaps | jq  -r .data.gmapapikey" | $TYPE
tput sgr0

curl -s --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/labsecrets/apikeys/googlemaps | jq -r .data.gmapapikey

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Show how you can list secrets
echo "LIST SECRETS LOADED INTO K/V ENGINE SO FAR"
echo "--------------------------------------------------------------"
echo ""
echo "To show the secrets that are posted under the particular secrets engine"
echo ""
echo "COMMAND: vault kv list labsecrets"
echo ""
echo ""
echo "$TCOLOR vault kv list labsecrets" | $TYPE
echo ""
tput sgr0

vault kv list labsecrets

echo ""
echo ""
echo "This concludes the static secrets engine component of the demo."
read -rsn1 -p "Press any key to return to menu..."
