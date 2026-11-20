#!/usr/bin/env bash
# Abre Champ en Chrome conectada al entorno SEÑUELO (datos ficticios).
set -euo pipefail
config="$HOME/.config/Champ/firebase.sim.json"
if [[ ! -f "$config" ]]; then
  echo "Falta $config. Ejecuta antes: bash tool/simulacion/preparar_sim.sh <proyecto>" >&2; exit 1
fi
if grep -q '"champ-dog-app"' "$config"; then
  echo "ALTO: $config apunta al proyecto real." >&2; exit 2
fi
cd "$(dirname -- "${BASH_SOURCE[0]}")/../.."
echo "Entorno SIMULADO: $(grep -o '"FIREBASE_PROJECT_ID": *"[^"]*"' "$config")"
exec flutter run -d chrome --dart-define-from-file="$config"
