//
//  OpenSourceLicenseCatalog.swift
//  hyuabot
//

import Foundation

struct OpenSourceLicenseEntry: Decodable, Equatable {
    let name: String
    let version: String
    let source: String
    let licenseText: String
}

enum OpenSourceLicenseKind: CaseIterable, Equatable {
    case apache2
    case mit
    case bsd3Clause
    case zlib
    case other

    var groupTitle: String {
        switch self {
        case .apache2: "Apache 2.0"
        case .mit: "MIT"
        case .bsd3Clause: "BSD 3-Clause"
        case .zlib: "zlib"
        case .other: String(localized: "licenses.group.other")
        }
    }

    var badgeTitle: String {
        switch self {
        case .apache2: "Apache License 2.0"
        case .mit: "MIT License"
        case .bsd3Clause: "BSD 3-Clause License"
        case .zlib: "zlib License"
        case .other: String(localized: "licenses.group.other")
        }
    }

    static func classify(_ licenseText: String) -> OpenSourceLicenseKind {
        let markers: [(OpenSourceLicenseKind, String)] = [
            (.apache2, "Apache License"),
            (.mit, "Permission is hereby granted"),
            (.bsd3Clause, "Redistribution and use in source and binary forms"),
            (.zlib, "This software is provided 'as-is'")
        ]
        let firstMatch = markers.compactMap { kind, marker in
            licenseText.range(of: marker).map { (kind, $0.lowerBound) }
        }.min { $0.1 < $1.1 }
        return firstMatch?.0 ?? .other
    }
}

struct OpenSourceLicenseGroup: Equatable {
    let kind: OpenSourceLicenseKind
    let licenses: [OpenSourceLicenseEntry]
}

enum OpenSourceLicenseCatalog {
    static func load(bundle: Bundle = .main) -> [OpenSourceLicenseEntry] {
        guard let url = bundle.url(forResource: "OpenSourceLicenses", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let licenses = try? PropertyListDecoder().decode([OpenSourceLicenseEntry].self, from: data)
        else { return [] }

        return licenses.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func filter(_ licenses: [OpenSourceLicenseEntry], query: String) -> [OpenSourceLicenseEntry] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return licenses }
        return licenses.filter { $0.name.localizedCaseInsensitiveContains(trimmedQuery) }
    }

    static func groups(for licenses: [OpenSourceLicenseEntry]) -> [OpenSourceLicenseGroup] {
        OpenSourceLicenseKind.allCases.compactMap { kind in
            let matching = licenses.filter { OpenSourceLicenseKind.classify($0.licenseText) == kind }
            return matching.isEmpty ? nil : OpenSourceLicenseGroup(kind: kind, licenses: matching)
        }
    }

    static func displaySource(_ source: String) -> String {
        var display = source
        if display.hasPrefix("https://") {
            display.removeFirst("https://".count)
        } else if display.hasPrefix("http://") {
            display.removeFirst("http://".count)
        }
        if display.hasSuffix("/") { display.removeLast() }
        if display.hasSuffix(".git") { display.removeLast(".git".count) }
        return display
    }
}
