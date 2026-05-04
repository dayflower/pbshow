#!/usr/bin/env bash
set -euo pipefail

if ! command -v swift-format >/dev/null 2>&1; then
  echo "error: swift-format is not installed. Install with: brew install swift-format" >&2
  exit 1
fi

swift-format lint --recursive Sources Tests
