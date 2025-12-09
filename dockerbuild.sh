#!/bin/bash

# Script to build the Docker container for nnn cross-compilation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="nnn-builder"
IMAGE_TAG="latest"

echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "This may take a few minutes..."

docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f "${SCRIPT_DIR}/Dockerfile" "${SCRIPT_DIR}"

echo ""
echo "✓ Docker image built successfully!"
echo ""
echo "You can now use this image to build nnn statically for different architectures."
echo "Run: ./build-nnn.sh"

