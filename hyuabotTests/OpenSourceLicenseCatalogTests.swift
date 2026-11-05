//
//  OpenSourceLicenseCatalogTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class OpenSourceLicenseCatalogTests: XCTestCase {
    func testClassifiesLicenseMarkersAndUnknownText() {
        XCTAssertEqual(OpenSourceLicenseKind.classify("Apache License"), .apache2)
        XCTAssertEqual(OpenSourceLicenseKind.classify("Permission is hereby granted"), .mit)
        XCTAssertEqual(OpenSourceLicenseKind.classify("Redistribution and use in source and binary forms"), .bsd3Clause)
        XCTAssertEqual(OpenSourceLicenseKind.classify("This software is provided 'as-is'"), .zlib)
        XCTAssertEqual(OpenSourceLicenseKind.classify("Unknown license"), .other)
    }

    func testClassificationUsesEarliestMarker() {
        XCTAssertEqual(
            OpenSourceLicenseKind.classify("Permission is hereby granted ... Apache License"),
            .mit
        )
    }

    func testGroupsInKindOrderAndSkipsEmptyKinds() {
        let entries = [entry("zlib", "This software is provided 'as-is'"),
                       entry("MIT", "Permission is hereby granted"),
                       entry("Apache", "Apache License"),
                       entry("MIT second", "Permission is hereby granted")]

        let groups = OpenSourceLicenseCatalog.groups(for: entries)

        XCTAssertEqual(groups.map(\.kind), [.apache2, .mit, .zlib])
        XCTAssertEqual(groups.map { $0.licenses.map(\.name) }, [["Apache"], ["MIT", "MIT second"], ["zlib"]])
    }

    func testDisplaySourceRemovesSchemeGitSuffixAndTrailingSlash() {
        XCTAssertEqual(
            OpenSourceLicenseCatalog.displaySource("https://github.com/SnapKit/SnapKit.git"),
            "github.com/SnapKit/SnapKit"
        )
        XCTAssertEqual(OpenSourceLicenseCatalog.displaySource("http://example.com/project/"), "example.com/project")
        XCTAssertEqual(OpenSourceLicenseCatalog.displaySource("github.com/project"), "github.com/project")
    }

    func testFilterWithEmptyOrWhitespaceQueryReturnsAll() {
        let entries = [entry("One", ""), entry("Two", "")]

        XCTAssertEqual(OpenSourceLicenseCatalog.filter(entries, query: ""), entries)
        XCTAssertEqual(OpenSourceLicenseCatalog.filter(entries, query: "  \n"), entries)
    }

    func testBundledLicensesLoadAndGroup() {
        let licenses = OpenSourceLicenseCatalog.load(bundle: .main)

        XCTAssertFalse(licenses.isEmpty)
        XCTAssertEqual(OpenSourceLicenseCatalog.groups(for: licenses).reduce(0) { $0 + $1.licenses.count }, licenses.count)
        XCTAssertEqual(OpenSourceLicenseCatalog.groups(for: licenses).map { $0.licenses.count }, [13, 4, 1, 1])
    }

    private func entry(_ name: String, _ licenseText: String) -> OpenSourceLicenseEntry {
        OpenSourceLicenseEntry(name: name, version: "1", source: "source", licenseText: licenseText)
    }
}
