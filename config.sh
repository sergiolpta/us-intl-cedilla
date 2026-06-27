#!/usr/bin/env bash

readonly PROJECT_NAME="us-intl-cedilla"

readonly PROJECT_ROOT="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" &&
    pwd
)"

readonly XKB_PACKAGE="xkb-data"
readonly XKB_SYMBOLS_FILE="/usr/share/X11/xkb/symbols/us"

readonly PATCH_FILE="$PROJECT_ROOT/patches/us-intl-cedilla.patch"
readonly BACKUP_DIR="/var/backups/$PROJECT_NAME"
readonly STATE_DIR="/var/lib/$PROJECT_NAME"

readonly XKB_LAYOUT="us"
readonly XKB_VARIANT="intl"

readonly SUPPORTED_DISTROS=(
    "debian"
    "ubuntu"
    "linuxmint"
    "pop"
)
