#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
xcrun --sdk macosx swiftc -target "$(uname -m)-apple-macos14" -o "$out/widget-logic-check" "$repo_root/widget/ShuttleDepartureMath.swift" "$repo_root/widget/CafeteriaPresentation.swift" "$repo_root/scripts/widget-logic-check/main.swift"
"$out/widget-logic-check"
