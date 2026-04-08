# Justfile for isolated-container
# Usage: just <command>

# Build the image
build:
    #!/usr/bin/env bash
    HOST_UID=$(id -u) HOST_GID=$(id -g) podman-compose build

# Start the container
up:
    #!/usr/bin/env bash
    HOST_UID=$(id -u) HOST_GID=$(id -g) podman-compose up

# Stop the container
down:
    podman-compose down

# Drop into the container shell
shell:
    podman-compose exec agent /bin/bash --login

# Reset persistent state (agent_home/ and share/)
clean:
    rm -rf agent_home share
    @echo "Cleaned agent_home/ and share/"
