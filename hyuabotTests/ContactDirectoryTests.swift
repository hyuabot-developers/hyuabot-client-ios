//
//  ContactDirectoryTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class ContactDirectoryTests: XCTestCase {
    private let entries = [
        ContactEntry(id: 4, department: "학사팀", name: "수업수강신청", phoneNumber: "031-400-4214"),
        ContactEntry(id: 2, department: "정보팀", name: "LMS(학습관리시스템)", phoneNumber: "031-400-4200"),
        ContactEntry(id: 1, department: "학사팀", name: "성적관리", phoneNumber: "031-400-4100"),
        ContactEntry(id: 3, department: "학생팀", name: "학생지원", phoneNumber: "031-400-4300"),
        ContactEntry(id: 5, department: "학생팀", name: "장학안내", phoneNumber: "031-400-4400"),
        ContactEntry(id: 6, department: "정보팀", name: "전산지원", phoneNumber: "031-400-4500"),
    ]

    func testSortedByPhoneUsesIDForTies() {
        let tied = [
            ContactEntry(id: 2, department: "A", name: "two", phoneNumber: "100"),
            ContactEntry(id: 1, department: "A", name: "one", phoneNumber: "100"),
        ]
        XCTAssertEqual(ContactDirectory.sortedByPhone(tied).map(\.id), [1, 2])
    }

    func testDepartmentsFollowPhoneOrderWithoutDuplicates() {
        XCTAssertEqual(ContactDirectory.departments(in: entries), ["학사팀", "정보팀", "학생팀"])
    }

    func testMatchingQueries() {
        let entry = entries[0]
        XCTAssertTrue(ContactDirectory.matches(entry, query: "  \n"))
        XCTAssertTrue(entries.allSatisfy { ContactDirectory.matches($0, query: " ") })
        XCTAssertTrue(ContactDirectory.matches(entry, query: "수강"))
        XCTAssertTrue(ContactDirectory.matches(entry, query: "학사팀"))
        XCTAssertTrue(ContactDirectory.matches(entry, query: "학사팀 수업"))
        XCTAssertTrue(ContactDirectory.matches(entry, query: "4214"))
        XCTAssertTrue(ContactDirectory.matches(entry, query: "4004214"))
        XCTAssertTrue(ContactDirectory.matches(entries[1], query: "lms"))
    }

    func testDepartmentFilterCombinesWithQuery() {
        let result = ContactDirectory.filter(entries, query: "수업", department: "학사팀")
        XCTAssertEqual(result.map(\.name), ["수업수강신청"])
        XCTAssertEqual(ContactDirectory.filter(entries, query: "수업", department: "정보팀").count, 0)
    }

    func testSectionsPreserveFirstAppearanceAndEntryOrder() {
        let sections = ContactDirectory.sections(for: [entries[0], entries[1], entries[2], entries[3]])
        XCTAssertEqual(sections.map(\.department), ["학사팀", "정보팀", "학생팀"])
        XCTAssertEqual(sections.map { $0.entries.count }, [2, 1, 1])
        XCTAssertEqual(sections[0].entries.map(\.id), [4, 1])
    }

    func testHighlightRanges() {
        XCTAssertEqual(ContactDirectory.highlightRange(of: "수업", in: "수업수강신청"), NSRange(location: 0, length: 2))
        XCTAssertEqual(ContactDirectory.highlightRange(of: "4214", in: "031-400-4214"), NSRange(location: 8, length: 4))
        XCTAssertNil(ContactDirectory.highlightRange(of: " ", in: "text"))
        XCTAssertNil(ContactDirectory.highlightRange(of: "missing", in: "text"))
    }

    func testPhoneHighlightRanges() {
        XCTAssertEqual(ContactDirectory.phoneHighlightRange(of: "4004214", in: "031-400-4214"), NSRange(location: 4, length: 8))
        XCTAssertEqual(ContactDirectory.phoneHighlightRange(of: "4214", in: "031-400-4214"), NSRange(location: 8, length: 4))
        XCTAssertEqual(ContactDirectory.phoneHighlightRange(of: "400", in: "031-400-4214"), NSRange(location: 4, length: 3))
        XCTAssertNil(ContactDirectory.phoneHighlightRange(of: "9999", in: "031-400-4214"))
        XCTAssertNil(ContactDirectory.phoneHighlightRange(of: "abc", in: "031-400-4214"))
        XCTAssertNil(ContactDirectory.phoneHighlightRange(of: "", in: "031-400-4214"))
    }
}
