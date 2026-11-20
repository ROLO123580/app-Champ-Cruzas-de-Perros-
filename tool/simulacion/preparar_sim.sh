#!/usr/bin/env bash
# Prepara el entorno SEÑUELO de Champ en un proyecto Firebase separado.
# Uso: bash tool/simulacion/preparar_sim.sh <id-proyecto-señuelo>
set -euo pipefail
proyecto="${1:-}"
if [[ -z "$proyecto" ]]; then
  echo "Uso: bash tool/simulacion/preparar_sim.sh <id-proyecto-señuelo>" >&2; exit 64
fi
if [[ "$proyecto" == "champ-dog-app" ]]; then
  echo "ALTO: champ-dog-app es el proyecto real. Usa un proyecto separado." >&2; exit 2
fi
cd "$(dirname -- "${BASH_SOURCE[0]}")/../.."
destino="$HOME/.config/Champ/firebase.sim.json"
mkdir -p "$(dirname "$destino")"

echo "1/3 Leyendo la configuración web de $proyecto..."
npx --yes firebase-tools apps:sdkconfig WEB --project "$proyecto" --json > /tmp/champ_sim_sdk.json
node -e '
const r = JSON.parse(require("fs").readFileSync("/tmp/champ_sim_sdk.json", "utf8"));
let c = r.result?.sdkConfig;
if (!c && r.result?.fileContents) { try { c = JSON.parse(r.result.fileContents); } catch { const m = r.result.fileContents.match(/\{[\s\S]*\}/); if (m) c = Function("return " + m[0])(); } }
c = c ?? r.result;
if (!c?.apiKey) { console.error("No hay una app web registrada en el proyecto."); process.exit(1); }
const salida = { FIREBASE_API_KEY: c.apiKey, FIREBASE_APP_ID: c.appId,
  FIREBASE_MESSAGING_SENDER_ID: c.messagingSenderId, FIREBASE_PROJECT_ID: c.projectId,
  FIREBASE_AUTH_DOMAIN: c.authDomain, FIREBASE_STORAGE_BUCKET: c.storageBucket ?? "" };
require("fs").writeFileSync(process.argv[1], JSON.stringify(salida, null, 2) + "\n");
console.log("   Guardada en " + process.argv[1] + " (largo de la key: " + c.apiKey.length + ")");
' "$destino"
rm -f /tmp/champ_sim_sdk.json

echo "2/3 Publicando las reglas de Firestore en $proyecto..."
npx --yes firebase-tools deploy --only firestore:rules --project "$proyecto"

echo "3/3 Creando usuarios y datos simulados..."
CHAMP_SIM_REGISTRO="$HOME/.config/Champ/simulacion_cuentas.json" \
  node tool/simulacion/sembrar_simulacion.mjs --config "$destino"
echo
echo "Listo. Abre Champ en el entorno simulado con: bash tool/simulacion/champ_sim.sh"
