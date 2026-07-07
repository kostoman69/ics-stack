ui = true

storage "raft" {
  path    = "/openbao/data"
  node_id = "icsauth-openbao-01"
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = true
}

api_addr     = "https://icsauth.net"
cluster_addr = "http://openbao:8201"