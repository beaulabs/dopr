path "labsecrets/lab*" {
  capabilities = ["create", "read"]
}

path "labsecrets/" {
  capabilities = ["list"]
}

path "transit/encrypt/ssn" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "transit/decrypt/ssn" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
