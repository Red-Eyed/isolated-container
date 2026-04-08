# isolated-container

A secure, reproducible container for running AI coding agents (or any
interactive toolchain) with strong isolation and zero-friction persistence.

Works with **Docker Compose** and **rootless Podman Compose** out of the box.

---

## Design overview

### Why the home directory is bind-mounted

Every user-level tool stores state in `$HOME`:

| Tool | What lives in `$HOME` |
|------|----------------------|
| npm  | `~/.npm`, `~/.npmrc` |
| pip  | `~/.local/lib/python*` |
| cargo | `~/.cargo` |
| go   | `~/go` |
| ssh  | `~/.ssh` |
| git  | `~/.gitconfig` |

By bind-mounting `./agent_home` → `/home/user`, **all of that persists
automatically** across container restarts and rebuilds.  You never need to
declare extra named volumes, write cache-warming scripts, or repeat `npm
install -g` after every image change.

### First-run dotfile seeding

On the very first run `./agent_home/` is an empty directory.  The
`entrypoint.sh` copies every file from `/etc/skel` (the image's skeleton
directory) into the home directory using `cp -rn` (no-clobber), so:

- `.bashrc`, `.profile`, and friends are created automatically.
- Subsequent runs never overwrite files you've customised.

### `/share` — file exchange

`./share` on the host maps to `/share` inside the container.  Drop files there
to hand them to the agent, or have the agent write output there to retrieve it
from the host.  It is intentionally separate from home so it can be cleared
independently.

---

## Quick start

```bash
# 1. Clone and enter the repo
git clone https://github.com/<you>/isolated-container
cd isolated-container

# 2. Create the host-side directories (git-ignored)
mkdir -p agent_home share

# 3. Build and start
docker compose up --build        # Docker
# — or —
podman compose up --build        # rootless Podman
```

The container drops you into an interactive bash shell.  Everything you install
or configure inside `~` persists in `./agent_home` on the host.

---

## Adding dependencies

### System dependencies — require a rebuild

System packages (`apt` installs) are baked into the image and must be added to
`Dockerfile`, then rebuilt:

```bash
# Edit Dockerfile, add your package to the apt-get list, then:
docker compose build
docker compose up
```

The rebuild is fast because Docker/Podman caches layers.  Your home directory
is untouched because it lives on the host, not in the image.

### User-level dependencies — just install, they persist automatically

```bash
# Inside the container — installs persist in ./agent_home on the host
npm install -g typescript          # lands in ~/.npm / ~/.local
pip install --user httpx           # lands in ~/.local/lib/python*
cargo install ripgrep              # lands in ~/.cargo/bin
```

No extra steps.  On the next `compose up` everything is already there.

---

## Security model

| Hardening measure | Setting |
|---|---|
| Drop all Linux capabilities | `cap_drop: [ALL]` |
| Read-only root filesystem | `read_only: true` |
| No privilege escalation | `no-new-privileges:true` |
| No host networking | `network_mode: bridge` |
| No privileged mode | (never set) |
| Writable scratch space | tmpfs on `/tmp`, `/var/tmp`, `/run` |
| Non-root user | UID/GID 1000 inside the image |

Ports are not exposed by default.  Uncomment the `ports:` block in
`compose.yml` and map only the specific ports you need.

---

## Rootless Podman notes

`compose.yml` uses `userns_mode: keep-id`, which is the key setting for
rootless Podman.  It maps your host UID/GID to the exact same values inside
the container, so bind-mounted directories (`agent_home`, `share`) are
readable and writable without any `chown` on the host.

The justfile automatically handles UID/GID:

```bash
just build     # Builds with your host UID/GID baked in
just up        # Starts the container
```

The justfile extracts your UID/GID once and passes them as build args, so
subsequent `just up` runs use the cached image.

### Docker users

Remove the `userns_mode: keep-id` line from `compose.yml` before using Docker
— Docker Compose does not support that value.  On Linux also ensure
`./agent_home` is owned by UID 1000 (or rebuild with `--build-arg UID=$(id -u)`).

---

## Repository layout

```
Dockerfile       Image definition (Ubuntu 24.04, system packages, non-root user)
compose.yml      Compose file with security hardening and bind-mounts
entrypoint.sh    Seeds dotfiles from /etc/skel on first run, then execs CMD
.gitignore       Excludes agent_home/ and share/ from version control
README.md        This file
agent_home/      Created locally, git-ignored — the agent's persistent $HOME
share/           Created locally, git-ignored — file exchange drop-zone
```
