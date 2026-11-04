//
//  CafeteriaWidgetViews.swift
//  hyuabot
//

import AppIntents
import SwiftUI
import WidgetKit

struct CafeteriaWidgetView: View {
    let entry: CafeteriaEntry
    @Environment(\.widgetFamily)
    private var family

    private var sorted: [CafeteriaMenuItem] {
        CafeteriaPresentation.sortedForDisplay(entry.items, now: entry.date, isNextDay: entry.isNextDay)
    }

    var body: some View {
        Group {
            if entry.items.isEmpty {
                WidgetStateView(
                    title: entry.isNextDay ? String(localized: "meal.tomorrow.breakfast") : entry.mealType.title,
                    refreshDate: entry.loadFailed ? nil : entry.date,
                    kind: entry.loadFailed ? .error : .empty(message: "cafeteria.no.data"),
                    retryIntent: RefreshCafeteriaIntent()
                )
            } else {
                content
            }
        }
        .padding(HYUWidgetMetrics.contentPadding)
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .systemSmall: CafeteriaSmallView(entry: entry, item: sorted[0])
        case .systemMedium: CafeteriaMediumView(entry: entry, items: sorted)
        case .systemExtraLarge: CafeteriaExtraLargeView(entry: entry, items: sorted)
        default: CafeteriaLargeView(entry: entry, items: sorted)
        }
    }

    func status(for item: CafeteriaMenuItem) -> CafeteriaRunningStatus? {
        CafeteriaPresentation.status(runningTime: item.runningTime, now: entry.date, isNextDay: entry.isNextDay)
    }
}

private struct CafeteriaSmallView: View {
    let entry: CafeteriaEntry
    let item: CafeteriaMenuItem
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CafeteriaHeader(entry: entry, titleSize: 13, showsTime: false)
            CafeteriaBlock(
                item: item,
                style: .compact,
                nameSize: 12,
                menuSize: 11,
                maxMenus: CafeteriaLayoutMetrics.compactMenuLimit
            ).padding(.top, 8)
            Spacer(minLength: 0)
        }
    }
}

private struct CafeteriaMediumView: View {
    let entry: CafeteriaEntry
    let items: [CafeteriaMenuItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CafeteriaHeader(entry: entry, titleSize: 14, dateSize: 11, dateStyle: .abbreviated, showsTime: true)
            HStack(alignment: .top, spacing: 12) {
                block(items[0]).frame(maxWidth: .infinity, alignment: .leading)
                if items.count > 1 {
                    WidgetSeparator(axis: .vertical)
                    block(items[1]).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 10)
            Spacer(minLength: 0)
        }
    }

    private func block(_ item: CafeteriaMenuItem) -> some View {
        CafeteriaBlock(
            item: item,
            status: status(item),
            style: .compact,
            nameSize: 12,
            menuSize: 11,
            maxMenus: CafeteriaLayoutMetrics.compactMenuLimit
        )
    }

    private func status(_ item: CafeteriaMenuItem) -> CafeteriaRunningStatus? {
        CafeteriaPresentation.status(runningTime: item.runningTime, now: entry.date, isNextDay: entry.isNextDay)
    }
}

struct CafeteriaLargeView: View {
    let entry: CafeteriaEntry
    let items: [CafeteriaMenuItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.isNextDay {
                ended
            }
            CafeteriaHeader(entry: entry, titleSize: 17, dateSize: 12, dateStyle: .wide, showsTime: true)
            MealStripView(meal: entry.mealType).padding(.top, 8)
            GeometryReader { geo in
                CafeteriaLargeList(items: items, availableHeight: geo.size.height) { item in status(item) }
            }
            .padding(.top, 10)
        }
    }

    private var ended: some View {
        Text("cafeteria.ended.today").font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted).padding(
            .bottom,
            2
        )
    }

    private func status(_ item: CafeteriaMenuItem) -> CafeteriaRunningStatus? {
        CafeteriaPresentation.status(runningTime: item.runningTime, now: entry.date, isNextDay: entry.isNextDay)
    }
}

private struct CafeteriaLargeList: View {
    let items: [CafeteriaMenuItem]
    let availableHeight: CGFloat
    let status: (CafeteriaMenuItem) -> CafeteriaRunningStatus?

    private var count: Int {
        CafeteriaPresentation.fittingCount(of: items, availableHeight: availableHeight)
    }

    private var hidden: Int {
        items.count - count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.prefix(count).enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Color.clear.frame(height: 8); WidgetSeparator(); Color.clear.frame(height: 8)
                }
                CafeteriaBlock(item: item, status: status(item), style: .full, nameSize: 13, menuSize: 12)
            }
            Spacer(minLength: 0)
            if hidden > 0 {
                more(hidden)
            }
        }
    }
}

private struct CafeteriaExtraLargeView: View {
    let entry: CafeteriaEntry
    let items: [CafeteriaMenuItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.isNextDay {
                ended
            }
            HStack(spacing: 6) {
                Text(verbatim: entry.isNextDay ? String(localized: "meal.tomorrow.breakfast") : entry.mealType.title)
                    .font(.godo(size: 17, weight: .bold)).foregroundStyle(HYUWidgetColor.brand)
                Text(entry.menuDate, format: .dateTime.month().day().weekday(.wide)).font(.godo(size: 12, weight: .regular))
                    .foregroundStyle(HYUWidgetColor.muted)
                MealStripView(meal: entry.mealType).frame(width: 180).padding(.leading, 16)
                Spacer(minLength: 4)
                WidgetRefreshStamp(date: entry.date, intent: RefreshCafeteriaIntent())
            }.frame(minHeight: HYUWidgetMetrics.headerMinHeight)
            GeometryReader { geo in CafeteriaExtraLargeColumns(items: items, availableHeight: geo.size.height, entry: entry) }
                .padding(.top, 14)
        }
    }

    private var ended: some View {
        Text("cafeteria.ended.today").font(.godo(size: 11, weight: .regular))
            .foregroundStyle(HYUWidgetColor.muted).padding(.bottom, 2)
    }
}

private struct CafeteriaExtraLargeColumns: View {
    let items: [CafeteriaMenuItem]
    let availableHeight: CGFloat
    let entry: CafeteriaEntry
    private var shown: [CafeteriaMenuItem] {
        CafeteriaPresentation.fittingColumns(
            of: items,
            availableHeight: availableHeight,
            maxColumns: CafeteriaLayoutMetrics.xlMaxColumns
        )
    }

    private var hidden: Int {
        items.count - shown.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(shown) { item in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.cafeteriaName).font(.godo(size: 13, weight: .bold)).lineLimit(1)
                            .frame(height: CafeteriaLayoutMetrics.nameRowHeight)
                        Color.clear.frame(height: CafeteriaLayoutMetrics.menuSpacing)
                        if let status = CafeteriaPresentation.status(
                            runningTime: item.runningTime,
                            now: entry.date,
                            isNextDay: entry.isNextDay
                        ) {
                            CafeteriaStatusLabel(status: status, style: .column).frame(height: CafeteriaLayoutMetrics.statusRowHeight)
                        } else {
                            Color.clear.frame(height: CafeteriaLayoutMetrics.statusRowHeight)
                        }
                        Color.clear.frame(height: CafeteriaLayoutMetrics.statusGap)
                        VStack(alignment: .leading, spacing: CafeteriaLayoutMetrics.menuSpacing) {
                            ForEach(item.menus) { CafeteriaMenuLine(row: $0, size: 12) }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer(minLength: 0)
            if hidden > 0 {
                more(hidden)
            }
        }
    }
}

private func more(_ count: Int) -> some View {
    Text(verbatim: String(format: String(localized: "cafeteria.more.format"), count))
        .font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
        .frame(
            maxWidth: .infinity,
            minHeight: CafeteriaLayoutMetrics.footerHeight,
            maxHeight: CafeteriaLayoutMetrics.footerHeight,
            alignment: .bottomTrailing
        )
}
