# GitHub Actions Integration Setup

This guide explains how to configure the GitHub Actions CI/CD pipeline for building, testing, scanning, signing, and publishing your nginx Docker images.

## Overview

The CI/CD pipeline automatically:
- ✅ Validates configuration and lints Dockerfile
- ✅ Builds multi-platform images (linux/amd64, linux/arm64)
- ✅ Runs smoke tests and read-only filesystem tests
- ✅ Scans for vulnerabilities with Trivy
- ✅ Generates SBOMs (Software Bill of Materials)
- ✅ Signs images with Cosign (keyless signing)
- ✅ Publishes to Docker Hub and GitHub Container Registry (ghcr.io)
- ✅ Updates Docker Hub description from README.md

## Required Setup

### 1. Docker Hub (Optional but Recommended)

If you want to publish to Docker Hub:

1. Create a Docker Hub account at https://hub.docker.com
2. Generate an access token:
   - Go to Account Settings → Security → New Access Token
   - Give it a descriptive name (e.g., "GitHub Actions")
   - Copy the token (you won't see it again!)

3. Add GitHub repository secrets:
   - Go to your GitHub repo → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Add `DOCKERHUB_USERNAME` with your Docker Hub username
   - Add `DOCKERHUB_TOKEN` with the access token (NOT your password)

**Note:** If you skip this step, the workflow will still publish to GitHub Container Registry only.

### 2. GitHub Container Registry (Automatic)

GHCR.io is automatically available for your repository:
- No setup required!
- Uses `GITHUB_TOKEN` (automatically provided)
- Images will be published to `ghcr.io/<your-username>/nginx`

### 3. Image Signing with Cosign (Automatic)

The workflow uses **keyless signing** via Sigstore:
- No manual key generation needed
- Uses GitHub's OIDC token for authentication
- Signatures are stored in the transparency log

To verify signed images:
```bash
cosign verify ghcr.io/<your-username>/nginx:1.29.3 \
  --certificate-identity https://github.com/<your-username>/<repo>/.github/workflows/ci.yml@refs/heads/master \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

### 4. Security Scanning (Automatic)

Trivy scanning is built-in:
- Scans run on every build
- Results uploaded to GitHub Security tab
- No additional setup required

## Image Registry Configuration

### Update Image Names

Edit `.github/workflows/ci.yml` line 15-16 to use your Docker Hub username:

```yaml
env:
  DOCKER_HUB_IMAGE: your-username/nginx
  GHCR_IMAGE: ghcr.io/${{ github.repository_owner }}/nginx
```

Also update `Makefile` line 7:
```makefile
IMAGE_REPO := your-username/nginx
```

## Workflow Behavior

### On Pull Requests
- Validates configuration
- Builds images (both platforms)
- Runs all tests
- Scans for vulnerabilities
- Does NOT publish

### On Push to `master` branch
- All of the above, PLUS:
- Publishes to Docker Hub (if credentials configured)
- Publishes to GHCR.io (always)
- Signs images with Cosign
- Updates Docker Hub description

### On Version Tags (v*.*.*)
- Same as push to master
- Creates release artifacts

### Weekly Schedule
- Runs security scans on latest published images
- Keeps you informed of new vulnerabilities

## Published Image Tags

When publishing, the workflow creates these tags:

**Docker Hub** (if configured):
- `your-username/nginx:latest`
- `your-username/nginx:1.29.3`
- `your-username/nginx:1.29.3-openssl-3.6.0`

**GitHub Container Registry** (always):
- `ghcr.io/your-username/nginx:latest`
- `ghcr.io/your-username/nginx:1.29.3`
- `ghcr.io/your-username/nginx:1.29.3-openssl-3.6.0`

## Artifacts

The workflow generates:
- **SBOM files**: Available as workflow artifacts for 90 days
  - `sbom-spdx.json` (SPDX format)
  - `sbom-cyclonedx.json` (CycloneDX format)
- **Security scan results**: Viewable in GitHub Security tab
- **Build logs**: Available in Actions tab

## Troubleshooting

### "Resource not accessible by integration" error
- Check that repository permissions allow GHCR.io publishing
- Go to Settings → Actions → General → Workflow permissions
- Select "Read and write permissions"

### Docker Hub authentication fails
- Verify `DOCKERHUB_USERNAME` secret is correct
- Verify `DOCKERHUB_TOKEN` is an access token, not your password
- Check token hasn't expired

### Build fails on ARM64
- This is normal if QEMU emulation times out
- Increase timeout or build on native ARM64 runner
- Consider using GitHub's ARM64 runners for faster builds

### Cosign signing fails
- Ensure `id-token: write` permission is set in workflow
- Check that workflow is running on a branch, not a fork PR

## Manual Triggering

You can manually trigger the workflow:
1. Go to Actions tab
2. Select "CI/CD Pipeline"
3. Click "Run workflow"
4. Choose branch and click "Run workflow"

## Cost Considerations

- GitHub Actions: Free for public repos, 2000 minutes/month for private
- Multi-platform builds: Use ~30-45 minutes per build (QEMU emulation)
- Consider using native ARM64 runners to reduce build times
- GHCR.io: Free for public images
- Docker Hub: Free tier includes unlimited public repos

## Next Steps

1. Set up Docker Hub credentials (optional)
2. Update image names in workflow and Makefile
3. Push to trigger your first workflow run
4. Check Actions tab to monitor progress
5. Verify images published to registries
6. Test image signature verification
