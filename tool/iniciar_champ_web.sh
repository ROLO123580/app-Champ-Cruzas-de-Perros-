#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
defines_file="${CHAMP_FIREBASE_DEFINES:-${HOME}/.config/Champ/firebase.web.json}"
if [[ ! -f "$defines_file" ]]; then
  echo "Falta la configuración real de Firebase: $defines_file" >&2
  exit 1
fi
cd "$project_dir"
exec flutter run -d web-server --web-hostname 127.0.0.1 --web-port "${CHAMP_WEB_PORT:-8793}" --dart-define-from-file="$defines_file"
