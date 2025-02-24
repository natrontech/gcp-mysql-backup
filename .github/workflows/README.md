# GitHub Workflows

## Overview

Following workflows are implemented in the repository.
[SARIF](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/sarif-support-for-code-scanning) is used to store the results for an analysis of code scanning tools in the Security tab of the repository.

| Workflow                         | Jobs                            | Trigger                                                       | SARIF upload | Description                                                              |
| :------------------------------- | :------------------------------ | :------------------------------------------------------------ | :----------- | ------------------------------------------------------------------------ |
| [cleanup.yml](./cleanup.yml)     | `clean`                         | workflow_dispatch, cron `0 0 * * *`                           | -            | Cleanup all untagged tags from GHCR repository which are older than `2w` |
| [release.yml](./release.yml)     | see [release chapter](#release) | push tag `v*`, cron `20 14 * * *`, pr on `main`               | -            | Create release with go binaries and docker container                     |
| [scorecard.yml](./scorecard.yml) | `analyze`                       | push to `main`, cron: `00 14 * * 1`, change branch protection | yes          | Create OpenSSF analysis and create project score                         |

## Release

The release workflow includes multiple jobs to create a release of the project. Following jobs are implemented:

| Job                        | GitHub Action                                                                                                              | Description                                                                  |
| :------------------------- | :------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------- |
| `docker-publish`           | -                                                                                                                          | Build and sign the container image, create and sign the SBOM with Syft       |
| `image-provenance`         | [generator_container_slsa3](https://github.com/slsa-framework/slsa-github-generator/tree/main/internal/builders/container) | Generates provenance for the container images                                |
| `verification-with-cosign` | -                                                                                                                          | Verifying the cryptographic signatures on provenance for the container image |

### Container Release

The docker image provenance is generated using the [SLSA Container Generator](https://github.com/slsa-framework/slsa-github-generator/tree/main/internal/builders/container) and uploaded to the GitHub registry. The provenance can be verified using the `slsa-verifier` or `cosign` tool (see [Release Verification](./../../SECURITY.md#release-verification)).

### Container SBOM

The SBOMs of the container images are uploaded to a separate package registry (see [SBOM](./../../SECURITY.md#sbom) for more information).

## Scorecards

Action: https://github.com/ossf/scorecard-action

[Scorecards](https://github.com/ossf/scorecard) is a tool that provides a security score for open-source projects. The workflow runs the scorecard on the repository and uploads the results to the Security tab of the repository. There is also a report on the OpenSSF website, the link is available in the README file by clicking on the OpenSSF Scorecard badge.

[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/natrontech/gcp-mysql-backup/badge)](https://securityscorecards.dev/viewer/?uri=github.com/natrontech/gcp-mysql-backup)
