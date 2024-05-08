# Use the Google Cloud SDK base image
FROM google/cloud-sdk:latest

# Install MySQL client
RUN apt-get update && apt-get install -y default-mysql-client wget

# Create a non-root user and group
# Note: Ensure the user and group IDs do not conflict with IDs on the host or in other containers
RUN groupadd -r mysqlbackup -g 3000 && \
    useradd -r -g mysqlbackup -u 1001 -m -d /backup mysqlbackup

# Create a directory for the backup and set permissions
WORKDIR /backup
RUN chown mysqlbackup:mysqlbackup /backup

# Copy the backup script into the container
COPY backup.sh /backup/backup.sh
RUN chmod +x /backup/backup.sh
RUN chown mysqlbackup:mysqlbackup /backup/backup.sh

# Use the non-root user to run the container
USER mysqlbackup

# Set the entry point to the backup script
ENTRYPOINT ["/backup/backup.sh"]
