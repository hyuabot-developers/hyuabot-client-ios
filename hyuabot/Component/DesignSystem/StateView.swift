//
//  StateView.swift
//  hyuabot
//

import SnapKit
import UIKit

/// The five states a screen can show in place of content.
/// `rawValue` is the GA4 `kind` parameter of `empty_state_shown`.
enum StateKind: String {
    case empty
    case ended
    case suspended
    case error
    case permissionDenied = "permission_denied"
}

struct StateAction {
    let title: String
    let handler: () -> Void
}

struct StateContent {
    let kind: StateKind
    let message: String?
    let action: StateAction?

    var title: String {
        switch kind {
        case .empty: String(localized: "state.empty.title")
        case .ended: String(localized: "state.ended.title")
        case .suspended: String(localized: "state.suspended.title")
        case .error: String(localized: "state.error.title")
        case .permissionDenied: String(localized: "state.permission_denied.title")
        }
    }

    /// Shows a caller-supplied message. The button appears only when `action` is passed.
    static func empty(message: String, action: StateAction? = nil) -> StateContent {
        StateContent(kind: .empty, message: message, action: action)
    }

    static func ended(onShowTimetable: @escaping () -> Void) -> StateContent {
        StateContent(
            kind: .ended,
            message: nil,
            action: StateAction(title: String(localized: "state.action.full_timetable"), handler: onShowTimetable)
        )
    }

    /// `date` is already parsed by the caller. It is shown in the app language.
    @MainActor
    static func suspended(date: Date, onShowTimetable: @escaping () -> Void) -> StateContent {
        let locale = Locale(identifier: LanguageManager.shared.apiLanguageTag)
        return StateContent(
            kind: .suspended,
            message: date.formatted(.dateTime.month().day().weekday(.abbreviated).locale(locale)),
            action: StateAction(title: String(localized: "state.action.full_timetable"), handler: onShowTimetable)
        )
    }

    static func error(onRetry: @escaping () -> Void) -> StateContent {
        StateContent(
            kind: .error,
            message: nil,
            action: StateAction(title: String(localized: "state.action.retry"), handler: onRetry)
        )
    }

    static func permissionDenied(onOpenSettings: @escaping () -> Void = StateContent.openAppSettings) -> StateContent {
        StateContent(
            kind: .permissionDenied,
            message: nil,
            action: StateAction(title: String(localized: "state.action.open_settings"), handler: onOpenSettings)
        )
    }

    private static func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

/// Shared empty/ended/suspended/error/permission view built on `UIContentUnavailableView`.
/// Logs `empty_state_shown` once each time it appears in a window with a given kind.
final class StateView: UIView {
    let sourceScreen: AnalyticsScreen

    /// Records the analytics event. Replaced in tests.
    var logShown: (StateKind, AnalyticsScreen) -> Void = { kind, screen in
        AnalyticsManager.logEmptyStateShown(kind: kind, screen: screen)
    }

    private let unavailableView = UIContentUnavailableView(configuration: .empty())
    private var content: StateContent?
    private var loggedKind: StateKind?

    init(sourceScreen: AnalyticsScreen) {
        self.sourceScreen = sourceScreen
        super.init(frame: .zero)
        addSubview(unavailableView)
        unavailableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // Title and body sizes depend on the content size category, so rebuild on change.
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: StateView, _) in
            view.render()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ content: StateContent) {
        self.content = content
        render()
        logIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            loggedKind = nil
        } else {
            logIfNeeded()
        }
    }

    private func render() {
        guard let content else { return }
        unavailableView.configuration = Self.makeConfiguration(for: content, traits: traitCollection)
    }

    private func logIfNeeded() {
        guard window != nil, let kind = content?.kind, kind != loggedKind else { return }
        loggedKind = kind
        logShown(kind, sourceScreen)
    }

    static func makeConfiguration(for content: StateContent, traits: UITraitCollection) -> UIContentUnavailableConfiguration {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = content.kind == .error ? UIImage(systemName: "exclamationmark.triangle.fill") : nil

        // One attributed string keeps title and body as a single accessibility element.
        let text = NSMutableAttributedString(string: content.title, attributes: [
            .font: HYUFont.font(.title3, compatibleWith: traits),
            .foregroundColor: HYUColor.Text.primary,
        ])
        if let message = content.message, !message.isEmpty {
            text.append(NSAttributedString(string: "\n" + message, attributes: [
                .font: HYUFont.font(.subheadline, compatibleWith: traits),
                .foregroundColor: HYUColor.Text.secondary,
            ]))
        }
        configuration.attributedText = text

        let margins = configuration.directionalLayoutMargins
        configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: HYUMetrics.Space.xxl,
            leading: margins.leading,
            bottom: HYUMetrics.Space.xxl,
            trailing: margins.trailing
        )

        if let action = content.action {
            configuration.button = .tinted()
            configuration.button.title = action.title
            configuration.buttonProperties.primaryAction = UIAction { _ in action.handler() }
        }
        return configuration
    }
}
