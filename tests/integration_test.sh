#!/bin/bash
set -euo pipefail

# Integration tests for nginx Docker image

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

source versions.env

IMAGE="cmooreio/nginx:$VERSION"
CONTAINER_NAME="nginx-test-$$"

cleanup() {
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}

trap cleanup EXIT

echo "Running integration tests on $IMAGE..."

# Test 1: Container starts successfully
echo "Test 1: Container startup..."
docker run -d --name "$CONTAINER_NAME" -p 8080:80 "$IMAGE"
sleep 3

# Test 2: HTTP response
echo "Test 2: HTTP response..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$response" != "200" ]; then
    echo "✗ Expected HTTP 200, got $response"
    exit 1
fi

# Test 3: Response headers
echo "Test 3: Server header..."
server_header=$(curl -s -I http://localhost:8080 | grep -i "^server:")
echo "  $server_header"

# Test 4: Container logs contain no errors
echo "Test 4: Container logs..."
if docker logs "$CONTAINER_NAME" 2>&1 | grep -qi "error"; then
    echo "⚠ Warnings or errors found in logs"
else
    echo "  No errors in logs"
fi

# Test 5: Health check passes
echo "Test 5: Health check..."
sleep 5
health=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "none")
if [ "$health" = "healthy" ] || [ "$health" = "none" ]; then
    echo "  Health status: $health"
else
    echo "✗ Unexpected health status: $health"
    exit 1
fi

# Test 6: Graceful shutdown
echo "Test 6: Graceful shutdown..."
docker stop "$CONTAINER_NAME"

# Test 7: Read-only filesystem compatibility
echo "Test 7: Read-only filesystem..."
docker run -d --name "${CONTAINER_NAME}-ro" --read-only \
    --tmpfs /var/cache/nginx:uid=101,gid=101 \
    --tmpfs /var/run:uid=101,gid=101 \
    -p 8081:80 "$IMAGE"
sleep 3

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081)
if [ "$response" != "200" ]; then
    echo "✗ Read-only test failed with HTTP $response"
    docker rm -f "${CONTAINER_NAME}-ro"
    exit 1
fi

docker rm -f "${CONTAINER_NAME}-ro"

echo "✓ All integration tests passed"
