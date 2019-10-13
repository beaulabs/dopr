#!/bin/bash

# This script runs the end to end operational use demo as part of the Dopr demo run locally from a laptop.
# This script should be located under:
# /Users/beau/labs/beaulabs/mydemos/vault_examples/local_vault_instance/vaultscripts
#
# The Dopr main script can be found under:
# /Users/beau/labs/beaulabs/dopr
#
# version: 0.1
# date: 10 June 2019

clear
# Showcase end to end use of Vault
echo "END TO END DEMO OF VAULT CONCEPTS"
echo "--------------------------------------------------------------"
echo ""
echo "Across this demo we've shown static, dynamic secrets, encryption as a service and methods of authentication."
echo "This sections walks you through a scenario use case of using Vault in an operational aspect."
echo ""
echo "In this scenario our lab manager Bunsen Honeydew needs to update his \"labapp\" database with social security numbers."
echo "However he has a confidentiality concerns and wants to encrypt them at rest."
echo ""
echo "The following workflow will be followed:"
echo ""
echo "1) User \"bunsen\" will authenticate to Vault and generate a token for use"
echo "2) A new database user for the database \"labapp\" will be generated dynamically with a TTL of 30 seconds"
echo "3) Bunsen will send his social security numbers to Vault using the transit engine to encrypt the data"
echo "4) The newly created database user will insert the encrypted data into the table"
echo ""
echo ""
echo "The list of SSN that will be encrypted is:"
echo ""
cat ./demofiles/labssn.txt
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

echo "EXECUTE WORKFLOW"
echo "--------------------------------------------------------------"

echo "The first thing that needs to happen is the database engine needs to be updated to allow writes on the labapp database."
echo "The role will be created on the database, and then the policy for writing will be set with a TTL of 30s for the created user."
echo ""
echo ""
echo "The role's SQL statement that Vault will use is:"
echo ""
cat ./demofiles/write3.sql
echo ""
echo ""
echo "$TCOLOR vault write database/roles/write db_name=labapp creation_statements=@./demofiles/write3.sql revocation_statements=@./demofiles/revoke.sql default_ttl=20s max_ttl=1h" | $TYPE
tput sgr0

# Quick check to see if Dynamic Secrets has been executed. If not, prep database for end to end actions
if ! grep -Fxq "3" ./config/data/trackruns.txt; then
    echo "Key demo action database engine not enabled. Prepping database..."
    pgrep postgres >/dev/null
    if [ $? == 1 ]; then
        pg_ctl -D /usr/local/var/postgres start
    fi
    vault secrets enable database >/dev/null
    psql -U bunsenhoneydew -h localhost -d labapp -c "CREATE SCHEMA thelab" >/dev/null
    psql -U bunsenhoneydew -h localhost -d labapp -c "CREATE TABLE thelab.labssn ( id serial PRIMARY KEY, social_security_number VARCHAR UNIQUE NOT NULL)" >/dev/null
    vault write database/config/labapp plugin_name=postgresql-database-plugin allowed_roles="readonly, write" connection_url=postgresql://bunsenhoneydew:honeydew@localhost/labapp?sslmode=disable
    vault write database/roles/readonly db_name=labapp creation_statements=@./demofiles/readonly.sql default_ttl=5s max_ttl=1h
    vault write database/roles/write db_name=labapp creation_statements=@./demofiles/write3.sql revocation_statements=@./demofiles/revoke.sql default_ttl=20s max_ttl=1h

else
    vault write database/roles/write db_name=labapp creation_statements=@./demofiles/write3.sql revocation_statements=@./demofiles/revoke.sql default_ttl=20s max_ttl=1h
fi

if ! grep -Fxq "4" ./config/data/trackruns.txt; then
    echo "Key demo action transit EaaS engine not enabled. Prepping transit engine..."
    vault secrets enable transit
    vault write -f transit/keys/ssn
fi

if ! grep -Fxq "5" ./config/data/trackruns.txt; then
    echo "Key demo action userpass method not enabled. Prepping authentication engine..."
    vault policy write base demofiles/base.hcl
    vault auth enable userpass
    vault write auth/userpass/users/bunsen password="honeydew" policies="base"
fi

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

echo "STEP 1 - GET BUNSEN A TOKEN TO INTERACT WITH VAULT"
echo "--------------------------------------------------------------"
echo "Now that the database engine and role has been configured, Bunsen will login to obtain his token..."
echo "Note, Bunsen decided to login via the API."
echo ""
echo ""
echo "$TCOLOR curl --request POST --data '{\"password\": \"honeydew\"}' \$VAULT_ADDR/v1/auth/userpass/login/bunsen | jq" | $TYPE
tput sgr0
echo ""
echo ""
#vault login -method=userpass username=bunsen password="honeydew"

curl --request POST --data '{"password": "honeydew"}' $VAULT_ADDR/v1/auth/userpass/login/bunsen | jq | tee ./vaultsingle/bunsentoken.txt
#Export the token for further use automated
export BUNSEN=$(jq -r .auth.client_token ./vaultsingle/bunsentoken.txt)

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

echo "STEP 2 - BUNSEN CREATES A NEW DB USER DYNAMICALLY"
echo "--------------------------------------------------------------"
echo "With that token received, Bunsen will execute a request to create a new DB user dynamically that can write the encrypted data into the database."
echo ""
echo ""
echo "$TCOLOR curl --header \"X-Vault-Token: $(jq -r .auth.client_token ./vaultsingle/bunsentoken.txt)\" \$VAULT_ADDR/v1/database/creds/write | jq" | $TYPE
#echo "$TCOLOR curl --header \"X-Vault-Token: \$BUNSEN\" \$VAULT_ADDR/v1/database/creds/write | jq" | $TYPE
tput sgr0

#curl --header "X-Vault-Token: $BUNSEN" $VAULT_ADDR/v1/database/creds/write | jq | tee ./vaultsingle/dbwritecreds.txt
curl --header "X-Vault-Token: $BUNSEN" $VAULT_ADDR/v1/database/creds/write | jq | tee ./vaultsingle/dbwritecreds.txt

export DBWRITE=$(jq -r .data.username ./vaultsingle/dbwritecreds.txt)
export DBWRITEPASS=$(jq -r .data.password ./vaultsingle/dbwritecreds.txt)

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

echo "STEPS 3 & 4 - BUNSEN OBTAINS CIPHERTEXT AND INSERTS INTO DB"
echo "--------------------------------------------------------------"
echo "Bunsen then loops through his SSN file to convert the plaintext values into base64 encoded values"
echo "and sends the data first to be encrypted by Vault's transit engine."
echo ""
echo "Once the data is encrypted, he receives the ciphertext back from Vault and uses the dynamically"
echo "generated DB user with write permissions to insert it into the database \"labapp\" table \"labssn\" ."
echo ""
echo ""
echo "Dynamically generated database credentials with TTL=30s"
echo "-------------------------------------------------------"
echo "Username: $(jq -r .data.username ./vaultsingle/dbwritecreds.txt)"
echo "Password: $(jq -r .data.password ./vaultsingle/dbwritecreds.txt)"
echo ""
echo ""
#echo "$TCOLOR while read LINE; do vault write transit/encrypt/ssn plaintext=\$(base64 <<< \"\$LINE\") | awk 'NR==3{print \$2}'" | $TYPE
echo "$TCOLOR curl --header \"X-Vault-Token: $(jq -r .auth.client_token ./vaultsingle/bunsentoken.txt)\" --request POST --data '{\"plaintext\": \"'\"$(base64 <<<$LINE)\"'\"}' $VAULT_ADDR/v1/transit/encrypt/ssn | jq -r .data.ciphertext" | $TYPE
tput sgr0
echo ""
echo ""
#echo "$TCOLOR psql -U $DBWRITE -d labapp -c \"INSERT INTO thelab.labssn (social_security_number) VALUES (ciphertext)\" done <./demofiles/labssn.txt" | $TYPE
#echo "$TCOLOR psql \"postgresql://\$DBWRITE:\$DBWRITEPASS@localhost/labapp\" -c \"INSERT INTO thelab.labssn (social_security_number) VALUES (ciphertext)\" done <./demofiles/labssn.txt" | $TYPE
echo "$TCOLOR psql \"postgresql://$(jq -r .data.username ./vaultsingle/dbwritecreds.txt):$(jq -r .data.password ./vaultsingle/dbwritecreds.txt)@localhost/labapp\" -c \"INSERT INTO thelab.labssn (social_security_number) VALUES (ciphertext)\" done <./demofiles/labssn.txt" | $TYPE
tput sgr0
echo ""
echo ""
while read LINE; do
    #export SSN=$(echo $LINE)
    echo ""
    echo "SSN: $LINE - encrypting via Vault transit..."
    #export ENC=$(vault write transit/encrypt/ssn plaintext=$(base64 <<<"$SSN") | awk 'NR==3{print $2}')
    export ENC=$(curl --header "X-Vault-Token: $BUNSEN" --request POST --data '{"plaintext": "'"$(base64 <<<$LINE)"'"}' $VAULT_ADDR/v1/transit/encrypt/ssn | jq -r .data.ciphertext)
    echo "Ciphertext received: $ENC - loading into database..."
    #psql -U $DBWRITE -d labapp -c "INSERT INTO thelab.labssn (social_security_number) VALUES ('$ENC')"
    psql "postgresql://$DBWRITE:$DBWRITEPASS@localhost/labapp" -c "INSERT INTO thelab.labssn (social_security_number) VALUES ('$ENC')"
done <./demofiles/labssn.txt
echo ""
echo ""
read -rsn1 -p "Demo paused - Check Postgres database \"labapp\" for \"labssn\" table data. Press any key to continue..."
clear

echo "DECRYPT - BUNSEN OBTAINS CIPHERTEXT AND DECRYPTS WITH TRANSIT"
echo "-------------------------------------------------------------"
echo "Decrypting ciphertext uses the same Vault transit engine."
echo "The reverse process is followed by selecting the ciphertext data from the DB and forwarding to Vault to decrypt."
echo ""
echo "The user created earlier to write to the database has been revoked. Using his token Bunsen has Vault dynamically"
echo "generate a read-only user to pull the encrypted data."
echo ""
echo ""
echo "$TCOLOR curl --header \"X-Vault-Token: $(jq -r .auth.client_token ./vaultsingle/bunsentoken.txt)\" \$VAULT_ADDR/v1/database/creds/readonly | jq" | $TYPE
tput sgr0
# TESTING TESTING TESTING: REMOVE THIS CODE AFTER RESOLUTION
#curl --request POST --data '{"password": "honeydew"}' $VAULT_ADDR/v1/auth/userpass/login/bunsen | jq | tee ./vaultsingle/bunsentoken1.txt
#Export the token for further use automated
#export BUNSEN1=$(awk 'NR==10{print $2}' ./vaultsingle/bunsentoken1.txt | tr -d '",')
# END TESTING TESTING TESTING

curl --header "X-Vault-Token: $BUNSEN" --request GET $VAULT_ADDR/v1/database/creds/readonly | jq -r .data | tee ./vaultsingle/dbreadcreds.txt

export DBREAD=$(jq -r .username ./vaultsingle/dbreadcreds.txt)
export DBREADPASS=$(jq -r .password ./vaultsingle/dbreadcreds.txt)

#echo "$TCOLOR psql -U \$DBWRITE -d labapp -c \"SELECT * FROM thelab.labssn\"" | $TYPE
echo "$TCOLOR psql \"postgresql://$(jq -r .username ./vaultsingle/dbreadcreds.txt):$(jq -r .password ./vaultsingle/dbreadcreds.txt)@localhost/labapp\" -c \"SELECT * FROM thelab.labssn\"" | $TYPE
tput sgr0
echo ""

#psql -U $DBWRITE -d labapp -c "SELECT * FROM thelab.labssn" | tee ./vaultsingle/ciphertext.txt
psql "postgresql://$DBREAD:$DBREADPASS@localhost/labapp" -c "SELECT * FROM thelab.labssn" | tee ./vaultsingle/ciphertext.txt

echo ""
echo "The original SSN values we submitted to the database were:"
echo ""

cat ./demofiles/labssn.txt

# echo ""
# echo ""
# echo "The ciphertext we retreived from the database was:"
# echo ""
# echo "$TCOLOR cat ./vaultsingle/ciphertext.txt" | $TYPE
# tput sgr0
# echo ""
# echo ""
# cat ./vaultsingle/ciphertext.txt
echo ""
echo ""
echo "In this example we will look to find the plaintext of id 3."
echo "Feeding the ciphertext back to the Vault transit key and decrypting yields a base64 output:"
echo ""
echo ""
#echo "$TCOLOR vault write transit/decrypt/ssn ciphertext=$(awk 'NR==5{print $3}' ./vaultsingle/ciphertext.txt)" | $TYPE
echo "$TCOLOR curl --header \"X-Vault-Token: $(jq -r .auth.client_token ./vaultsingle/bunsentoken.txt)\" --request POST --data '{\"ciphertext\": \"$(awk 'NR==5{print $3}' ./vaultsingle/ciphertext.txt)\"}' $VAULT_ADDR/v1/transit/decrypt/ssn | jq -r .data.plaintext" | $TYPE
tput sgr0
echo ""

curl --header "X-Vault-Token: $BUNSEN" --request POST --data '{"ciphertext": "'"$(awk 'NR==5{print $3}' ./vaultsingle/ciphertext.txt)"'"}' $VAULT_ADDR/v1/transit/decrypt/ssn | jq -r .data.plaintext | tee ./vaultsingle/base64.txt
#export DENC=$(cat ./vaultsingle/base64.txt)

echo ""
echo "Finally to obtain the SSN value use base64 to decode:"
#echo $DENC
echo ""
echo "$TCOLOR base64 --decode <<< $(cat ./vaultsingle/base64.txt)"
tput sgr0
base64 --decode <<<$(cat ./vaultsingle/base64.txt)
#unset DENC

echo ""
echo ""
read -rsn1 -p "This concludes the end-to-end operational use demo. Press any key to return to menu..."
