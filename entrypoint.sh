#!/usr/bin/env bash

rsync -av --ignore-existing /home_init/user/ "$HOME/"
touch "$HOME/.initialized"

exec "$@"
