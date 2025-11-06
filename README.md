# nginx

[![Docker Hub](https://img.shields.io/docker/v/cmooreio/nginx?sort=semver)](https://hub.docker.com/r/cmooreio/nginx)
[![Docker Image Size](https://img.shields.io/docker/image-size/cmooreio/nginx/latest)](https://hub.docker.com/r/cmooreio/nginx)
[![License](https://img.shields.io/github/license/cmooreio/nginx)](LICENSE)

nginx running on Alpine Linux, built from source with OpenSSL 3.x and multiple additional modules for enhanced functionality and security.

## Features

- **Modern TLS**: Built with OpenSSL 3.6.0
- **Security Hardened**: Runs as non-root, verified sources, minimal attack surface
- **Multi-platform**: Supports amd64 and arm64 architectures
- **Production Ready**: Health checks, proper logging, Docker Business compliant
- **Enhanced Modules**: Brotli compression, GeoIP, JavaScript (njs), and more

## Quick Start

### Basic Usage

```bash
docker run --rm -it -p 80:80 cmooreio/nginx:latest
```

Test the server:

```bash
$ curl -sSL -D - http://localhost -o /dev/null | head -n 2
HTTP/1.1 200 OK
Server: nginx/1.29.3
```

### Docker Compose (Recommended)

For production deployments with security hardening:

```bash
docker compose up -d
```

The provided `docker-compose.yml` includes:
- Read-only root filesystem
- Dropped capabilities (principle of least privilege)
- Resource limits
- Proper tmpfs mounts for writable directories
- Health checks

## Included Modules

### Compression
- **ngx_http_brotli_filter_module** - Dynamic Brotli compression
- **ngx_http_brotli_static_module** - Serve pre-compressed Brotli files

### Enhancement
- **ngx_http_fancyindex_module** - Enhanced directory listings
- **ngx_http_headers_more_filter_module** - Custom HTTP header manipulation
- **ngx_http_image_filter_module** - On-the-fly image transformations
- **ngx_http_js_module** - JavaScript scripting (njs)
- **ngx_http_perl_module** - Perl scripting
- **ngx_http_xslt_filter_module** - XSLT transformations

### Networking
- **ngx_http_geoip_module** - GeoIP-based request handling
- **ngx_mail_module** - Mail proxy (SMTP, POP3, IMAP)
- **ngx_stream_module** - TCP/UDP load balancing and proxying
- **ngx_stream_geoip_module** - GeoIP support for stream module

## Version Info

Current versions:
- **nginx**: 1.29.3
- **OpenSSL**: 3.6.0
- **PCRE2**: 10.47
- **Alpine Linux**: 3.22
- **zlib**: Cloudflare fork (optimized)

```bash
$ docker run --rm cmooreio/nginx:latest nginx -V
nginx version: nginx/1.29.3
built by gcc 14.2.0 (Alpine 14.2.0)
built with OpenSSL 3.6.0 1 Oct 2025
TLS SNI support enabled
```

## Security

This image follows Docker Business security best practices:

### Build-Time Security
- ✅ **Compiler Hardening**: Stack protection, FORTIFY_SOURCE, RELRO
- ✅ **Static Linking**: OpenSSL statically linked (no-shared) for immutable crypto
- ✅ **Supply Chain Security**: All git commits pinned, sources verified with SHA256
- ✅ **Minimal Attack Surface**: Build tools removed, debug symbols stripped

### Runtime Security
- ✅ **Non-Root Execution**: Runs as nginx:nginx (UID 101, GID 101)
- ✅ **Read-Only Filesystem**: Compatible with read-only root filesystem
- ✅ **Minimal Capabilities**: Drops all capabilities except required
- ✅ **Binary Hardening**: RELRO, BIND_NOW, stack canaries

### Supply Chain
- ✅ **SBOM Generation**: Software Bill of Materials in SPDX/CycloneDX formats
- ✅ **Image Signing**: Cosign signatures for verification
- ✅ **Provenance**: Build attestation included
- ✅ **Automated Scanning**: Trivy/Grype in CI pipeline
- ✅ **Dependency Updates**: Renovate + Dependabot automation

## For Developers

### Prerequisites

- Docker 20.10+ with Buildx
- Make
- Git
- (Optional) Trivy/Grype for scanning
- (Optional) Cosign for signing

### Quick Start

```bash
# Using Makefile (recommended)
make build       # Build for native architecture (fast, no emulation)
make build-multi # Build for all platforms (amd64, arm64) - slower
make test        # Run tests
make scan        # Security scan

# Or use build script directly
./build.sh
./build.sh --dry-run  # See command without executing
```

**Note**: The Makefile auto-detects your system architecture and builds natively by default to avoid slow QEMU emulation. Use `make build-multi` only when you need multi-platform images.

## Building

### Using Makefile (Recommended)

```bash
# Full pipeline
make all        # validate + build + test + scan

# Individual steps
make validate   # Validate configuration
make lint       # Lint Dockerfile and scripts
make build      # Build for native platform (linux/arm64 or linux/amd64)
make build-multi # Build for all platforms (requires QEMU emulation)
make test       # Run all tests
make scan       # Security scan
make push       # Build and push multi-platform to registry

# Architecture info
make version    # Show versions and detected platform

# See all targets
make help
```

**Platform Detection**: The Makefile automatically detects your system architecture:

- **Apple Silicon Mac**: Builds for `linux/arm64` natively (fast)
- **Intel Mac/x86 Linux**: Builds for `linux/amd64` natively (fast)
- **Multi-platform**: Use `make build-multi` or `make push` (slower, uses QEMU)

### Using build script

```bash
export VERSION=1.29.3
export SHA256=9befcced12ee09c2f4e1385d7e8e21c91f1a5a63b196f78f897c2d044b8c9312
export PCRE2_VERSION=10.47
export PCRE2_SHA256=c08ae2388ef333e8403e670ad70c0a11f1eed021fd88308d7e02f596fcd9dc16
export ZLIB_COMMIT_SHA=1252e2565573fe150897c9d8b44d3453396575ff
export OPENSSL_VERSION=3.6.0
export OPENSSL_SHA256=b6a5f44b7eb69e3fa35dbf15524405b44837a481d43d81daddde3ff21fcbb8e9

docker buildx build --no-cache --platform linux/amd64,linux/arm64 \
  --build-arg VERSION --build-arg SHA256 \
  --build-arg PCRE2_VERSION --build-arg PCRE2_SHA256 \
  --build-arg ZLIB_COMMIT_SHA \
  --build-arg OPENSSL_VERSION --build-arg OPENSSL_SHA256 \
  --build-arg MORE_HEADERS_COMMIT_SHA \
  -t cmooreio/nginx:latest \
  -t cmooreio/nginx:${VERSION} \
  -t cmooreio/nginx:${VERSION}-openssl-${OPENSSL_VERSION} \
  --pull --push .
```

## Deployment Best Practices

### Production Configuration

1. **Use Docker Compose**: See `docker-compose.yml` for hardened configuration
2. **Enable Health Checks**: Already configured in image and compose file
3. **Resource Limits**: Set appropriate CPU and memory limits
4. **Read-only Filesystem**: Mount root filesystem as read-only
5. **Least Privilege**: Drop all unnecessary Linux capabilities
6. **Custom Config**: Mount your nginx.conf and sites as read-only volumes

### Example with Custom Config

```yaml
services:
  nginx:
    image: cmooreio/nginx:latest
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./conf.d:/etc/nginx/conf.d:ro
      - ./html:/etc/nginx/html:ro
      - ./ssl:/etc/nginx/ssl:ro
    ports:
      - "80:80"
      - "443:443"
    read_only: true
    tmpfs:
      - /var/cache/nginx:uid=101,gid=101
      - /var/run:uid=101,gid=101
```

## Testing

```bash
# Run all tests
make test

# Individual test suites
make smoke-test        # Basic functionality
make integration-test  # Full integration tests
make -C tests security # Security-specific tests
```

## Building & Publishing

This project uses manual build and publish workflows.

### Quick Build

Build for your native architecture:
```bash
make build  # Fast native build (10-15 min)
```

### Multi-Platform Build

Build for both amd64 and arm64:
```bash
make build-multi  # Multi-platform build (30-45 min, uses QEMU)
```

### Publishing Images

Build and push to your container registry:
```bash
# Configure your registry in Makefile (IMAGE_REPO variable)
make push         # Build and push multi-platform
make push-signed  # Build, push, and sign with Cosign
```

### Available Images

**Docker Hub**: `cmooreio/nginx:latest`

### Security Tools

Optional security scanning and SBOM generation:
```bash
make scan  # Vulnerability scan with Trivy
make sbom  # Generate Software Bill of Materials
```

## Tags

- `latest` - Latest stable nginx version
- `1.29.3` - Specific nginx version
- `1.29.3-openssl-3.6.0` - nginx + OpenSSL version tag

## Project Structure

```text
.
├── .github/
│   ├── dependabot.yml      # Dependency updates
│   └── renovate.json       # Renovate config
├── tests/                  # Test suite
│   ├── smoke_test.sh
│   ├── integration_test.sh
│   └── security_test.sh
├── Dockerfile              # Hardened image build
├── Makefile                # Build automation
├── build.sh                # Secure build script
├── docker-compose.yml      # Production deployment
├── versions.env            # Centralized versions
├── CLAUDE.md               # Project instructions
```

## License

[MIT License](LICENSE)

## Support

- **Issues**: [GitHub Issues](https://github.com/cmooreio/nginx/issues)
- **Docker Hub**: [cmooreio/nginx](https://hub.docker.com/r/cmooreio/nginx)
