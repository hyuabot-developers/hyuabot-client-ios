//
//  TransferTransitGrid.swift
//  hyuabot
//

import AppIntents
import SwiftUI
import WidgetKit

struct TransitGridRow: Identifiable {
    let id = UUID()
    let colorKey: String
    let left: TransitEntry?
    let right: TransitEntry?
}

struct TransitCell: View {
    let entry: TransitEntry?
    let minuteSize: CGFloat
    let labelSize: CGFloat

    var body: some View {
        Group {
            if let entry {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    InlineMinutesText(minutes: entry.minutes, size: minuteSize, imminent: entry.minutes <= HYUWidgetMetrics.imminentMinutes)
                    if !entry.terminal.isEmpty {
                        Text(verbatim: entry.terminal)
                            .font(.godo(size: labelSize, weight: .regular))
                            .foregroundStyle(HYUWidgetColor.muted)
                            .lineLimit(1)
                    }
                }
            } else {
                Text(verbatim: "-").foregroundStyle(HYUWidgetColor.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TransitGrid: View {
    let title: LocalizedStringKey?
    let leftHeader: LocalizedStringKey?
    let rightHeader: LocalizedStringKey?
    let rows: [TransitGridRow]
    let badgeWidth: CGFloat
    let minuteSize: CGFloat
    let labelSize: CGFloat
    let rowSpacing: CGFloat

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: rowSpacing) {
            if let title {
                GridRow {
                    Text(title).font(.godo(size: 11, weight: .bold)).foregroundStyle(HYUWidgetColor.brand)
                        .frame(width: badgeWidth, alignment: .leading).padding(.bottom, 4)
                    Text(leftHeader ?? "").font(.godo(size: 10, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
                        .padding(.bottom, 4)
                    Text(rightHeader ?? "").font(.godo(size: 10, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
                        .padding(.bottom, 4)
                }
            }
            ForEach(rows) { row in
                GridRow {
                    RouteBadge(colorKey: row.colorKey).frame(width: badgeWidth, alignment: .leading)
                    TransitCell(entry: row.left, minuteSize: minuteSize, labelSize: labelSize)
                    TransitCell(entry: row.right, minuteSize: minuteSize, labelSize: labelSize)
                }
            }
        }
    }
}

func subwayRows(_ arrivals: [TransitArrival]) -> [TransitGridRow] {
    arrivals.filter { $0.colorKey != "bus" }.map {
        TransitGridRow(colorKey: $0.colorKey, left: $0.upEntries.first, right: $0.downEntries.first)
    }
}

func busRows(_ arrivals: [TransitArrival]) -> [TransitGridRow] {
    arrivals.filter { $0.colorKey == "bus" }.map {
        TransitGridRow(colorKey: $0.colorKey, left: $0.upEntries.first, right: $0.upEntries.dropFirst().first)
    }
}
