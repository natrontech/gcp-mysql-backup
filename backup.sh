#!/bin/bash

# Enable parallel composite uploads in GSUtil configuration.
BOTO_FILE="${HOME}/.boto"
if [ ! -f "${BOTO_FILE}" ]; then
  touch "${BOTO_FILE}"
fi
# Only add the configuration if it doesn't already exist.
if ! grep -q "parallel_composite_upload_threshold" "${BOTO_FILE}"; then
  echo "[GSUtil]" >>"${BOTO_FILE}"
  echo "parallel_composite_upload_threshold = 150M" >>"${BOTO_FILE}"
fi

# Exit on error, unset variables, and failures in pipelines.
set -euo pipefail

# Logging function with timestamp.
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $*"
}

# Validate required environment variables.
REQUIRED_VARS=(MYSQL_DATABASES MYSQL_HOST MYSQL_PORT MYSQL_USER MYSQL_PASSWORD GCS_BUCKET GCS_BUCKET_DIR PROXY_QUIT_URL)
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    log "ERROR: Environment variable ${var} is not set."
    exit 1
  fi
done

# Global error handler.
function catchError {
  log "ERROR: An error occurred during the backup of database: ${DB:-unknown}"
  exit 1
}
trap 'catchError' ERR

# Read the comma-separated list of databases.
IFS=',' read -ra DB_ARRAY <<<"$MYSQL_DATABASES"

# Process each database.
for DB in "${DB_ARRAY[@]}"; do
  log "Starting backup for database: ${DB}"
  TIMESTAMP=$(date +%Y%m%d%H%M%S)
  FILENAME="/backup/${DB}_backup_${TIMESTAMP}.sql"

  # Dump the database.
  if mysqldump -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
       --single-transaction --quick --compress "${DB}" >"${FILENAME}"; then
    log "Database dump completed successfully for ${DB}"
  else
    log "ERROR: Failed to dump database ${DB}"
    exit 1
  fi

  # Upload the backup file to Google Cloud Storage.
  if gsutil cp "${FILENAME}" "gs://${GCS_BUCKET}/${GCS_BUCKET_DIR}/"; then
    log "Uploaded backup for ${DB} to Google Cloud Storage."
  else
    log "ERROR: Failed to upload backup for ${DB} to GCS."
    exit 1
  fi

  log "Backup for ${DB} completed successfully."
done

log "Waiting for final operations to complete..."
sleep 60

log "Terminating Cloud SQL proxy..."
if curl -s "${PROXY_QUIT_URL}" >/dev/null; then
  log "Cloud SQL proxy terminated successfully."
else
  log "ERROR: Failed to terminate Cloud SQL proxy."
  exit 1
fi

log "Backup and shutdown process completed."
