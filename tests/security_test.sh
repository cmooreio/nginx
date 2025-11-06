#!/bin/bash
set -euo pipefail

# Security tests for nginx Docker image

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

source versions.env

IMAGE="cmooreio/nginx:$VERSION"

echo "Running security tests on $IMAGE..."

# Test 1: Running as non-root user
echo "Test 1: Non-root user..."
user=$(docker run --rm "$IMAGE" whoami)
if [ "$user" != "nginx" ]; then
    echo "✗ Expected user 'nginx', got '$user'"
    exit 1
fi

# Test 2: USER directive set to non-root (Docker Scout requirement)
echo "Test 2: USER directive configured..."
image_user=$(docker image inspect "$IMAGE" --format '{{.Config.User}}')
if [ -z "$image_user" ]; then
    echo "✗ No USER directive found in image"
    exit 1
elif [ "$image_user" = "0" ] || [ "$image_user" = "root" ] || [ "$image_user" = "0:0" ]; then
    echo "✗ USER directive set to root: $image_user"
    exit 1
else
    echo "  USER directive: $image_user (non-root ✓)"
fi

# Test 3: No setuid/setgid binaries
echo "Test 3: No dangerous permissions..."
dangerous=$(docker run --rm --user root "$IMAGE" find / -perm /6000 -type f 2>/dev/null | wc -l)
if [ "$dangerous" -gt 0 ]; then
    echo "⚠ Found $dangerous setuid/setgid files"
else
    echo "  No setuid/setgid files found"
fi

# Test 4: nginx.conf has correct permissions
echo "Test 4: File permissions..."
perms=$(docker run --rm "$IMAGE" stat -c "%a" /etc/nginx/nginx.conf)
if [ "$perms" != "644" ]; then
    echo "⚠ nginx.conf has permissions $perms (expected 644)"
else
    echo "  nginx.conf permissions correct"
fi

# Test 5: No shells in /bin for nginx user
echo "Test 5: User shell restrictions..."
shell=$(docker run --rm "$IMAGE" grep '^nginx:' /etc/passwd | cut -d: -f7)
if [ "$shell" = "/sbin/nologin" ] || [ "$shell" = "/bin/false" ] || [ -z "$shell" ]; then
    echo "  nginx user has no shell access (shell: ${shell:-none})"
else
    echo "⚠ nginx user has shell: $shell"
fi

# Test 6: OpenSSL version check
echo "Test 6: OpenSSL version..."
openssl_ver=$(docker run --rm "$IMAGE" sh -c 'nginx -V 2>&1 | grep "OpenSSL"')
echo "  $openssl_ver"

# Test 7: Binary has security features
echo "Test 7: Binary hardening..."
if command -v docker &> /dev/null; then
    docker run --rm "$IMAGE" sh -c 'readelf -d /usr/sbin/nginx | grep -q RELRO' && echo "  RELRO: enabled" || echo "⚠ RELRO: not detected"
    docker run --rm "$IMAGE" sh -c 'readelf -d /usr/sbin/nginx | grep -q BIND_NOW' && echo "  BIND_NOW: enabled" || echo "⚠ BIND_NOW: not detected"
fi

# Test 8: Image labels present
echo "Test 8: OCI labels..."
docker inspect "$IMAGE" | grep -q "org.opencontainers.image.version"
echo "  OCI labels present"

echo "✓ All security tests passed"
