auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        period: 24h

storage_config:
  filesystem:
    directory: /loki/chunks

ingester:
  max_chunk_age: 2h

limits_config:
  retention_period: "30h"
  allow_structured_metadata: false
  reject_old_samples: false
  reject_old_samples_max_age: 240h

compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m
  retention_enabled: true
  delete_request_store: filesystem

