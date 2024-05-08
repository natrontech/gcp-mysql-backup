#!/bin/bash
# Environment variables: MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASES, GCS_BUCKET, PROXY_PORT=3306, PROXY_QUIT_URL

# Exit on any error
set -e

# Split the database names separated by commas (also when only one database is provided)
IFS=',' read -ra DB_ARRAY <<< "$MYSQL_DATABASES"

# Loop over each database name and perform a backup
for DB in "${DB_ARRAY[@]}"; do
    echo "Starting backup for database: $DB"

    # Dump the database into a SQL file
    FILENAME="/backup/${DB}_backup_$(date +%Y%m%d%H%M%S).sql"
    mysqldump -h$MYSQL_HOST -P$PROXY_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD $DB > $FILENAME

    # Upload the backup to Google Cloud Storage
    echo "Uploading $DB backup to Google Cloud Storage..."
    gsutil cp $FILENAME gs://$GCS_BUCKET/$DB/

    echo "Backup for $DB completed successfully."
done

# Give time for all operations to complete
echo "Waiting for final operations to complete..."
sleep 60

# Kill the Cloud SQL proxy process using the provided URL
echo "Terminating Cloud SQL proxy..."
wget -qO- $PROXY_QUIT_URL

echo "Backup and shutdown process completed."
