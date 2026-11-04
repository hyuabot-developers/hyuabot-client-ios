//
//  CafeteriaWidgetComponents.swift
//  hyuabot
//

import AppIntents
import SwiftUI
import WidgetKit

struct CafeteriaStatusLabel: View {
    let status: CafeteriaRunningStatus
    let style: CafeteriaStatusStyle

    private var isOpen: Bool {
        if case .open = status { return true }
        return false
    }

    private var color: Color {
        switch status {
        case .open: HYUWidgetColor.open
        case .closingSoon: HYUWidgetColor.imminent
        case .upcoming, .closed, .unknown: HYUWidgetColor.muted
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(verbatim: CafeteriaPresentation.label(for: status, style: style))
                .font(.godo(size: 10, weight: .semibold)).lineLimit(1)
                .foregroundStyle(isOpen ? HYUWidgetColor.ink2 : color)
        }
        .fixedSize()
    }
}

struct CafeteriaMenuLine: View {
    let row: CafeteriaMenuRow
    let size: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(row.food).font(.godo(size: size, weight: .regular))
                .foregroundStyle(HYUWidgetColor.ink2).lineLimit(1)
            Spacer(minLength: 8)
            if !row.price.isEmpty {
                Text(verbatim: CafeteriaPresentation.formattedPrice(row.price))
                    .font(.godo(size: size, weight: .semibold)).foregroundStyle(HYUWidgetColor.price)
                    .monospacedDigit().fixedSize()
            }
        }
        .frame(height: CafeteriaLayoutMetrics.menuRowHeight)
    }
}

struct CafeteriaBlock: View {
    let item: CafeteriaMenuItem
    var status: CafeteriaRunningStatus?
    var style: CafeteriaStatusStyle = .full
    let nameSize: CGFloat
    let menuSize: CGFloat
    var maxMenus: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: CafeteriaLayoutMetrics.menuSpacing) {
            HStack(spacing: 6) {
                Text(item.cafeteriaName).font(.godo(size: nameSize, weight: .bold)).lineLimit(1)
                Spacer(minLength: 4)
                if let status {
                    CafeteriaStatusLabel(status: status, style: style)
                }
            }
            .frame(height: CafeteriaLayoutMetrics.nameRowHeight)
            ForEach(Array(item.menus.prefix(maxMenus ?? item.menus.count))) { menu in
                CafeteriaMenuLine(row: menu, size: menuSize)
            }
        }
    }
}

struct MealStripView: View {
    let meal: MealType
    private let labels = [String(localized: "meal.breakfast"), String(localized: "meal.lunch"), String(localized: "meal.dinner")]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(zip(CafeteriaPresentation.mealSegments(for: meal), labels).enumerated()), id: \.offset) { _, pair in
                let (segment, label) = pair
                VStack(alignment: .leading, spacing: 3) {
                    Capsule().fill(color(for: segment)).frame(height: 4)
                    Text(label).font(.godo(size: 10, weight: segment == .current ? .bold : .regular))
                        .foregroundStyle(segment == .current ? HYUWidgetColor.brand : HYUWidgetColor.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func color(for segment: MealSegmentState) -> Color {
        switch segment {
        case .done: HYUWidgetColor.muted.opacity(0.45)
        case .current: HYUWidgetColor.brand
        case .upcoming: HYUWidgetColor.separator
        }
    }
}

struct CafeteriaHeader: View {
    let entry: CafeteriaEntry
    let titleSize: CGFloat
    var dateSize: CGFloat = 12
    var dateStyle: Date.FormatStyle.Symbol.Weekday?
    var showsTime = true

    var body: some View {
        HStack(spacing: 6) {
            Text(verbatim: title).font(.godo(size: titleSize, weight: .bold)).foregroundStyle(HYUWidgetColor.brand)
            if let dateStyle {
                Text(entry.menuDate, format: .dateTime.month().day().weekday(dateStyle))
                    .font(.godo(size: dateSize, weight: .regular)).foregroundStyle(HYUWidgetColor.muted).lineLimit(1)
            }
            Spacer(minLength: 4)
            WidgetRefreshStamp(date: showsTime ? entry.date : nil, intent: RefreshCafeteriaIntent())
        }
        .frame(minHeight: HYUWidgetMetrics.headerMinHeight)
    }

    private var title: String {
        entry.isNextDay ? String(localized: "meal.tomorrow.breakfast") : entry.mealType.title
    }
}
