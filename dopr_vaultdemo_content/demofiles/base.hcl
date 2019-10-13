path "labsecrets/lab*" {
  capabilities = ["create", "read"]
}

path "labsecrets/" {
 capabilities = ["list"]
}

path "database/creds/write" {
  capabilities = ["read"]
}

path "database/roles/write" {
  capabilities = ["read"]
}

path "database/creds/readonly" {
  capabilities = ["read"]
}

path "database/roles/readonly" {
  capabilities = ["read"]
}

path "transit/encrypt/ssn" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

path "transit/decrypt/ssn" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
