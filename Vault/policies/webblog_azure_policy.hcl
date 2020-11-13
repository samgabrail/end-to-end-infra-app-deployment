path "mongodb/creds/mongodb-role" {
  capabilities = [ "read" ]
}
path "transit/*" {
  capabilities = ["list","read","update"]
}
