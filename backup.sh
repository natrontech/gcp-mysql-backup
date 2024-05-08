#!/bin/bash
# Environment variables: MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASES, GCS_BUCKET

# Exit on any error
set -e

# Split the database names separated by commas
IFS=',' read -ra DB_ARRAY <<< "$MYSQL_DATABASES"

# Loop over each database name and perform a backup
for DB in "${DB_ARRAY[@]}"; do
    echo "Starting backup for database: $DB"

    # Dump the database into a SQL file
    FILENAME="/backup/${DB}_backup_$(date +%Y%m%d%H%M%S).sql"
    mysqldump -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD $DB > $FILENAME

    # Upload the backup to Google Cloud Storage
    echo "Uploading $DB backup to Google Cloud Storage..."
    gsutil cp $FILENAME gs://$GCS_BUCKET/$DB/

    echo "Backup for $DB completed successfully."
done
