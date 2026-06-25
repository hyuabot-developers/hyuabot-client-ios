#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
baseline="$repo_root/.swiftlint_baseline.json"
temporary_baseline="$(mktemp)"

cleanup() {
  rm -f "$temporary_baseline"
}
trap cleanup EXIT

ruby - "$baseline" "$temporary_baseline" "$repo_root" <<'RUBY'
require "json"

source_path, output_path, repo_root = ARGV
baseline = File.read(source_path)
escaped_root = repo_root.gsub("/", "\\/")

baseline = baseline.gsub(%r{file:\\\\/\\\\/\\\\/.*?\\\\/hyuabot-client-ios}, "file:\\/\\/\\/#{escaped_root}")
baseline = baseline.gsub(%r{file:///.*?/hyuabot-client-ios}, "file://#{repo_root}")

File.write(output_path, baseline)
RUBY

swiftlint lint --strict --config "$repo_root/.swiftlint.yml" --baseline "$temporary_baseline"
