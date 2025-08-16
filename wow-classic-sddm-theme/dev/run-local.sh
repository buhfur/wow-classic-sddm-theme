#!/usr/bin/env bash
set -euo pipefail
THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GREETER="$(command -v sddm-greeter || true)"
[[ -z "$GREETER" ]] && GREETER=/usr/lib/sddm/sddm-greeter
export QML2_IMPORT_PATH="${QML2_IMPORT_PATH:-/usr/share/sddm/imports:/usr/lib/qt/qml:/usr/lib64/qt5/qml:/usr/lib/x86_64-linux-gnu/qt5/qml}"
sudo -E "$GREETER" --test-mode --theme "$THEME_DIR"
