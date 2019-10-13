#!/bin/bash

# This script runs the dynamic secrets demo as part of the Dopr demo run locally from a laptop.
# This script should be located under:
# /Users/beau/labs/beaulabs/mydemos/vault_examples/local_vault_instance/vaultscripts
#
# The Dopr main script can be found under:
# /Users/beau/labs/beaulabs/dopr
#
# version: 0.1
# date: 10 June 2019

clear

# Perform some quick house keeping to ensure postgres is running and if not fire it up
pgrep postgres >/dev/null
if [ $? == 1 ]; then
    echo "Starting Postgre SQL database for demo..."
    pg_ctl -D /usr/local/var/postgres start
    echo ""
    echo ""
fi

# Have Mac activate pgAdmin 4 as part of demo
osascript -e "tell application \"pgAdmin 4\" to activate"
clear

# Enable the dynamic secrets engine for database - postgresql
echo "ENABLE THE DATABASE SECRETS ENGINE FOR DYNAMIC SECRETS"
echo "--------------------------------------------------------------"
echo ""
echo "In this example we are going to show how Vault can dynamically create"
echo "secrets -> a just what you need, when you need, where you need capability."
echo "Again the appropriate secrets engine must be enabled first."
echo "Check existing secrets engines to see if database is currently enabled."
echo ""
echo "COMMAND: vault secrets list"
echo ""
echo ""
echo "$TCOLOR vault secrets list" | $TYPE
echo ""
tput sgr0

vault secrets list

echo ""
echo ""
echo "There is no database engine currently. Enabling database secrets engine."
echo ""
echo "COMMAND: vault secrets enable database"
echo ""
echo "$TCOLOR vault secrets enable database" | $TYPE
echo ""
tput sgr0

vault secrets enable database

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Show current secrets engines that are enabled
echo "LIST AVAILABLE SECRETS ENGINES AVAILABLE FOR USE NOW"
echo "--------------------------------------------------------------"
echo ""
echo "Confirm what secrets engines are available for use now."
echo ""
echo "COMMAND: vault secrets list"
echo ""
echo "$TCOLOR vault secrets list" | $TYPE
echo ""
tput sgr0

vault secrets list

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Configure the database secrets engine to utilize postgresql
echo "CONFIGURE THE DATABASE SECRETS ENGINE TO USE POSTGRESQL"
echo "--------------------------------------------------------------"
echo ""
echo "For Vault to dynamically create secrets for the database it must first"
echo "configure the database secrets engine. In this case we will utilize postgresql."
echo ""
echo "You set the engine with the required plugin and connection details..."
echo ""
echo "COMMAND: vault write database/config/postgresql plugin_name=postgresql-database-plugin allowed_roles=\"readonly, write\" connection_url=postgresql://{{username}}:{{password}}@localhost/labapp?sslmode=disable"
echo ""
echo ""
echo "$TCOLOR vault write database/config/labapp plugin_name=postgresql-database-plugin allowed_roles=\"readonly, write\" connection_url=postgresql://bunsenhoneydew:honeydew@localhost/labapp?sslmode=disable" | $TYPE
echo ""
tput sgr0

psql -U bunsenhoneydew -h localhost -d labapp -c "CREATE SCHEMA thelab" >/dev/null
psql -U bunsenhoneydew -h localhost -d labapp -c "CREATE TABLE thelab.labssn ( id serial PRIMARY KEY, social_security_number VARCHAR UNIQUE NOT NULL)" >/dev/null
#The command below is interesting. It works, but not sure if it's because postgres is caching user name from above and since I don't have a password on the parent (for demo purposes no master)
#password. Something to investigate when I have time.
#vault write database/config/labapp plugin_name=postgresql-database-plugin allowed_roles="readonly, write" connection_url=postgresql://{{username}}:{{password}}@localhost/labapp?sslmode=disable
vault write database/config/labapp plugin_name=postgresql-database-plugin allowed_roles="readonly, write" connection_url=postgresql://bunsenhoneydew@localhost/labapp?sslmode=disable

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Configure the database role to configure users inside the database
echo "CONFIGURE THE DATABASE ROLE THAT CONFIGURES USERS IN THE DB"
echo "--------------------------------------------------------------"
echo ""
echo "Configure the database role that will configure users inside the postgres database..."
echo "This will use a payload with a SQL statement to be used by Vault when creating a user inside the database"
echo ""
echo ""
echo "PAYLOAD: demofiles/readonly.sql"
echo ""
cat demofiles/readonly.sql
echo ""
echo ""
echo "COMMAND: vault write database/roles/readonly db_name=labapp creation_statements=@readonly.sql default_ttl=5s max_ttl=1h"
echo ""
echo ""
echo "$TCOLOR vault write database/roles/readonly db_name=labapp creation_statements=@./demofiles/readonly.sql default_ttl=5s max_ttl=1h" | $TYPE
echo ""
tput sgr0

vault write database/roles/readonly db_name=labapp creation_statements=@./demofiles/readonly.sql default_ttl=5s max_ttl=1h

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

#Generate a new set of database credentials to utilize
echo "GENERATE A NEW SET OF DATABASE CREDENTIALS FOR USE VIA CLI"
echo "--------------------------------------------------------------"
echo ""
echo "Generating a new database credential is as simple as hitting the readonly role and having Vault create the user on the fly inside the database."
echo ""
echo "GENERATE COMMAND VIA CLI: vault read database/creds/readonly"
echo ""
echo "How many database users do you want to create (enter a number):"
read DBCREDS
echo ""
echo "Starting terminal to watch postgres..."
echo ""

osascript -e "tell application \"Terminal\" to activate" -e "tell application \"Terminal\" to do script \"cd $(pwd); ./vaultscripts/psqlwatch.sh\""
sleep 2

echo "Creating database users..."
echo ""

for i in $(seq 1 $DBCREDS); do
    echo "$TCOLOR vault read database/creds/readonly" | $TYPE
    tput sgr0
    vault read database/creds/readonly
    echo ""
done

echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

echo "GENERATE A NEW SET OF DATABASE CREDENTIALS FOR USE VIA API"
echo "--------------------------------------------------------------"
echo ""
echo "GENERATE COMMAND VIA API: curl --header "X-Vault-Token: $VAULT_TOKEN" --request GET $VAULT_ADDR/v1/database/creds/readonly | jq"
echo ""
echo ""
echo "$TCOLOR curl --header "X-Vault-Token: $VAULT_TOKEN" --request GET $VAULT_ADDR/v1/database/creds/readonly | jq" | $TYPE
echo ""
tput sgr0

curl --header "X-Vault-Token: $VAULT_TOKEN" --request GET $VAULT_ADDR/v1/database/creds/readonly | jq

echo ""
echo "This concludes the dynamic secrets engine component of the demo."
read -rsn1 -p "Press any key to return to menu..."
