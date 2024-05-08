# MySQL Backup Docker Container

This Docker container is designed to backup MySQL databases and upload the backups to Google Cloud Storage. It also handles the management of a Cloud SQL Proxy connection to securely connect to Google Cloud SQL instances without exposing them publicly.

## Features

- **Database Backups**: Supports backing up multiple databases configured via environment variables.
- **Google Cloud Storage**: Automatically uploads database backups to a specified GCS bucket.
- **Cloud SQL Proxy Management**: Manages the lifecycle of a Cloud SQL Proxy connection to secure database access.

## Prerequisites

- A Google Cloud account with a configured GCS bucket.
- Access to a Google Cloud SQL instance or any MySQL server.
- Docker installed on your machine or Kubernetes cluster.

## Configuration

### Environment Variables

This container relies on several environment variables for operation:

- `MYSQL_HOST` (**Required**): The hostname of the MySQL server.
- `MYSQL_USER` (**Required**): The username for the MySQL database.
- `MYSQL_PASSWORD` (**Required**): The password for the MySQL database (recommended to use Kubernetes secrets for Kubernetes deployments).
- `MYSQL_DATABASES` (**Required**): Comma-separated list of databases to backup.
- `GCS_BUCKET` (**Required**): The Google Cloud Storage bucket for storing backups.
- `GCS_BUCKET_DIR` (**Required**): The directory within the GCS bucket to store backups.
- `PROXY_PORT` (**Required**): The port on which the MySQL server or proxy is accessible (default 3306).
- `PROXY_QUIT_URL` (**Required**): URL to send the quit command to the Cloud SQL Proxy.

### Volumes

- `/backup`: The directory where database dumps are temporarily stored before being uploaded to GCS.

## Usage

### Running Locally

To run the Docker container locally:

```sh
docker run -e MYSQL_HOST='your-mysql-host' -e MYSQL_USER='user' -e MYSQL_PASSWORD='password' \
-e MYSQL_DATABASES='db1,db2' -e GCS_BUCKET='your-gcs-bucket' \
-e PROXY_QUIT_URL='http://localhost:9091/quitquitquit' \
-v your-local-backup-dir:/backup \
your-docker-image
```

### Deployment in Kubernetes

Create a read-only mysql user for the databases you want to backup:

```sql
CREATE USER 'backup'@'%' IDENTIFIED BY 'password';
GRANT SELECT, LOCK TABLES ON *.* TO 'backup'@'%';
```

Deploy this container in a Kubernetes cluster as part of a CronJob. Refer to the [deployment](./deployment/) directory for a Kubernetes deployment example.

```sh
kubectl apply -k deployment/
```

### GCP Service Account & IAM Role

Set up a service account in GCP and assign necessary roles for Cloud SQL and GCS access:

```sh
gcloud iam service-accounts create cloudsql-backup-sa --display-name "Cloud SQL Backup Service Account"

gcloud projects add-iam-policy-binding your-project-id \
--member serviceAccount:cloudsql-backup-sa@your-project-id.iam.gserviceaccount.com \
--role roles/cloudsql.client

gcloud projects add-iam-policy-binding your-project-id \
--member serviceAccount:cloudsql-backup-sa@your-project-id.iam.gserviceaccount.com \
--role roles/storage.objectAdmin
```

Bind this service account to your Kubernetes service account:

```sh
gcloud iam service-accounts add-iam-policy-binding \
--role roles/iam.workloadIdentityUser \
--member "serviceAccount:your-project-id.svc.id.goog[your-namespace/your-service-account]"
```

## Building the Docker Image

To build the image from the Dockerfile:

```sh
docker build -t your-custom-tag .
```

## Contributing

We welcome contributions! Please fork the repository and submit pull requests with your changes or improvements.

## License

Specify the license under which the project is available. Common licenses for open source projects include MIT, Apache 2.0, etc.

## Contact Information

For help or issues related to this project, please submit an issue to our GitHub repository or contact the maintainer at `support@natron.io`.
