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
require "uri"

source_path, output_path, repo_root = ARGV
violations = JSON.parse(File.read(source_path))

violations.each do |entry|
  location = entry.dig("violation", "location")
  next unless location

  file_uri = location["file"]
  next unless file_uri

  path = URI(file_uri).path
  relative_path = path.split("/hyuabot-client-ios/", 2).last
  next unless relative_path

  location["file"] = "file://#{File.join(repo_root, relative_path)}"
end

File.write(output_path, JSON.generate(violations))
RUBY

swiftlint lint --strict --config "$repo_root/.swiftlint.yml" --baseline "$temporary_baseline"
