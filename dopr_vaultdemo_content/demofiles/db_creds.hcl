# Get credentials from the database backend
path "database/creds/readonly" {
  capabilities = [ "read" ]
}
# Renew the lease
path "/sys/leases/renew" {
  capabilities = [ "update" ]
}
