#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

mkdir -p ~/.config/systemd/user
SCRIPT_DIR="${SCRIPT_DIR}" \
envsubst '${SCRIPT_DIR}' <"${SCRIPT_DIR}/pingbot.service" >"${HOME}/.config/systemd/user/pingbot.service"

systemctl --user daemon-reload
systemctl --user enable pingbot.service
systemctl --user start pingbot.service
