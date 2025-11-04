# CLAUDE.md

Instructions for Claude Code when working with this nginx Docker image project.

## Quick Reference

**Build**: `make build` (native platform, fast) or `make build-multi` (all platforms, slow)
**Test**: `make test` or `docker compose up -d`
**Versions**: All in `versions.env`
**Base**: Alpine 3.22, nginx 1.29.3, OpenSSL 3.6.0

## Key Commands

```bash
make build       # Build native (linux/arm64 or linux/amd64)
make build-multi # Build multi-platform (amd64 + arm64, slow)
make test        # Run tests
make scan        # Security scan
make version     # Show versions and detected platform
```

## Build Architecture

**Single-RUN Dockerfile** to minimize layers:
1. Install Alpine build tools + libs
2. Download & verify sources (nginx, PCRE2, Cloudflare zlib, OpenSSL) using `sha256sum -c`
3. Clone third-party modules with `--depth 1` (commits pinned in `versions.env`)
4. Configure nginx with static OpenSSL (`no-shared`), PCRE2, Cloudflare zlib
5. Compile with hardened flags, strip binaries
6. Create nginx user (UID 101, GID 101), cleanup, symlink logs

**Modules**: Brotli, headers-more, fancyindex, njs (JavaScript), GeoIP, image filter, Perl, XSLT, mail proxy, stream proxy

**Security**:
- Static OpenSSL linking (`no-shared`) for immutable crypto
- All git commits pinned via env vars
- Compiler flags: `-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security`
- Linker flags: `-Wl,-z,relro -Wl,-z,now`
- Non-root user (101:101)
- SHA256 verification for all sources

## Version Management

**All versions in `versions.env`** - update there, then:
1. Run `make build`
2. Test with `make test`
3. Update README.md version section if needed

**Sources**:
- nginx: https://nginx.org/en/download.html
- PCRE2: https://github.com/PCRE2Project/pcre2/releases
- zlib: https://github.com/cloudflare/zlib/commits/gcc.amd64/
- OpenSSL: https://www.openssl.org/source/
- Module commits: Pin SHAs in `versions.env`

## Important Files

- **versions.env**: All versions and checksums (single source of truth)
- **Dockerfile**: Single-RUN build, Alpine 3.22 base
- **Makefile**: Auto-detects architecture, provides targets
- **build.sh**: Build script (used by Makefile)
- **docker-compose.yml**: Hardened production deployment
- **nginx.conf**, **conf.d/default.conf**: Runtime configs

## Critical Rules

### Security
- **Checksums**: Always `echo "$SHA256 file" | sha256sum -c -` (not grep)
- **Git commits**: Must pin all via env vars (`BROTLI_COMMIT_SHA`, etc.)
- **OpenSSL**: Use `no-shared` for static linking
- **User**: nginx runs as UID 101, GID 101 (not 100!)
- **tmpfs**: Must use `uid=101,gid=101` in docker-compose.yml

### Dockerfile Changes
- Keep single-RUN pattern (minimize layers)
- Verify all downloads have SHA256 checks
- Update `versions.env` ARG list if adding dependencies
- Test read-only filesystem: `docker run --read-only --tmpfs /var/cache/nginx:uid=101,gid=101 --tmpfs /var/run:uid=101,gid=101 ...`

### Build Performance
- **Native** (`make build`): 10-15 min, no emulation
- **Multi-platform** (`make build-multi`): 30-45 min with QEMU
- Use native for development, multi-platform for releases only

### Common Tasks
- **Update nginx**: Change `VERSION` and `SHA256` in `versions.env`, run `make build`
- **Update OpenSSL**: Change `OPENSSL_VERSION` and `OPENSSL_SHA256`, rebuild
- **Update modules**: Change commit SHAs (`*_COMMIT_SHA`), rebuild
- **Test changes**: `make build && make test`
- **Check platforms**: `make version`
