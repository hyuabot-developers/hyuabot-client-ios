//
//  WidgetStateView.swift
//  hyuabot
//

import AppIntents
import SwiftUI

enum WidgetStateKind: Equatable {
    case locationRequired
    case ended(message: LocalizedStringKey)
    case empty(message: LocalizedStringKey)
    case error
}

struct WidgetStateView<Intent: AppIntent>: View {
    let title: String
    let refreshDate: Date?
    let kind: WidgetStateKind
    let retryIntent: Intent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(verbatim: title)
                    .font(.godo(size: 13, weight: .bold))
                    .foregroundStyle(HYUWidgetColor.brand)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if shouldShowRefresh, let refreshDate {
                    WidgetRefreshStamp(date: refreshDate, intent: retryIntent)
                }
            }
            .frame(minHeight: HYUWidgetMetrics.headerMinHeight)

            Spacer(minLength: 4)
            VStack(spacing: 6) {
                icon
                Text(message)
                    .font(.godo(size: 12, weight: .semibold))
                    .foregroundStyle(HYUWidgetColor.foreground)
                    .multilineTextAlignment(.center)
                extraLine
            }
            .frame(maxWidth: .infinity)
            Spacer(minLength: 4)
        }
    }

    private var shouldShowRefresh: Bool {
        switch kind {
        case .ended, .empty: true
        case .locationRequired, .error: false
        }
    }

    private var message: LocalizedStringKey {
        switch kind {
        case .locationRequired: "shuttle.location.required"
        case let .ended(message), let .empty(message): message
        case .error: "widget.state.error.message"
        }
    }

    @ViewBuilder private var extraLine: some View {
        switch kind {
        case .locationRequired:
            Text("widget.state.location.hint")
                .font(.godo(size: 11, weight: .regular))
                .foregroundStyle(HYUWidgetColor.muted)
        case .error:
            Button(intent: retryIntent) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("widget.state.retry")
                }
                .font(.godo(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(Capsule().fill(HYUWidgetColor.brandFill))
            }
            .buttonStyle(.plain)
        case .ended, .empty:
            EmptyView()
        }
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(HYUWidgetColor.hero)
            switch kind {
            case .locationRequired:
                Circle()
                    .fill(HYUWidgetColor.brandFill)
                    .frame(width: 9, height: 9)
            case .ended:
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HYUWidgetColor.muted)
            case .empty:
                Image(systemName: "tray")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HYUWidgetColor.muted)
            case .error:
                Image(systemName: "exclamationmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HYUWidgetColor.warning)
            }
        }
        .frame(width: 30, height: 30)
    }
}
