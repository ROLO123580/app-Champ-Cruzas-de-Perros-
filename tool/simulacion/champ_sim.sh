#!/usr/bin/env bash
# Abre Champ en Chrome conectada al entorno SEÑUELO: Firebase champ-sim y la
# API simulada (puerto 8788, SQLite propio). Inicia antes champ_api_sim.sh.
set -euo pipefail
config="$HOME/.config/Champ/firebase.sim.json"
if [[ ! -f "$config" ]]; then
  echo "Falta $config. Ejecuta antes: bash tool/simulacion/preparar_sim.sh <proyecto>" >&2; exit 1
fi
if grep -q '"champ-dog-app"' "$config"; then
  echo "ALTO: $config apunta al proyecto real." >&2; exit 2
fi
if ! curl -s -m 3 http://127.0.0.1:8788/health > /dev/null; then
  echo "La API simulada no responde. En otra terminal: bash tool/simulacion/champ_api_sim.sh" >&2; exit 1
fi
cd "$(dirname -- "${BASH_SOURCE[0]}")/../.."
echo "Entorno SIMULADO: $(grep -o '"FIREBASE_PROJECT_ID": *"[^"]*"' "$config"), API 127.0.0.1:8788"
exec flutter run -d chrome --dart-define-from-file="$config" --dart-define=CHAMP_API_URL=http://127.0.0.1:8788
