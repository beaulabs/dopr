# Use the file storage - this will write encrypted data to disk.
storage "file" {
  path = "./config/data/singleinstance"
}

# Listen on a different port (8201), which will allow us to run multiple
# Vault's simultaneously.

listener "tcp" {
  address = "127.0.0.1:8200"
  #address	= "0.0.0.0:8200"
  tls_disable   = false
  tls_cert_file = "./certs/beaulabs.com+19.pem"
  tls_key_file  = "./certs/beaulabs.com+19-key.pem"
}

# Enable Vault UI
ui = true

# Disable mlock - NOTE only have this setting for dev. Do not run in production
disable_mlock = false

# Advertise non loopback address
api_addr = "https://127.0.0.1:8200"

# Set plugin directory location for addtl plugins needed
plugin_directory = "./plugins"
