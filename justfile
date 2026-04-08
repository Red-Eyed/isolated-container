# Justfile for isolated-container
# Usage: just <command>

# Build the image
build:
    uv tool install podman-compose
    HOST_UID=$(id -u) HOST_GID=$(id -g) podman compose build

# Start the container as a daemon and wait until init is complete
up:
    HOST_UID=$(id -u) HOST_GID=$(id -g) podman compose up -d
    until [ -f agent_home/.initialized ]; do echo "wait for initialization" && sleep 1; done


# Stop the container
down:
    podman compose down

# Drop into the running container's shell (waits for first-run init to finish)
shell: up
    podman compose exec agent /bin/zsh --login

# Reset persistent state (agent_home/)
clean:
    rm -rf agent_home
    @echo "Cleaned agent_home/"
