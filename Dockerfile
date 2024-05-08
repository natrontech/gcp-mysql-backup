# Use the Google Cloud SDK base image
FROM google/cloud-sdk:latest

# Install MySQL client
RUN apt-get update && apt-get install -y default-mysql-client

# Create a directory for the backup
WORKDIR /backup

# Copy the backup script into the container
COPY backup.sh /backup/backup.sh

# Make the backup script executable
RUN chmod +x /backup/backup.sh

# Set the entry point to the backup script
ENTRYPOINT ["/backup/backup.sh"]
