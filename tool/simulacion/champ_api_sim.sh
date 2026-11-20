#!/usr/bin/env bash
# API de datos SIMULADA: su propio champ.db, separado del real, en el puerto 8788.
set -euo pipefail
export CHAMP_DATA_DIR="$HOME/.local/share/RHIA/ChampSim"
real="$HOME/.local/share/RHIA/Champ"
if [[ "$(realpath -m "$CHAMP_DATA_DIR")" == "$(realpath -m "$real")" ]]; then
  echo "ALTO: la carpeta simulada coincide con la real." >&2; exit 2
fi
cd "$(dirname -- "${BASH_SOURCE[0]}")/../.."
echo "Entorno SIMULADO: datos en $CHAMP_DATA_DIR"
exec dart run tool/champ_api.dart 8788
