#!/bin/bash

# This script runs the transit secrets demo as part of the Dopr demo run locally from a laptop.
# This script should be located under:
# /Users/beau/labs/beaulabs/mydemos/vault_examples/local_vault_instance/vaultscripts
#
# The Dopr main script can be found under:
# /Users/beau/labs/beaulabs/dopr
#
# version: 0.1
# date: 10 June 2019

clear

# Enable the transit secrets engine for database - postgresql
echo "ENABLE THE TRANSIT ENGINE FOR ENCRYPTION AS A SERVICE"
echo "--------------------------------------------------------------"
echo ""
echo "Check existing secrets engines to see if transit is currently enabled."
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
echo "There is no transit engine currently. Enabling transit secrets engine."
echo ""
echo "COMMAND: vault secrets enable transit"
echo ""
echo "$TCOLOR vault secrets enable transit" | $TYPE
echo ""
tput sgr0

vault secrets enable transit

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
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

# Create the encryption key ring for use
echo "CREATE THE ENCRYPTION KEY RING FOR USE"
echo "--------------------------------------------------------------"
echo ""
echo "Configure your key ring that will be used to ecrypt/decrypt data..."
echo ""
echo "COMMAND: vault write -f transit/keys/<name of key ring>"
echo ""
echo ""
echo "$TCOLOR vault write -f transit/keys/ssn" | $TYPE
echo ""
tput sgr0

vault write -f transit/keys/ssn

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

echo "SEND DATA TO BE ENCRYPTED BY NEW KEY RING"
echo "--------------------------------------------------------------"
echo ""
echo "Once your transit engine is enabled and a key ring created, any client with a valid token,"
echo "and proper permission can send data to be encrypted by Vault."
echo ""
echo "NOTE: All plaintext data must be base64-encoded. The reason for this requirement is that"
echo "Vault does not require that the plaintext is \"text\". It could be a binary file such as a PDF"
echo "or image. The easiest safe transport mechanism for this data as part of a JSON payload is to"
echo "base64-encode it."
echo ""
echo "COMMAND: vault write transit/encrypt/<name of key ring> plaintext=\$(base64 <<<\"<text to be encrypted>\")"
echo ""
echo "$TCOLOR vault write transit/encrypt/ssn plaintext=\$(base64 <<< \"123-45-6789\")" | $TYPE
echo ""
tput sgr0

vault write transit/encrypt/ssn plaintext=$(base64 <<<"123-45-6789") | tee ./vaultsingle/encrypt.txt
export ENC=$(cat ./vaultsingle/encrypt.txt | awk 'NR==3{print $2}')

echo ""
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."
clear

echo "DECRYPT DATA"
echo "--------------------------------------------------------------"
echo ""
echo "To decrypt your data is as easy as sending the ciphertext to the key ring with decrypt and then decoding base64."
echo ""
echo "COMMAND: vault write transit/decrypt/<name of key ring> ciphertext=\"<cipher text received from encrypting>\""
echo ""
echo ""
echo "$TCOLOR vault write transit/decrypt/ssn ciphertext="$ENC"" | $TYPE
echo ""
tput sgr0

vault write transit/decrypt/ssn ciphertext="$ENC" | tee ./vaultsingle/decrypt.txt
export DENC=$(cat ./vaultsingle/decrypt.txt | awk 'NR==3{print $2}')

echo ""
echo ""
echo ""
echo "Pass the decrypted base64 output and decode to obtain plain text..."
echo ""
echo "COMMAND: base64 --decode <<< \"<decrypt output>\""
echo ""
echo ""
echo "$TCOLOR base64 --decode <<< "$DENC"" | $TYPE
echo ""
tput sgr0

base64 --decode <<<"$DENC"

echo ""
echo ""
echo "This concludes the transit encryption as a service engine component of the demo."
read -rsn1 -p "Press any key to return to menu..."
