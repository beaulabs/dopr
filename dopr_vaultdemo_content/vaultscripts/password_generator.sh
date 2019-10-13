#!/bin/bash

# Setup password generator plugin for Vault

# Ensure you have downloaded the latest release from: https://github.com/sethvargo/vault-secrets-gen

# Export sha256 checksum for validating plugin to Vault plugin registry

export SHA256=$(shasum -a 256 "./plugins/vault-secrets-gen" | cut -d' ' -f1)

# Write the secrets-gen value to the plugins path

vault write sys/plugins/catalog/secrets-gen sha_256="${SHA256}" command="vault-secrets-gen"

# Enable the secrets engine for secrets generation

vault secrets enable -path="gen" -plugin-name="secrets-gen" plugin

# Enable a secrets kv store for passwords

vault secrets enable -version=2 -path=svrcreds/ kv

# Start the container with the volume share: docker run -t -i --name ubu -v ~/labs/beaulabs/dockershare:/opt/dockershare ubuntu /bin/bash

# Running tests in your Ubuntu container will require some additional packages
apt-get update
apt-get install -y curl util-linux iproute2 net-tools iputils-ping zip vim jq sudo cron
service cron start
curl -LO https://releases.hashicorp.com/vault/1.2.2/vault_1.2.2_linux_amd64.zip
unzip vault_1.2.2_linux_amd64.zip
mv vault /usr/local/bin/

# Docker container on OSX will use the internal DNS of host.docker.internal to reach the host

# Update the self signed certificate and place it on the Linux container
# use Docker Desktop for Mac volume sharing with the container

# copy the Vault self signed certificate to the container and install it (change the .pem to .crt when copying into a Linux cert trust store
# and then update the trust store
cd /opt/dockershare/
cp vault.beaulabs+7.pem /usr/local/share/ca-certificates/vault.beaulabs+7.crt
update-ca-certificates

# Once that has been set you can then login normally to vault running on the host with vault login -address=https://host.docker.internal:8200 <token>

# Remember once you set VAULT_ADDR and VAULT_TOKEN in /etc/environment of your Linux server you need to "source /etc/environment" to pull the values

# Once you have configured everything, set up a cronjob (crontab -e) to run the token renewal and rotate password script

# crontab -e -> */5 * * * * /opt/dockershare/rotate-linux-password.sh root
