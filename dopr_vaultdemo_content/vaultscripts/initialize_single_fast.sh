#!/bin/bash

# This script initializes single Vault enterprise instance without step by step actions.
# Useful for when you want to show interaction with Vault instantiated with pre-populated set up.

clear
echo "STARTING SINGLE VAULT PROCESS - WITH FAST SET UP"
echo "--------------------------------------------------------------"
echo "Checking for running instance..."
# Check if Vault is already running. Don't step on it.

pgrep vault

if [ $? == 0 ]; then
    echo "Vault is already running. Please shut down current instance."
    echo ""
    echo "Vault process is: "
    pgrep vault
    sleep 2
    exit
else
    echo "DO NOT RUN THIS DEMO CODE IN PRODUCTION!"
    echo "    STARTING SINGLE VAULT INSTANCE"
    echo "DO NOT RUN THIS DEMO CODE IN PRODUCTION!"
fi

echo ""
vault server -config=./config/single_config.hcl >./vaultsingle/vault_stdout.txt 2>&1 &
export VPID=$(echo $!)
echo "VPID=$(pgrep vault)" >>./vaultsingle/vault_variables.txt 2>&1
if [ $? == 0 ]; then
    echo "Vault server successfully started and running with process number:" $VPID

else
    echo "Vault did not start correctly. Check ./vaultsingle/vault_stdout.txt for error messages."
fi
osascript -e 'tell application "Firefox" to activate' -e 'tell application "Firefox" to open location "https://localhost:8200"'
sleep 1
vault operator init -key-shares=3 -key-threshold=2 2>&1 | tee ./vaultsingle/shamir.txt
for i in $(seq 1 2); do
    vault operator unseal $(awk 'NR=='$i'{print$4}' ./vaultsingle/shamir.txt)
done
export VAULT_ADDR=https://$(grep "Listener" ./vaultsingle/vault_stdout.txt | awk 'NR==1{print $5}' | tr -d '",')
echo "VAULT_ADDR=https://$(grep "Listener" ./vaultsingle/vault_stdout.txt | awk 'NR==1{print $5}' | tr -d '",')" >>./vaultsingle/vault_variables.txt 2>&1
export VAULT_TOKEN=$(awk 'NR==5{print $4}' ./vaultsingle/shamir.txt)
echo "VAULT_TOKEN=$(awk 'NR==5{print $4}' ./vaultsingle/shamir.txt)" >>./vaultsingle/vault_variables.txt 2>&1
curl --header "X-Vault-Token: $VAULT_TOKEN" --request PUT --data @./demofiles/licensepayload.json $VAULT_ADDR/v1/sys/license
touch ./vaultsingle/loadenv.sh
chmod 700 ./vaultsingle/loadenv.sh
echo "#!/bin/bash" >./vaultsingle/loadenv.sh
echo "export VAULT_ADDR="$VAULT_ADDR >>./vaultsingle/loadenv.sh
echo "export VAULT_TOKEN="$VAULT_TOKEN >>./vaultsingle/loadenv.sh
echo "export VPID=$(pgrep vault)" >>./vaultsingle/loadenv.sh

touch ./vaultsingle/audit.log
vault audit enable file file_path=$(pwd)/vaultsingle/audit.log

# Check if Terminal is already running. On OSX have seen osascript not execute as expected depending on if Terminal is already running (front window does not start) or not.
pgrep Terminal

if [ $? == 0 ]; then
    osascript -e "tell application \"Terminal\" to activate" -e "tell application \"Terminal\" to do script \"cd $(pwd); tail -f ./vaultsingle/audit.log | jq .\""
else
    osascript -e "tell application \"Terminal\" to activate" -e "tell application \"Terminal\" to do script \"cd $(pwd); tail -f ./vaultsingle/audit.log | jq .\" in front window"
fi

sleep 1
# Prep environment with static secrets, dynamic secrets for database, transit, and userpass

# Populate trackruns.txt to block inadvertent running of steps a second time
for i in {1..5}; do
    echo "$i" >>./vaultsingle/trackruns.txt
done

# Static secrets
echo "Enabling static secrets..."
vault secrets enable -path="labsecrets" kv
vault kv put labsecrets/apikeys/googlemain apikey="master-api-key-111111"
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"gvoiceapikey": "walkie-talkie-222222"}' $VAULT_ADDR/v1/labsecrets/apikeys/googlevoice
vault kv put labsecrets/webapp username="beaker" password="meepmeepmeep"
vault kv put labsecrets/labinfo @./demofiles/data.json
vault kv put labsecrets/lab_keypad code="12345" >/dev/null
vault kv put labsecrets/lab_room room="A113" >/dev/null
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"gmapapikey": "where-am-i-??????"}' $VAULT_ADDR/v1/labsecrets/apikeys/googlemaps

# Dynamic secrets for databases
echo "Enabling dynamic secrets for database PostgreSQL..."
pgrep postgres >/dev/null
if [ $? == 1 ]; then
    echo "No PostgreSQL process found...starting Postgre SQL database..."
    pg_ctl -D /usr/local/var/postgres start
fi
osascript -e "tell application \"pgAdmin 4\" to activate"
vault secrets enable database
psql -U bunsenhoneydew -h localhost -d labapp -c "CREATE SCHEMA thelab" >/dev/null
psql -U bunsenhoneydew -h localhost -d labapp -c "CREATE TABLE thelab.labssn ( id serial PRIMARY KEY, social_security_number VARCHAR UNIQUE NOT NULL)" >/dev/null
vault write database/config/labapp plugin_name=postgresql-database-plugin allowed_roles="readonly, write" connection_url=postgresql://{{username}}:{{password}}@localhost/labapp?sslmode=disable
vault write database/roles/readonly db_name=labapp creation_statements=@./demofiles/readonly.sql default_ttl=5s max_ttl=1h
osascript -e "tell application \"Terminal\" to activate" -e "tell application \"Terminal\" to do script \"cd $(pwd); ./vaultscripts/psqlwatch.sh\""

# Transit secrets
echo "Enabling transit secrets, encryption as a service..."
vault secrets enable transit
vault write -f transit/keys/ssn
vault write transit/encrypt/ssn plaintext=$(base64 <<<"123-45-6789") | tee ./vaultsingle/encrypt.txt
export ENC=$(cat ./vaultsingle/encrypt.txt | awk 'NR==3{print $2}')
vault write transit/decrypt/ssn ciphertext="$ENC" | tee ./vaultsingle/decrypt.txt
export DENC=$(cat ./vaultsingle/decrypt.txt | awk 'NR==3{print $2}')

# Set up Userpass as authentication
echo "Enabling local user/password authentication method..."
vault policy write base demofiles/base.hcl
vault auth enable userpass
vault write auth/userpass/users/beaker password="meep" policies="default"
vault write auth/userpass/users/bunsen password="honeydew" policies="base"

# Set up Okta with push MFA authentication
echo "Enabling Okta with push MFA authentication method..."
vault auth enable okta
vault write auth/okta/config base_url=okta.com organization=dev-578305 token=$OKTATOKEN
vault write auth/okta/groups/vault policies="base"

# CODE BELOW IS DRAFT AND IS A PLACE HOLDER FOR DOPR ENHANCEMENTS
# Set up Vault environment for operataionl use examples using transit to encrypt database entry at rest
#echo "Enabling operational use configuration - database operations with transit..."
#vault write database/config/labapp plugin_name=postgresql-database-plugin allowed_roles=write connection_url=postgresql://bunsenhoneydew@localhost/labapp?sslmode=disable
#vault write database/roles/write db_name=labapp creation_statements=@./demofiles/write3.sql revocation_statements=@./demofiles/revoke.sql default_ttl=10s max_ttl=24h
#vault write database/roles/write db_name=labapp creation_statements=@./demofiles/write3.sql default_ttl=30s max_ttl=1h

echo ""
echo ""
echo "VAULT HAS BEEN SUCCESSFULLY STARTED, INITIALIZED, AND LICENSED"
echo "--------------------------------------------------------------"
echo "Vault has been successfully initialized, unsealed and is ready for operational use."
echo "Static secrets, dynamic secrets via database, transit have all been populated and enabled."
echo "You can begin using vault via CLI or API commands."
echo ""
echo "To access the UI, please open a browser and point to: "$VAULT_ADDR
echo ""
echo "\$VAULT_TOKEN is: "$VAULT_TOKEN

echo ""
read -rsn1 -p "Press any key to return to menu..."
