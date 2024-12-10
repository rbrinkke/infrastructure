storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address     = "0.0.0.0:8600"
  tls_disable = 1
}

api_addr = "http://0.0.0.0:8600"
ui       = true

telemetry {
  prometheus_retention_time = "24h"
  disable_hostname          = true
}

