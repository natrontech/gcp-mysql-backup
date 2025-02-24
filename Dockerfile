FROM google/cloud-sdk:latest

RUN apt-get update && apt-get install -y default-mysql-client curl

RUN groupadd -r mysqlbackup -g 3000 && \
    useradd -r -g mysqlbackup -u 1001 -m -d /backup mysqlbackup

WORKDIR /backup

RUN chown mysqlbackup:mysqlbackup /backup
COPY backup.sh /backup/backup.sh
RUN chmod +x /backup/backup.sh
RUN chown mysqlbackup:mysqlbackup /backup/backup.sh

USER mysqlbackup

ENTRYPOINT ["/backup/backup.sh"]
