FROM debian:bookworm-slim

# Install build dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    libncursesw5-dev \
    libgpm-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Add cross-compilation architectures
RUN dpkg --add-architecture armhf && \
    dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get install -y \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    libncursesw5-dev:armhf \
    libgpm-dev:armhf \
    libtinfo-dev:armhf \
    libncursesw5-dev:arm64 \
    libgpm-dev:arm64 \
    libtinfo-dev:arm64 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash"]

