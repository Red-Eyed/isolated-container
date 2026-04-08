FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=user
ARG UID=1000
ARG GID=1000

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # VCS & network
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    openssh-client \
    # Build toolchain
    build-essential \
    pkg-config \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # Node / npm  (24.04 ships Node 18)
    nodejs \
    npm \
    # Rust toolchain (stable from Ubuntu repos)
    cargo \
    rustc \
    # Shell utilities
    bash \
    jq \
    unzip \
    zip \
    ripgrep \
    fd-find \
    less \
    vim-tiny \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user that matches the intended UID/GID
RUN groupadd --gid "${GID}" "${USERNAME}" \
    && useradd \
        --uid "${UID}" \
        --gid "${GID}" \
        --shell /bin/bash \
        --create-home \
        "${USERNAME}"

# The home directory will be bind-mounted at runtime, so /etc/skel stays
# intact inside the image for the entrypoint to seed from on first run.

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

# /share is the file-exchange directory; create it so the bind-mount has a
# known mountpoint even if the user forgets to pre-create the host directory.
RUN mkdir -p /share && chown "${UID}:${GID}" /share

USER "${USERNAME}"
WORKDIR "/home/${USERNAME}"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash", "--login"]
