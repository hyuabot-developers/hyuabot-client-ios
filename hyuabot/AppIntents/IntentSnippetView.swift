//
//  IntentSnippetView.swift
//  hyuabot
//

import SwiftUI

struct IntentSnippetView: View {
    let content: IntentSnippetContent

    var body: some View {
        VStack(alignment: .leading, spacing: HYUMetrics.Space.small) {
            Text(content.title)
                .font(.headline)
                .foregroundStyle(Color(uiColor: HYUColor.Text.primary))
            if let subtitle = content.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color(uiColor: HYUColor.Text.secondary))
            }
            if content.rows.isEmpty {
                Text(content.emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(Color(uiColor: HYUColor.Text.secondary))
            } else {
                ForEach(content.rows) { row in
                    IntentSnippetRowView(row: row)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HYUMetrics.Space.large)
    }
}

private struct IntentSnippetRowView: View {
    let row: IntentSnippetRow

    var body: some View {
        HStack(alignment: .center, spacing: HYUMetrics.Space.medium) {
            VStack(alignment: .leading, spacing: HYUMetrics.Space.xxs) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(uiColor: HYUColor.Text.primary))
                Text(row.detail)
                    .font(.footnote)
                    .foregroundStyle(Color(uiColor: HYUColor.Text.secondary))
                    .lineLimit(3)
            }
            Spacer(minLength: HYUMetrics.Space.small)
            if let badge = row.badge {
                Text(badge)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(uiColor: row.isRealtime ? HYUColor.Status.realtimeFg : HYUColor.Status.scheduledFg))
                    .padding(.horizontal, HYUMetrics.Space.small)
                    .padding(.vertical, HYUMetrics.Space.xxs)
                    .background(Capsule().fill(Color(uiColor: row.isRealtime ? HYUColor.Status.realtimeBg : HYUColor.Status.scheduledBg)))
            }
        }
        .padding(HYUMetrics.Space.medium)
        .background(
            RoundedRectangle(cornerRadius: HYUMetrics.Radius.row, style: .continuous)
                .fill(Color(uiColor: HYUColor.Background.cardInset))
        )
    }
}
