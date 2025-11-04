#!/bin/bash
set -euo pipefail

# Smoke tests for nginx Docker image

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

source versions.env

IMAGE="cmooreio/nginx:$VERSION"

echo "Running smoke tests on $IMAGE..."

# Test 1: nginx binary exists and is executable
echo "Test 1: nginx binary..."
docker run --rm "$IMAGE" which nginx

# Test 2: nginx version check
echo "Test 2: nginx version..."
docker run --rm "$IMAGE" nginx -v

# Test 3: nginx configuration test
echo "Test 3: Configuration syntax..."
docker run --rm "$IMAGE" nginx -t

# Test 4: Check installed modules
echo "Test 4: Check modules..."
docker run --rm "$IMAGE" nginx -V 2>&1 | grep -q "http_ssl_module"
docker run --rm "$IMAGE" nginx -V 2>&1 | grep -q "http_v2_module"

# Test 5: User is nginx (non-root)
echo "Test 5: Non-root user..."
docker run --rm "$IMAGE" id | grep -q "uid=101(nginx)"

# Test 6: Required files exist
echo "Test 6: Required files..."
docker run --rm "$IMAGE" test -f /etc/nginx/nginx.conf
docker run --rm "$IMAGE" test -f /usr/sbin/nginx

# Test 7: Modules are loadable
echo "Test 7: Module loading..."
docker run --rm "$IMAGE" sh -c 'ls /usr/lib/nginx/modules/*.so' | grep -q "ngx_http_brotli"

echo "✓ All smoke tests passed"
