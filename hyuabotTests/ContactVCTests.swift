//
//  ContactVCTests.swift
//  hyuabot
//

import UIKit
import XCTest
@testable import hyuabot

@MainActor
final class ContactVCTests: XCTestCase {
    private var navigationController: UINavigationController?

    private let fixture = [
        ContactEntry(id: 1, department: "학사팀", name: "가", phoneNumber: "031-400-4001"),
        ContactEntry(id: 2, department: "학사팀", name: "나", phoneNumber: "031-400-4002"),
        ContactEntry(id: 3, department: "학사팀", name: "다", phoneNumber: "031-400-4003"),
        ContactEntry(id: 4, department: "수업", name: "라", phoneNumber: "031-400-4101"),
        ContactEntry(id: 5, department: "수업", name: "마", phoneNumber: "031-400-4102")
    ]

    private func makeController() -> ContactVC {
        let controller = ContactVC()
        controller.loadsContactsOnLoad = false
        navigationController = UINavigationController(rootViewController: controller)
        controller.loadViewIfNeeded()
        return controller
    }

    private func injectFixture(into controller: ContactVC) {
        controller.allEntries = ContactDirectory.sortedByPhone(fixture)
        controller.applyFilter()
    }

    func testTableIsWiredToController() {
        let controller = makeController()

        XCTAssertTrue(controller.tableView.dataSource === controller)
        XCTAssertTrue(controller.tableView.delegate === controller)
    }

    func testSectionsAndRowsFromInjectedEntries() {
        let controller = makeController()
        injectFixture(into: controller)

        XCTAssertEqual(controller.tableView.numberOfSections, 2)
        XCTAssertEqual(controller.tableView(controller.tableView, numberOfRowsInSection: 0), 3)
        XCTAssertEqual(controller.tableView(controller.tableView, numberOfRowsInSection: 1), 2)
        XCTAssertEqual(controller.sections.map(\.department), ["학사팀", "수업"])

        let cell = controller.tableView(
            controller.tableView,
            cellForRowAt: IndexPath(row: 0, section: 0)
        )
        XCTAssertTrue(cell is ContactSearchResultCellView)
        XCTAssertNotNil(controller.tableView(controller.tableView, viewForHeaderInSection: 0))
    }

    func testDepartmentOrderingUsesSuffixGroupsAndPreservesPhoneOrder() {
        let other = String(localized: "contact.filter.other")
        let entries = [
            ContactEntry(id: 1, department: "상담센터", name: "가", phoneNumber: "010-0006"),
            ContactEntry(id: 2, department: "기타부서", name: "나", phoneNumber: "010-0005"),
            ContactEntry(id: 3, department: other, name: "다", phoneNumber: "010-0007"),
            ContactEntry(id: 4, department: "공학대학", name: "라", phoneNumber: "010-0002"),
            ContactEntry(id: 5, department: "학생팀", name: "마", phoneNumber: "010-0004"),
            ContactEntry(id: 6, department: "인문대학", name: "바", phoneNumber: "010-0001"),
            ContactEntry(id: 7, department: "자연대학", name: "사", phoneNumber: "010-0003")
        ]
        let expected = ["인문대학", "공학대학", "자연대학", "학생팀", "상담센터", "기타부서", other]

        XCTAssertEqual(ContactDirectory.departments(in: entries), expected)
        XCTAssertEqual(ContactDirectory.sections(for: entries).map(\.department), expected)
    }

    func testQueryWithoutMatchesShowsEmptyCell() {
        let controller = makeController()
        injectFixture(into: controller)
        controller.query = "없는검색어"
        controller.applyFilter()

        XCTAssertEqual(controller.tableView.numberOfSections, 1)
        XCTAssertEqual(controller.tableView(controller.tableView, numberOfRowsInSection: 0), 1)
        let cell = controller.tableView(
            controller.tableView,
            cellForRowAt: IndexPath(row: 0, section: 0)
        )
        XCTAssertTrue(cell is ContactSearchEmptyCellView)
        XCTAssertNil(controller.tableView(controller.tableView, viewForHeaderInSection: 0))
    }

    func testDepartmentFilterAndReset() {
        let controller = makeController()
        injectFixture(into: controller)
        controller.selectedDepartment = "수업"
        controller.applyFilter()

        XCTAssertEqual(controller.tableView.numberOfSections, 1)
        XCTAssertEqual(controller.tableView(controller.tableView, numberOfRowsInSection: 0), 2)
        controller.resetSearch()
        XCTAssertEqual(controller.tableView.numberOfSections, 2)
    }

    func testDashlessPhoneQueryFindsEntry() {
        let controller = makeController()
        injectFixture(into: controller)
        controller.query = "0314004101"
        controller.applyFilter()

        XCTAssertEqual(controller.tableView.numberOfSections, 1)
        XCTAssertEqual(controller.tableView(controller.tableView, numberOfRowsInSection: 0), 1)
    }
}
