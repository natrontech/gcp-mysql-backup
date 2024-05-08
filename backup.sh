#!/bin/bash
# Enable parallel composite uploads
echo "[GSUtil]" >>~/.boto
echo "parallel_composite_upload_threshold = 150M" >>~/.boto

set -e

trap 'catchError' ERR

function catchError {
    echo "An error occurred during the backup of $DB." # maybe proxy is not ready
    exit 1
}

IFS=',' read -ra DB_ARRAY <<<"$MYSQL_DATABASES"

for DB in "${DB_ARRAY[@]}"; do
    echo "Starting backup for database: $DB"
    FILENAME="/backup/${DB}_backup_$(date +%Y%m%d%H%M%S).sql"
    mysqldump -h "${MYSQL_HOST}" -P "${PROXY_PORT}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --single-transaction --quick --compress "${DB}" >"${FILENAME}"
    echo "Uploading $DB backup to Google Cloud Storage..."
    gsutil cp "${FILENAME}" "gs://${GCS_BUCKET}/${GCS_BUCKET_DIR}/"
    echo "Backup for $DB completed successfully."
done

echo "Waiting for final operations to complete..."
sleep 60
echo "Terminating Cloud SQL proxy..."
curl -s "${PROXY_QUIT_URL}"

echo "Backup and shutdown process completed."
