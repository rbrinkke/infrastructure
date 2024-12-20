resource "docker_container" "couchdb" {
  name  = "couchdb"
  image = "couchdb:latest"

  # Poortmapping toevoegen
  ports {
    internal = 5984
    external = 5984
  }

  # Basis CouchDB configuratie
  upload {
    content = <<EOF
[couchdb]
single_node = true
max_document_size = 4294967296

[chttpd]
bind_address = 0.0.0.0
port = 5984

[httpd]
enable_cors = true

[cors]
credentials = true
origins = *
headers = accept, authorization, content-type, origin, referer
methods = GET, PUT, POST, DELETE

[admins]
${var.couchdb_user} = ${var.couchdb_password}
EOF
    file = "/opt/couchdb/etc/local.d/docker.ini"
  }

  env = [
    "COUCHDB_USER=${var.couchdb_user}",
    "COUCHDB_PASSWORD=${var.couchdb_password}",
    "COUCHDB_SINGLE_NODE=true"
  ]

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.couchdb.rule"
    value = "Host(`db.example.com`)"
  }

  labels {
    label = "traefik.http.routers.couchdb.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.couchdb.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.services.couchdb.loadbalancer.server.port"
    value = "5984"
  }

  volumes {
    host_path      = "${var.infrastructure_base_path}/couchdb-data"
    container_path = "/opt/couchdb/data"
  }

  networks_advanced {
    name = var.monitoring_network
  }

  networks_advanced {
    name = var.traefik_network
  }

  healthcheck {
    test         = ["CMD-SHELL", "curl -f http://localhost:5984/_up || exit 1"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}

