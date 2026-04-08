# Justfile for isolated-container
# Usage: just <command>

# Build the image
build:
    uv tool install podman-compose
    HOST_UID=$(id -u) HOST_GID=$(id -g) podman compose build

# Start the container as a daemon
up:
    HOST_UID=$(id -u) HOST_GID=$(id -g) podman compose up -d

# Stop the container
down:
    podman compose down

# Drop into the running container's shell (waits for first-run init to finish)
shell:
    podman compose exec agent /bin/zsh --login

# Reset persistent state (agent_home/ and share/)
clean:
    rm -rf agent_home share
    @echo "Cleaned agent_home/ and share/"
