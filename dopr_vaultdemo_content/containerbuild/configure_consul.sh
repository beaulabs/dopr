#!/bin/bash

# This script will run Consul in server mode pulling config file from a shared location
#
# Change the configuration file location to match directory structure required.
# Configuration file location: /Users/beau/labs/beaulabs/dopr/dopr_vaultdemo_content/containerbuild

# Configure CA certificates for using https
cp /opt/shared/certs/beaulabs.com+19.crt /usr/local/share/ca-certificates/
update-ca-certificates

# Start Consul server
consul agent -config-file=/opt/shared/config/$(hostname).json -syslog=false &
