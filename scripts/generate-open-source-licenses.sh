#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
RESOLVED_PATH="$PROJECT_ROOT/hyuabot.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
PACKAGE_SOURCES_PATH="${1:-$PROJECT_ROOT/.derivedData/SourcePackages/checkouts}"
OUTPUT_PATH="$PROJECT_ROOT/hyuabot/Resources/OpenSourceLicenses.plist"
TEMP_DIRECTORY="$(mktemp -d)"

cleanup() {
    rm -rf "$TEMP_DIRECTORY"
}
trap cleanup EXIT

if [[ ! -f "$RESOLVED_PATH" ]]; then
    print -u2 "Package.resolved not found: $RESOLVED_PATH"
    exit 1
fi

if [[ ! -d "$PACKAGE_SOURCES_PATH" ]]; then
    print -u2 "Swift package sources not found: $PACKAGE_SOURCES_PATH"
    print -u2 "Resolve packages first, or pass the SourcePackages/checkouts directory as the first argument."
    exit 1
fi

mkdir -p "${OUTPUT_PATH:h}"
print '[]' > "$TEMP_DIRECTORY/licenses.json"

display_name() {
    case "$1" in
        abseil-cpp-binary) print "Abseil C++" ;;
        apollo-ios) print "Apollo iOS" ;;
        app-check) print "Google App Check" ;;
        firebase-ios-sdk) print "Firebase iOS SDK" ;;
        google-ads-on-device-conversion-ios-sdk) print "Google Ads On-Device Conversion SDK" ;;
        googleappmeasurement) print "Google App Measurement" ;;
        googledatatransport) print "Google Data Transport" ;;
        googleutilities) print "Google Utilities" ;;
        grpc-binary) print "gRPC" ;;
        gtm-session-fetcher) print "GTMSessionFetcher" ;;
        interop-ios-for-google-sdks) print "Google SDK Interop" ;;
        leveldb) print "LevelDB" ;;
        nanopb) print "nanopb" ;;
        promises) print "Promises" ;;
        realm-core) print "Realm Core" ;;
        realm-swift) print "Realm Swift" ;;
        rxswift) print "RxSwift" ;;
        snapkit) print "SnapKit" ;;
        then) print "Then" ;;
        *) print "$1" ;;
    esac
}

jq -r '.pins[] | [.identity, (.state.version // .state.revision), .location] | @tsv' "$RESOLVED_PATH" |
while IFS=$'\t' read -r identity version source; do
    case "$identity" in
        swift-custom-dump|swift-snapshot-testing|swift-syntax|xctest-dynamic-overlay)
            continue
            ;;
    esac

    package_path="$PACKAGE_SOURCES_PATH/$identity"
    license_path="$(find "$package_path" -maxdepth 2 -type f \( -iname 'LICENSE' -o -iname 'LICENSE.*' -o -iname 'COPYING' -o -iname 'NOTICE' \) | head -1)"
    if [[ -z "$license_path" ]]; then
        print -u2 "License file not found for $identity in $package_path"
        exit 1
    fi

    normalized_license_path="$TEMP_DIRECTORY/$identity-license.txt"
    sed 's/[[:space:]]*$//' "$license_path" > "$normalized_license_path"

    next_json="$TEMP_DIRECTORY/$identity.json"
    jq \
        --arg name "$(display_name "$identity")" \
        --arg version "$version" \
        --arg source "$source" \
        --rawfile licenseText "$normalized_license_path" \
        '. + [{name: $name, version: $version, source: $source, licenseText: $licenseText}]' \
        "$TEMP_DIRECTORY/licenses.json" > "$next_json"
    mv "$next_json" "$TEMP_DIRECTORY/licenses.json"
done

plutil -convert xml1 -o "$OUTPUT_PATH" "$TEMP_DIRECTORY/licenses.json"
print "Generated $OUTPUT_PATH"
