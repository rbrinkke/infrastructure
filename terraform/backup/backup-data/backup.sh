      #!/bin/sh
      
      # Set timestamp
      TIMESTAMP=$(date +%Y%m%d_%H%M%S)
      
      echo "Starting backup process - ${TIMESTAMP}"
      
      # Create temp directory for this backup
      BACKUP_DIR="/backup/temp/${TIMESTAMP}"
      mkdir -p ${BACKUP_DIR}
      
      # Backup PostgreSQL
      echo "Backing up PostgreSQL..."
      PGPASSWORD=${POSTGRES_PASSWORD} pg_dump -h postgres -U ${POSTGRES_USER} -d keycloak > ${BACKUP_DIR}/postgres_keycloak.sql
      
      # Backup CouchDB
      echo "Backing up CouchDB..."
      curl -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} -X GET http://couchdb:5984/_all_dbs | jq -r '.[]' | \
        while read -r db; do
          curl -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} -X GET "http://couchdb:5984/${db}/_all_docs?include_docs=true" \
            > ${BACKUP_DIR}/couchdb_${db}.json
        done
      
      # Backup Redis
      echo "Backing up Redis..."
      redis-cli -h redis -a ${REDIS_PASSWORD} --rdb ${BACKUP_DIR}/redis_dump.rdb
      
      # Create restic backup
      echo "Creating restic backup..."
      restic -r s3:s3.amazonaws.com/${S3_BACKUP_BUCKET}/restic backup ${BACKUP_DIR}
      
      # Cleanup old backups
      echo "Cleaning up old backups..."
      restic -r s3:s3.amazonaws.com/${S3_BACKUP_BUCKET}/restic forget \
        --keep-last 7 \
        --keep-daily 7 \
        --keep-weekly 4 \
        --keep-monthly 6 \
        --prune
      
      # Cleanup temp directory
      rm -rf ${BACKUP_DIR}
      
      echo "Backup completed successfully"
