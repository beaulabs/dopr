storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vaultcluster1/"
}

# Set the listener address, cluster address and tls certs
listener "tcp" {
  #address       = "127.0.0.1:8200"
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = false
  tls_cert_file   = "/opt/shared/certs/beaulabs.com+19.pem"
  tls_key_file    = "/opt/shared/certs/beaulabs.com+19-key.pem"
}

# Enable Vault UI
ui = true

# Disable mlock - NOTE only have this setting for dev. Do not run in production
disable_mlock = true

# Advertise non loopback address
api_addr = "https://10.0.10.102:8200"

cluster_addr = "https://10.0.10.102:8201"

# Set plugin directory location for addtl plugins needed
plugin_directory = "/opt/shared/plugins"
