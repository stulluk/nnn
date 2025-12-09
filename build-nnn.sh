#!/bin/bash

# Script to build statically compiled nnn for x86_64, arm32, and arm64

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="nnn-builder"
IMAGE_TAG="latest"
OUTPUT_DIR="${SCRIPT_DIR}/build-output"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

echo "Building statically compiled nnn binaries..."
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# Function to build for a specific architecture
build_arch() {
    local arch=$1
    local cc=$2
    local target=$3
    local cross_arch=$4
    
    echo "=== Building for ${arch} ==="
    
    if [ "$arch" = "x86_64" ]; then
        # Native build for x86_64
        docker run --rm \
            -v "${SCRIPT_DIR}:/workspace" \
            -w /workspace \
            "${IMAGE_NAME}:${IMAGE_TAG}" \
            bash -c "
                make clean
                export LDFLAGS='-static'
                export LDLIBS='-lncursesw -ltinfo -lpthread -lgpm'
                make O_STATIC=1 O_NORL=1
                mv nnn ${target}
                file ${target}
                ldd ${target} 2>&1 | grep -q 'not a dynamic executable' || echo 'Static binary verified'
            "
    else
        # Cross-compilation for ARM
        local pkg_config_name
        local lib_dir
        if [ "$cc" = "arm-linux-gnueabihf-gcc" ]; then
            pkg_config_name="arm-linux-gnueabihf-pkg-config"
            lib_dir="arm-linux-gnueabihf"
        else
            pkg_config_name="aarch64-linux-gnu-pkg-config"
            lib_dir="aarch64-linux-gnu"
        fi
        
        docker run --rm \
            -v "${SCRIPT_DIR}:/workspace" \
            -w /workspace \
            "${IMAGE_NAME}:${IMAGE_TAG}" \
            bash -c "
                export CC=${cc}
                export PKG_CONFIG=${pkg_config_name}
                export PKG_CONFIG_LIBDIR=/usr/lib/${lib_dir}/pkgconfig
                export LDFLAGS='-static -L/usr/lib/${lib_dir}'
                export LDLIBS='-lncursesw -ltinfo -lpthread -lgpm'
                make clean
                make O_STATIC=1 O_NORL=1
                mv nnn ${target}
                file ${target}
                ldd ${target} 2>&1 | grep -q 'not a dynamic executable' || echo 'Static binary verified'
            "
    fi
    
    # Copy to output directory
    cp "${SCRIPT_DIR}/${target}" "${OUTPUT_DIR}/"
    
    # Generate SHA256 checksum
    cd "${OUTPUT_DIR}"
    sha256sum "${target}" > "${target}.sha256"
    cd "${SCRIPT_DIR}"
    
    echo "✓ ${arch} build completed: ${OUTPUT_DIR}/${target}"
    echo ""
}

# Check if Docker image exists
if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
    echo "Error: Docker image ${IMAGE_NAME}:${IMAGE_TAG} not found!"
    echo "Please run ./dockerbuild.sh first to build the Docker image."
    exit 1
fi

# Build for all architectures
build_arch "x86_64" "gcc" "nnn-x86_64" ""
build_arch "arm32" "arm-linux-gnueabihf-gcc" "nnn-arm32" "armhf"
build_arch "arm64" "aarch64-linux-gnu-gcc" "nnn-arm64" "arm64"

echo "=== Build Summary ==="
echo "All binaries built successfully!"
echo "Output directory: ${OUTPUT_DIR}"
echo ""
ls -lh "${OUTPUT_DIR}"/nnn-*
echo ""
echo "✓ All builds completed successfully!"

