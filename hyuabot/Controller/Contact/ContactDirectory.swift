//
//  ContactDirectory.swift
//  hyuabot
//

import Foundation

struct ContactEntry: Equatable, Sendable {
    let id: Int
    let department: String
    let name: String
    let phoneNumber: String
}

struct ContactSection: Equatable, Sendable {
    let department: String
    let entries: [ContactEntry]
}

enum ContactDirectory {
    static func split(name: String) -> (department: String?, title: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let separator = trimmedName.firstIndex(of: "-") else {
            return (nil, trimmedName)
        }
        let department = trimmedName[..<separator].trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedName[trimmedName.index(after: separator)...].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !department.isEmpty, !title.isEmpty else {
            return (nil, trimmedName)
        }
        return (department, title)
    }

    static func sortedByPhone(_ entries: [ContactEntry]) -> [ContactEntry] {
        entries.sorted { ($0.phoneNumber, $0.id) < ($1.phoneNumber, $1.id) }
    }

    static func departments(in entries: [ContactEntry]) -> [String] {
        var result: [String] = []
        for entry in sortedByPhone(entries) where !result.contains(entry.department) {
            result.append(entry.department)
        }
        let other = String(localized: "contact.filter.other")
        return result.enumerated().sorted { lhs, rhs in
            let leftRank = departmentRank(lhs.element, other: other)
            let rightRank = departmentRank(rhs.element, other: other)
            return leftRank == rightRank ? lhs.offset < rhs.offset : leftRank < rightRank
        }.map(\.element)
    }

    private static func departmentRank(_ department: String, other: String) -> Int {
        if department == other { return 4 }
        if department.hasSuffix("대학") { return 0 }
        if department.hasSuffix("팀") { return 1 }
        if department.hasSuffix("센터") { return 2 }
        return 3
    }

    static func matches(_ entry: ContactEntry, query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return true }
        let values = [entry.name, entry.department, "\(entry.department) \(entry.name)", entry.phoneNumber]
        if values.contains(where: { $0.range(of: trimmedQuery, options: [.caseInsensitive]) != nil }) {
            return true
        }
        let compact = trimmedQuery.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        guard !compact.isEmpty, compact.allSatisfy({ $0 >= "0" && $0 <= "9" }) else { return false }
        return entry.phoneNumber.replacingOccurrences(of: "-", with: "").contains(compact)
    }

    static func filter(_ entries: [ContactEntry], query: String, department: String?) -> [ContactEntry] {
        sortedByPhone(entries.filter { (department == nil || $0.department == department) && matches($0, query: query) })
    }

    static func sections(for entries: [ContactEntry]) -> [ContactSection] {
        var sections: [ContactSection] = []
        for entry in entries {
            if let index = sections.firstIndex(where: { $0.department == entry.department }) {
                sections[index] = ContactSection(department: sections[index].department, entries: sections[index].entries + [entry])
            } else {
                sections.append(ContactSection(department: entry.department, entries: [entry]))
            }
        }
        let orderedDepartments = departments(in: entries)
        return orderedDepartments.compactMap { department in
            sections.first { $0.department == department }
        }
    }

    static func highlightRange(of query: String, in text: String) -> NSRange? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty, let range = text.range(of: trimmedQuery, options: [.caseInsensitive]) else { return nil }
        return NSRange(range, in: text)
    }

    static func phoneHighlightRange(of query: String, in phoneNumber: String) -> NSRange? {
        if let range = highlightRange(of: query, in: phoneNumber) { return range }
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = trimmedQuery.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        guard !compact.isEmpty, compact.allSatisfy({ $0 >= "0" && $0 <= "9" }) else { return nil }
        let kept = phoneNumber.indices.filter { phoneNumber[$0] != "-" && phoneNumber[$0] != " " }
        let digits = String(kept.map { phoneNumber[$0] })
        guard let match = digits.range(of: compact) else { return nil }
        let startOffset = digits.distance(from: digits.startIndex, to: match.lowerBound)
        let endOffset = digits.distance(from: digits.startIndex, to: match.upperBound) - 1
        let lower = kept[startOffset]
        let upper = phoneNumber.index(after: kept[endOffset])
        return NSRange(lower..<upper, in: phoneNumber)
    }
}
