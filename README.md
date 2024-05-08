# MySQL Backup Docker Container

This Docker container is designed to backup MySQL databases and upload the backups to Google Cloud Storage. It also handles the management of a Cloud SQL Proxy connection to securely connect to Google Cloud SQL instances without having to expose them publicly.

## Features

- **Database Backups**: Supports backing up multiple databases configured via environment variables.
- **Google Cloud Storage**: Uploads database backups directly to a configured GCS bucket.
- **Cloud SQL Proxy Management**: Handles the lifecycle of a Cloud SQL Proxy connection to secure database connections.

## Prerequisites

- A Google Cloud account and a configured GCS bucket.
- Access to a Google Cloud SQL instance or any MySQL server.
- Docker installed on your machine or Kubernetes cluster.

## Configuration

### Environment Variables

This container uses the following environment variables:

- `MYSQL_HOST`: The hostname of the MySQL server.
- `MYSQL_USER`: The username for the MySQL database.
- `MYSQL_PASSWORD`: The password for the MySQL database (use Kubernetes secrets for Kubernetes deployments).
- `MYSQL_DATABASES`: Comma-separated list of databases to backup.
- `GCS_BUCKET`: The Google Cloud Storage bucket where backups will be stored.
- `PROXY_PORT`: The port on which the MySQL server or proxy is accessible (default is 3306).
- `PROXY_QUIT_URL`: URL to send the quit command to Cloud SQL Proxy.

### Volumes

- `/backup`: This directory is where the database dumps are temporarily stored before being uploaded to GCS.

## Using the Docker Container

### Running Locally

```sh
docker run -e MYSQL_HOST='your-mysql-host' -e MYSQL_USER='user' -e MYSQL_PASSWORD='password' \
-e MYSQL_DATABASES='db1,db2' -e GCS_BUCKET='your-gcs-bucket' \
-e PROXY_QUIT_URL='http://localhost:9091/quitquitquit' \
-v your-local-backup-dir:/backup \
your-docker-image
```

### Deployment in Kubernetes

You can deploy this container in a Kubernetes cluster as part of a CronJob. Refer to the included `kubernetes-cronjob.yaml` file for a sample deployment configuration.

## Building the Docker Image

To build this image from the Dockerfile:

```sh
docker build -t your-custom-tag .
```

## Contributing

Contributions to this project are welcome! Please fork the repository and submit a pull request with your changes or improvements.

## License

Specify the license under which the project is available. Common licenses for open source projects include MIT, Apache 2.0, etc.

## Contact Information

For help or issues, please submit an issue to the project's GitHub repository or contact the maintainer at `support@natron.io`.


### Notes on the README

- **Detailed Instructions**: The README provides instructions on how to use the Docker image, including environment variables, volume mappings, and running the container.
- **Example Commands**: Commands for running the container both locally and within a Kubernetes environment are given to ease the usage.
- **Contribution Guidelines**: Encouraging contributions helps in the growth and maintenance of the project.
- **License**: It's important to specify a license if the project is open source. This governs how the project can be used and modified by others.
