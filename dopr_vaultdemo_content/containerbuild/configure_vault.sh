#!/bin/bash

# This script will run Vault in server mode pulling config file from a shared location
#
# Change the configuration file location to match directory structure required.
# Configuration file location: dopr/dopr_vaultdemo_content/containerbuild

# Configure CA certificates for using https
cp /opt/shared/certs/beaulabs.com+19.crt /usr/local/share/ca-certificates/
update-ca-certificates

# Start Vault server and Consul agent
vault server -config=/opt/shared/config/$(hostname)_config.hcl &
consul agent -config-file=/opt/shared/config/$(hostname)_client_agent.json -syslog=false &
