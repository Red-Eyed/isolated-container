# isolated-container

A secure, reproducible container for running AI coding agents with strong isolation and zero-friction persistence. Designed for rootless Podman.

---

## How it works

The agent's entire home directory (`/home/user`) is bind-mounted to `./agent_home` on the host. Every user-level tool stores state in `$HOME`, so npm, pip, cargo, uv, go, and SSH keys all persist automatically across restarts and rebuilds — no extra volume config needed.

On first run the entrypoint seeds `agent_home/` from a snapshot baked into the image (`/home_init/user/`), using `--ignore-existing` so host edits are never overwritten.

---

## Quick start

```bash
just build   # build image (bakes your UID/GID in)
just up      # start daemon
just shell   # attach zsh
just down    # stop daemon
just clean   # delete agent_home/ (full reset)
```

Requires [just](https://github.com/casey/just) and [podman-compose](https://github.com/containers/podman-compose).

---

## Adding dependencies

**System package** — add to `apt-get install` in `Dockerfile`, then `just build`. Layer cache means rebuilds are fast; `agent_home/` is untouched.

**User-level tool** — install inside the container. It lands in `$HOME` and persists in `agent_home/` automatically.

---

## Security

| Measure | Value |
|---------|-------|
| Capabilities | `cap_drop: ALL` |
| Root filesystem | read-only |
| Privilege escalation | `no-new-privileges:true` |
| Networking | isolated bridge (no host network) |
| User | non-root, UID/GID matched to host |

Writable at runtime: `/home/user` (bind-mount), `/tmp`, `/var/tmp`, `/run` (tmpfs).

Ports are not exposed by default — uncomment `ports:` in `compose.yml` to add them.

---

## Docker users

Remove `userns_mode: keep-id` from `compose.yml` — Docker does not support that value. On Linux ensure `./agent_home` is owned by UID 1000, or rebuild with `--build-arg UID=$(id -u)`.
