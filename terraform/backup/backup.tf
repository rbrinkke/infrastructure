resource "docker_container" "backup_service" {
  name  = "backup-service"
  image = "alpine:latest"
  
  restart = "unless-stopped"
  
  command = [
    "/bin/sh", "-c",
    <<-EOT
      # Install de benodigde tools
      apk update && \
      apk add --no-cache \
        restic \
        postgresql-client \
        curl \
        jq \
        redis \
        mc \
        dcron \
        python3

      mkdir -p /backup/temp

      # Maak het backup-script aan
      cat > /backup/backup.sh << 'EOF'
      #!/bin/sh
      TIMESTAMP=$(date +%Y%m%d_%H%M%S)
      echo "Starting backup process - $${TIMESTAMP}"

      BACKUP_DIR="/backup/temp/$${TIMESTAMP}"
      mkdir -p $${BACKUP_DIR}

      echo "Backing up PostgreSQL..."
      PGPASSWORD=$${POSTGRES_PASSWORD} pg_dump -h postgres -U $${POSTGRES_USER} -d keycloak > $${BACKUP_DIR}/postgres_keycloak.sql

      echo "Backing up CouchDB..."
      curl -u $${COUCHDB_USER}:$${COUCHDB_PASSWORD} -X GET http://couchdb:5984/_all_dbs | jq -r '.[]' | \
        while read -r db; do
          curl -u $${COUCHDB_USER}:$${COUCHDB_PASSWORD} -X GET "http://couchdb:5984/$${db}/_all_docs?include_docs=true" > $${BACKUP_DIR}/couchdb_$${db}.json
        done

      echo "Backing up Redis..."
      redis-cli -h redis -a $${REDIS_PASSWORD} --rdb $${BACKUP_DIR}/redis_dump.rdb

      echo "Creating restic backup..."
      restic -r s3:s3.amazonaws.com/$${S3_BACKUP_BUCKET}/restic backup $${BACKUP_DIR}

      echo "Cleaning up old backups..."
      restic -r s3:s3.amazonaws.com/$${S3_BACKUP_BUCKET}/restic forget \
        --keep-last 7 \
        --keep-daily 7 \
        --keep-weekly 4 \
        --keep-monthly 6 \
        --prune

      rm -rf $${BACKUP_DIR}

      echo "Backup completed successfully"
EOF
      
      chmod +x /backup/backup.sh

      # Cron job instellen
      mkdir -p /var/spool/cron/crontabs
      echo "0 2 * * * /backup/backup.sh >> /backup/backup.log 2>&1" > /var/spool/cron/crontabs/root
      chmod 0644 /var/spool/cron/crontabs/root

      echo "Running initial backup..."
      /backup/backup.sh

      # Start een eenvoudige HTTP-server op poort 8080 zodat Traefik ernaartoe kan routeren
      # Deze server kan bv. een simpele statuspagina dienen.
      echo "Backup service is running" > /backup/index.html
      python3 -m http.server 8080 -d /backup &

      # Start de cron daemon in de voorgrond, zodat de container blijft draaien
      exec crond -f
    EOT
  ]

  env = [
    "RESTIC_PASSWORD=${var.backup_password}",
    "AWS_ACCESS_KEY_ID=${var.aws_access_key}",
    "AWS_SECRET_ACCESS_KEY=${var.aws_secret_key}",
    "S3_BACKUP_BUCKET=${var.s3_backup_bucket}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "REDIS_PASSWORD=${var.redis_password}",
    "MINIO_ROOT_USER=${var.minio_root_user}",
    "MINIO_ROOT_PASSWORD=${var.minio_root_password}",
    "COUCHDB_USER=${var.couchdb_user}",
    "COUCHDB_PASSWORD=${var.couchdb_password}"
  ]

  volumes {
    host_path      = "${var.infrastructure_base_path}/backup-data"
    container_path = "/backup"
  }

  networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }

  # Definieer poort en Traefik labels voor toegang via Traefik
  ports {
    internal = 8080
    external = 8080
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.backup.rule"
    value = "Host(`backup.example.com`)"
  }

  labels {
    label = "traefik.http.routers.backup.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.backup.tls"
    value = "true"
  }

  labels {
    # Koppel de service expliciet aan poort 8080
    label = "traefik.http.services.backup.loadbalancer.server.port"
    value = "8080"
  }
}

