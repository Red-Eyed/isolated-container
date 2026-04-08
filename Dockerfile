FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=user
ARG UID=1000
ARG GID=1000

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    zsh \
    rsync \
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
    # Shell utilities
    bash \
    jq \
    unzip \
    zip \
    ripgrep \
    fd-find \
    less \
    micro \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user that matches the intended UID/GID.
# On macOS the host GID (e.g. 20 = staff) or UID may already exist inside
# the Ubuntu base image, so we skip creation when that is the case.
RUN getent group "${GID}" || groupadd --gid "${GID}" "${USERNAME}"
RUN getent passwd "${UID}" || useradd \
        --uid "${UID}" \
        --gid "${GID}" \
        --shell /bin/zsh \
        --create-home \
        "${USERNAME}"

# Install all other packages (uv, npm etc) into /home/user so they are
USER "${USERNAME}"
RUN cd /home/"${USERNAME}" \
    && git clone https://github.com/Red-Eyed/ConfigFiles \
    && cd ConfigFiles \
    && python3 ./install -s install_oh-my-zsh \
    && python3 ./install -s install_all_no_root

# Copy home
USER root
RUN rsync -av /home/"${USERNAME}" /home_init

# The home directory will be bind-mounted at runtime, so /etc/skel stays
# intact inside the image for the entrypoint to seed from on first run.

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

USER "${USERNAME}"
WORKDIR "/home/${USERNAME}"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
