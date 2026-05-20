#!/bin/bash
# Run Flow locally
# Usage: ./run.sh [additional flutter run args]
#
# First time setup:
#   1. Edit lib/firebase_config.dart with your Firebase Console values (Android only)
#   2. Run: git update-index --skip-worktree lib/firebase_config.dart
#   3. Run ./run.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/firebase_config.json"

if [ -f "$CONFIG_FILE" ]; then
  flutter run --dart-define-from-file="$CONFIG_FILE" "$@"
else
  flutter run "$@"
fi
