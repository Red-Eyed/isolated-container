#!/usr/bin/env bash
# entrypoint.sh — runs as the container user before handing off to CMD.
#
# On first run the bind-mounted home directory is empty (or missing dotfiles).
# This script seeds any missing skeleton files so tools like bash, pip, and
# npm find a properly initialised home without requiring manual setup.

set -euo pipefail

SKEL=/etc/skel

# Only seed when the directory exists and contains files.
if [ -d "$SKEL" ] && [ -n "$(ls -A "$SKEL" 2>/dev/null)" ]; then
    # cp -rn: recursive, no-clobber — never overwrites files the user has
    # already customised in a subsequent run.
    cp -rn "${SKEL}/." "${HOME}/"
fi

exec "$@"
