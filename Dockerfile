FROM google/cloud-sdk:alpine

# Install dependencies in one layer and clean up apt caches
RUN apk update && \
    apk add --no-cache mysql-client curl

# Create a dedicated non-root user and group
RUN addgroup -g 3000 mysqlbackup && \
    adduser -D -u 1001 -G mysqlbackup -h /backup mysqlbackup

WORKDIR /backup

COPY --chown=mysqlbackup:mysqlbackup backup.sh /backup/backup.sh
RUN chmod +x /backup/backup.sh

USER mysqlbackup

ENTRYPOINT ["/backup/backup.sh"]
