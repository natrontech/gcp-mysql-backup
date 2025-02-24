# Security Policy

## Reporting Security Issues

The contributor and community take security bugs in gcp-mysql-backup seriously. We appreciate your efforts to responsibly disclose your findings, and will make every effort to acknowledge your contributions.

To report a security issue, please use the GitHub Security Advisory ["Report a Vulnerability"](https://github.com/natrontech/gcp-mysql-backup/security/advisories/new) tab.

The contributor will send a response indicating the next steps in handling your report. After the initial reply to your report, the security team will keep you informed of the progress towards a fix and full announcement, and may ask for additional information or guidance.

## Release verification

The release workflow creates provenance for its builds using the [SLSA standard](https://slsa.dev), which conforms to the [Level 3 specification](https://slsa.dev/spec/v1.0/levels#build-l3).

All signatures are created by [Cosign](https://github.com/sigstore/cosign) using the [keyless signing](https://docs.sigstore.dev/verifying/verify/#keyless-verification-using-openid-connect) method.

### Prerequisites

To verify the release artifacts, you will need the [slsa-verifier](https://github.com/slsa-framework/slsa-verifier), [cosign](https://github.com/sigstore/cosign) and [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md) binaries.

### Version

All of the following commands require the `VERSION` environment variable to be set to the version of the release you want to verify. You can set the variable manually or the the latest version with the following command:

```bash
# get the latest release
export VERSION=$(curl -s "https://api.github.com/repos/natrontech/gcp-mysql-backup/releases/latest" | jq -r '.tag_name')
```

### Verify provenance of container images

**Verify with SLSA verifier**

The `slsa-verifier` can also verify docker images. Verification can be done by tag or by digest. We recommend to always use the digest to prevent [TOCTOU attacks](https://github.com/slsa-framework/slsa-verifier?tab=readme-ov-file#toctou-attacks), as an image tag is not immutable.

```bash
IMAGE=ghcr.io/natrontech/gcp-mysql-backup:$VERSION

# get the image digest and append it to the image name
#   e.g. ghcr.io/natrontech/gcp-mysql-backup:v0.2.0@sha256:...
IMAGE="${IMAGE}@"$(crane digest "${IMAGE}")

# verify the image
slsa-verifier verify-image \
  --source-uri github.com/natrontech/gcp-mysql-backup \
  --provenance-repository ghcr.io/natrontech/signatures \
  --source-versioned-tag $VERSION \
  $IMAGE
```

The output should be: `PASSED: Verified SLSA provenance`.

**Verify with Cosign**

As an alternative to the SLSA verifier, you can use `cosign` to verify the provenance of the container images. Cosign also supports validating the attestation against `CUE` policies (see [Validate In-Toto Attestation](https://docs.sigstore.dev/verifying/attestation/#validate-in-toto-attestations) for more information), which is useful to ensure that some specific requirements are met. We provide a [policy.cue](./policy.cue) file to verify the correct workflow has triggered the release and that the image was generated from the correct source repository. 

```bash
# download policy.cue
curl -L -O https://raw.githubusercontent.com/natrontech/gcp-mysql-backup/main/policy.cue

# verify the image with cosign
COSIGN_REPOSITORY=ghcr.io/natrontech/signatures cosign verify-attestation \
  --type slsaprovenance \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$' \
  --policy policy.cue \
  $IMAGE | jq
```

### Verify signature of container image

The container images are additionally signed with cosign. The signature can be verified with the `cosign` binary.
**Important**: only the multi-arch image is signed, not the individual platform images.

```bash
COSIGN_REPOSITORY=ghcr.io/natrontech/signatures cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/natrontech/gcp-mysql-backup/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?$' \
  $IMAGE | jq
```

> [!IMPORTANT]
> Verifying the provenance of a container image ensures the integrity and authenticity of the image because the provenance (with the image digest) is signed with Cosign. The container images themselves are also signed with Cosign, but the signature is not necessary for verification if the provenance is verified. Provenance verification is a stronger security guarantee than image signing because it verifies the entire build process, not just the final image. Image signing is therefore not essential if provenance verification is.

### SBOM

The Software Bill of Materials (SBOM) is generated in CycloneDX JSON format for each release and can be used to verify the project's dependencies.

#### Container images

The SBOMs of the container is attestated with Cosign and uploaded to the `ghcr.io/natrontech/sbom` repository. The SBOMs can be verified with the `cosign` binary.

**Important**: Only the multi-arch image has a SBOM, not the individual platform images.

**Verify provenance of the SBOM**

```bash
# download policy-sbom.cue
curl -L -O https://raw.githubusercontent.com/natrontech/gcp-mysql-backup/main/policy-sbom.cue

COSIGN_REPOSITORY=ghcr.io/natrontech/sbom cosign verify-attestation \
  --type cyclonedx \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/natrontech/gcp-mysql-backup/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?$' \
  --policy policy-sbom.cue \
  $IMAGE | jq -r '.payload' | base64 -d | jq
```

**Download SBOM**

If you want to download the SBOM of the container image, you can use the following command:

```bash
COSIGN_REPOSITORY=ghcr.io/natrontech/sbom cosign verify-attestation \
  --type cyclonedx \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/natrontech/gcp-mysql-backup/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?$' \
  --policy policy-sbom.cue \
  $IMAGE | jq -r '.payload' | base64 -d | jq -r '.predicate' > sbom.json
```
