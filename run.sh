#!/bin/bash
# Run Flow locally
# Usage: ./run.sh [additional flutter run args]
#
# Setup:
#   1. Copy .env.example to .env:  cp .env.example .env
#   2. Fill in your Firebase values in .env
#   3. Run:  ./run.sh
#      or:   ./run.sh -d chrome
#      or:   ./run.sh -d linux
#
# .env is gitignored — your keys stay local and safe.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌  .env file not found!"
  echo ""
  echo "   Setup:"
  echo "   1. cp .env.example .env"
  echo "   2. Fill in your Firebase values in .env"
  echo "   3. Run: ./run.sh"
  echo ""
  exit 1
fi

echo "✅  Loading keys from .env"
flutter run --dart-define-from-file="$ENV_FILE" "$@"
