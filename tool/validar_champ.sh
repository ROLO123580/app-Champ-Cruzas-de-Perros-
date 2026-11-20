#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
flutter pub get
flutter analyze
flutter test
flutter build web
