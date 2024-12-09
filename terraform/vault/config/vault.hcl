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
  disable_hostname         = true
}

# Audit logging kan later worden toegevoegd
# audit {
#   file_path          = "/vault/logs/audit.log"
#   file_roll_size     = 100
#   file_roll_duration = "24h"
# }
