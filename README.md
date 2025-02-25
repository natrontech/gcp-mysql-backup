# MySQL Backup Docker Container

[![license](https://img.shields.io/github/license/natrontech/gcp-mysql-backup)](https://github.com/natrontech/gcp-mysql-backup/blob/main/LICENSE)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/natrontech/gcp-mysql-backup/badge)](https://securityscorecards.dev/viewer/?uri=github.com/natrontech/gcp-mysql-backup)
[![release](https://img.shields.io/github/v/release/natrontech/gcp-mysql-backup)](https://github.com/natrontech/gcp-mysql-backup/releases)
[![SLSA 3](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev)

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

## Release

Each release of the application includes the container images. 

The release workflow creates provenance for its builds using the [SLSA standard](https://slsa.dev), which conforms to the [Level 3 specification](https://slsa.dev/spec/v1.0/levels#build-l3). Each artifact can be verified using the `slsa-verifier` or `cosign` tool (see [Release verification](SECURITY.md#release-verification)).
