#!/bin/bash
# Run Flow locally
# Usage: ./run.sh [additional flutter run args]
#
# First time setup:
#   Option A (recommended): Just edit lib/firebase_config.dart with your Firebase values
#     then: git update-index --skip-worktree lib/firebase_config.dart
#     then: flutter run -d chrome  (or just ./run.sh)
#
#   Option B: Create firebase_config.json from firebase_config.example.json
#     and fill in values, then use --dart-define-from-file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/firebase_config.json"

if [ -f "$CONFIG_FILE" ]; then
  flutter run --dart-define-from-file="$CONFIG_FILE" "$@"
else
  flutter run "$@"
fi
