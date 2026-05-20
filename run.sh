#!/bin/bash
# Run the app locally with Firebase config from firebase_config.json
# Usage: ./run.sh [additional flutter run args]
# 
# First time setup:
#   1. Copy firebase_config.example.json to firebase_config.json
#   2. Fill in your Firebase project values from Firebase Console
#   3. Run ./run.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/firebase_config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: firebase_config.json not found."
  echo "Copy firebase_config.example.json to firebase_config.json and fill in your values."
  exit 1
fi

flutter run --dart-define-from-file="$CONFIG_FILE" "$@"
