datacenter = "canada-central1"
data_dir = "/opt/consul"
performance {
  raft_multiplier = 1
}
server = false
bootstrap_expect = 1
ui = true
client_addr = "0.0.0.0"

connect {
  enabled = true
}
ports {
  grpc = 8502
}