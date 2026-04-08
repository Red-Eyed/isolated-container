# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A rootless-Podman-first container setup for running AI coding agents in a secure, isolated environment with zero-friction persistence. The key design decision: `./agent_home` on the host is bind-mounted to `/home/user` inside the container, so every user-level tool (npm, pip, cargo, uv, go, etc.) persists automatically without any extra volume config.

## Commands

```bash
just build   # Build image — passes host UID/GID as build args (required for bind-mount ownership)
just up      # Start container as daemon
just shell   # Attach zsh to running container
just down    # Stop container
just clean   # Delete agent_home/ (full state reset)
```

Always use `just` rather than calling `podman compose` directly — the justfile injects `HOST_UID`/`HOST_GID` which `compose.yml` reads as build args. `build` also ensures `podman-compose` is installed via `uv` first.

## Architecture

### UID/GID flow (critical to understand)

`compose.yml` uses `userns_mode: keep-id` (rootless Podman) so the host user's UID maps unchanged into the container. The Dockerfile bakes that same UID/GID into the image user via build args. Without this alignment, bind-mounted files appear as wrong-owner inside the container.

On macOS the host GID is often `20` (staff), which already exists in Ubuntu's `/etc/group`. The Dockerfile handles this with `getent group "${GID}" || groupadd ...` — skipping creation if the GID is already taken.

### Home seeding (entrypoint.sh)

The Dockerfile snapshots `/home/user` into `/home_init/user` at build time (after running the ConfigFiles installer). On every container start, `entrypoint.sh` rsyncs `/home_init/user/` → `$HOME/` with `--ignore-existing`, then `exec`s the CMD. The `--ignore-existing` flag ensures host edits to `agent_home/` are never overwritten.

### Read-only root filesystem

`compose.yml` sets `read_only: true`. The only writable locations at runtime are:
- `/home/user` — bind-mount from `./agent_home`
- `/tmp`, `/var/tmp`, `/run` — tmpfs

Any tool that writes outside these paths will fail with a permission error. Add a tmpfs entry in `compose.yml` or redirect state to `$HOME`.

### ConfigFiles install

The Dockerfile installs dotfiles and user-level tools (oh-my-zsh, uv, Go, Node) from `github.com/Red-Eyed/ConfigFiles` as the non-root user so `$HOME` resolves to `/home/user`. This runs before the `rsync → /home_init` snapshot. The install **must** run as the non-root user — running as root would install to `/root/` and the snapshot would be empty.

## Key files

| File | Role |
|------|------|
| `Dockerfile` | apt packages → create user → ConfigFiles install → snapshot home to `/home_init` → copy entrypoint |
| `compose.yml` | Security hardening, bind-mount, `userns_mode: keep-id`, no CMD (passed via compose `command`) |
| `entrypoint.sh` | Seeds home from `/home_init/user/` on every start (`--ignore-existing`), then `exec "$@"` |
| `justfile` | Wraps compose commands with `HOST_UID`/`HOST_GID` injection |

## Adding things

- **System package**: add to `apt-get install` in `Dockerfile`, then `just build`
- **User-level tool**: install inside the container; persists in `agent_home/` automatically
- **Linux capability**: add to `cap_add` in `compose.yml` (default is `cap_drop: ALL`)
- **Exposed port**: uncomment the `ports:` block in `compose.yml`
- **Docker instead of Podman**: remove `userns_mode: keep-id` from `compose.yml`
