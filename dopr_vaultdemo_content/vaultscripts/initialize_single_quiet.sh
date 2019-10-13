#!/bin/bash

# This script initializes single Vault enterprise without step by step actions and DOES NOT.
# pre-populat set up. Used for testing purposes.

clear
touch ./vaultsingle/vault_variables.txt
echo "STARTING VAULT PROCESS - WITH QUIET BYPASS OF STEPS"
echo "--------------------------------------------------------------"
echo "Checking for running instance..."
# Check if Vault is already running. Don't step on it.

pgrep vault >/dev/null

if [ $? == 0 ]; then
    echo "Vault is already running. Please shut down current instance."
    echo "Vault process is: "
    pgrep vault
    sleep 2
    exit
else
    echo "DO NOT RUN THIS DEMO CODE IN PRODUCTION!"
    echo "    STARTING SINGLE VAULT INSTANCE"
    echo "DO NOT RUN THIS DEMO CODE IN PRODUCTION!"
fi

vault server -config=./config/single_config.hcl >./vaultsingle/vault_stdout.txt 2>&1 &

export VPID=$(echo $!)
echo "VPID=$(pgrep vault)" >>./vaultsingle/vault_variables.txt 2>&1
if [ $? == 0 ]; then
    echo ""
    echo "Vault server successfully started and running with process number:" $VPID

else
    echo "Vault did not start correctly. Check /vaultsingle/vault_stdout.txt for error messages."
fi

# Allow Vault to fully initialize and come up in memory. Have had issues initializing w/o the pause
sleep 3
echo ""
echo ""
echo "Opening Vault UI..."
osascript -e 'tell application "Firefox" to activate' -e 'tell application "Firefox" to open location "https://localhost:8200"'
#osascript -e 'tell application "Firefox" to activate' -e 'tell application "Firefox" to set URL of active tab of window 1 to location "https://localhost:8200"'
echo ""

# Initialize Vault using Shamir Keys
echo "INITIALIZING VAULT USING SHAMIR KEYS AND UNSEALING"
echo "--------------------------------------------------------------"
echo ""
echo "Initializing Vault using Shamir Keys..."

vault operator init -key-shares=3 -key-threshold=2 2>&1 | tee ./vaultsingle/shamir.txt

echo ""
# Unseal Vault for operational use
echo "UNSEALING VAULT FOR OPERATIONAL USE..."
echo "--------------------------------------------------------------"
echo ""

for i in $(seq 1 2); do
    vault operator unseal $(awk 'NR=='$i'{print$4}' ./vaultsingle/shamir.txt)
done

echo ""
# Set VAULT_ADDR and VAULT_TOKEN as environment variables
echo "SETTING VAULT ADDRESS AND VAULT TOKEN FOR USE"
echo "--------------------------------------------------------------"
echo ""
echo "Configuring environmental variables for CLI and API use..."
echo ""
echo "Setting VAULT ADDR..."
echo ""
export VAULT_ADDR=https://$(grep "Listener" ./vaultsingle/vault_stdout.txt | awk 'NR==1{print $5}' | tr -d '",')
echo "VAULT_ADDR=https://$(grep "Listener" ./vaultsingle/vault_stdout.txt | awk 'NR==1{print $5}' | tr -d '",')" >>./vaultsingle/vault_variables.txt 2>&1
echo "\$VAULT_ADDR is set to: https://$(grep "Listener" ./vaultsingle/vault_stdout.txt | awk 'NR==1{print $5}' | tr -d '",')"
echo ""
echo ""
echo "Setting VAULT_TOKEN variable..."
echo ""
export VAULT_TOKEN=$(awk 'NR==5{print $4}' ./vaultsingle/shamir.txt)
echo "VAULT_TOKEN=$(awk 'NR==5{print $4}' ./vaultsingle/shamir.txt)" >>./vaultsingle/vault_variables.txt 2>&1
echo "\$VAULT_TOKEN is: $(awk 'NR==5{print $4}' ./vaultsingle/shamir.txt)"
echo ""
echo ""

# Upload license payload to enable vault enterprise features
# and login to Vault as root to authenticate in this terminal
echo "UPLOADING AND APPLYING LICENSE TO VAULT"
echo "--------------------------------------------------------------"
echo ""
echo "Applying Vault license..."
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" --request PUT --data @./demofiles/licensepayload.json $VAULT_ADDR/v1/sys/license

if [ $? == 0 ]; then
    echo "Vault server has been licensed."
else
    echo "Vault did not license correctly. Check /vaultsingle/vault_stdout.txt for error messages."
fi
echo ""
echo ""

# Set environment variables to pass if selection is made for new terminal shell
touch ./vaultsingle/loadenv.sh
chmod 700 ./vaultsingle/loadenv.sh
echo "#!/bin/bash" >./vaultsingle/loadenv.sh
echo "export VAULT_ADDR="$VAULT_ADDR >>./vaultsingle/loadenv.sh
echo "export VAULT_TOKEN="$VAULT_TOKEN >>./vaultsingle/loadenv.sh
echo "export VPID=$(pgrep vault)" >>./vaultsingle/loadenv.sh

# Create an audit log for demo purpose to showcase Vault's auditing
echo "CREATE AUDIT LOG AND DISPLAY"
echo "--------------------------------------------------------------"
echo ""
echo "Configuring audit logging..."
echo ""

touch ./vaultsingle/audit.log
vault audit enable file file_path=$(pwd)/vaultsingle/audit.log

#osascript -e '"tell application "Terminal" do script "cd \"`pwd`\"; tail -f vaultsingle/audit.log""'
echo ""
echo "Opening terminal to display active logging..."

# Check if Terminal is already running. On OSX have seen osascript not execute as expected depending on if Terminal is already running (front window does not start) or not.
pgrep Terminal

if [ $? == 0 ]; then
    osascript -e "tell application \"Terminal\" to activate" -e "tell application \"Terminal\" to do script \"cd $(pwd); tail -f ./vaultsingle/audit.log | jq .\""
else
    osascript -e "tell application \"Terminal\" to activate" -e "tell application \"Terminal\" to do script \"cd $(pwd); tail -f ./vaultsingle/audit.log | jq .\" in front window"
fi

echo ""
echo ""
echo "VAULT HAS BEEN SUCCESSFULLY STARTED, INITIALIZED, AND LICENSED"
echo "--------------------------------------------------------------"
echo "Vault has been successfully initialized, unsealed and is ready for operational use."
echo "You can begin using vault via CLI or API commands."
echo ""
echo "To access the UI, please open a browser and point to: "$VAULT_ADDR
echo ""
echo "\$VAULT_TOKEN is: "$VAULT_TOKEN

echo ""
read -rsn1 -p "Press any key to return to menu..."
