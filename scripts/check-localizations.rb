#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

ROOT = File.expand_path("..", __dir__)
REQUIRED_LANGUAGES = ["ko", "en", "ja", "zh-Hans"].freeze
CATALOGS = [
  "hyuabot/Localization/Localizable.xcstrings",
  "hyuabot/Localization/InfoPlist.xcstrings",
  "widget/Localizable.xcstrings",
  "widget/InfoPlist.xcstrings",
  "watch/Localization/InfoPlist.xcstrings"
].freeze

failures = []

CATALOGS.each do |relative_path|
  path = File.join(ROOT, relative_path)
  next unless File.exist?(path)

  catalog = JSON.parse(File.read(path))
  strings = catalog.fetch("strings", {})
  strings.each do |key, value|
    next if value["shouldTranslate"] == false
    next unless value["extractionState"] == "manual"

    localizations = value["localizations"]
    next unless localizations

    REQUIRED_LANGUAGES.each do |language|
      failures << "#{relative_path}: #{key.inspect} missing #{language}" unless localizations.key?(language)
    end
  end
end

if failures.empty?
  puts "Localization catalogs contain required languages."
else
  warn failures.join("\n")
  exit 1
end
