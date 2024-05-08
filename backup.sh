#!/bin/bash
# Environment variables: MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASES, GCS_BUCKET, PROXY_PORT

# Exit on any error
set -e

# Split the database names separated by commas (also when only one database is provided)
IFS=',' read -ra DB_ARRAY <<< "$MYSQL_DATABASES"

# Loop over each database name and perform a backup
for DB in "${DB_ARRAY[@]}"; do
    echo "Starting backup for database: $DB"

    # Construct filename for backup
    FILENAME="/backup/${DB}_backup_$(date +%Y%m%d%H%M%S).sql"

    # Dump the database into a SQL file
    # Ensure proper spacing and use of command options
    mysqldump -h "${MYSQL_HOST}" -P "${PROXY_PORT}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${DB}" > "${FILENAME}"

    # Upload the backup to Google Cloud Storage
    echo "Uploading $DB backup to Google Cloud Storage..."
    gsutil cp "${FILENAME}" "gs://${GCS_BUCKET}/${GCS_BUCKET_DIR}/"

    echo "Backup for $DB completed successfully."
done

# Wait for a minute to allow all operations to complete
echo "Waiting for final operations to complete..."
sleep 60

# Use wget to send a quit command to the Cloud SQL proxy
echo "Terminating Cloud SQL proxy..."
wget -qO- "${PROXY_QUIT_URL}"

echo "Backup and shutdown process completed."
