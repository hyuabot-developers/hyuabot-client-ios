//
//  RootVC+DuoDetail.swift
//  hyuabot
//
//  Right-hand detail pane used only in the unfolded (wide) layout.
//

import UIKit

extension UIViewController {
    /// Non-nil only when the app is in the unfolded wide layout and a detail pane is available.
    var duoWideRoot: RootVC? {
        guard let root = tabBarController as? RootVC, root.isWideLayout else { return nil }
        return root
    }
}

extension RootVC {
    func showDuoDetail(_ detail: UIViewController) {
        duoDetailHost.show(detail, in: self)
    }

    func clearDuoDetail() {
        duoDetailHost.show(nil, in: self)
    }
}

/// Navigation container for a screen shown in the detail pane, styled like the tab navigation controllers.
final class DuoDetailNC: UINavigationController, UINavigationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        navigationBar.prefersLargeTitles = false
        let appearance = SettingsNavigationStyle.makeAppearance()
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = SettingsNavigationStyle.makeScrollEdgeAppearance()
        navigationBar.tintColor = SettingsStyle.Color.link
    }

    /// A plain custom-view close item; the system close item can fail to render in the embedded bar on the Duo inner display.
    static func makeCloseItem(_ action: @escaping () -> Void) -> UIBarButtonItem {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = SettingsStyle.Color.tabGlass
        config.baseForegroundColor = SettingsStyle.Color.link
        config.cornerStyle = .capsule
        config.image = UIImage(systemName: "xmark")
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        button.accessibilityIdentifier = "duo.detail.close"
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        return UIBarButtonItem(customView: button)
    }

    private lazy var fallbackButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = SettingsStyle.Color.tabGlass
        config.baseForegroundColor = SettingsStyle.Color.link
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.fallbackAction() })
        button.accessibilityIdentifier = "duo.detail.close"
        return button
    }()
    private static let fallbackInset: CGFloat = 48

    /// On the Duo inner display the embedded bar can collapse to zero height, which hides the close button;
    /// show an explicit control in a reserved strip instead.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let collapsed = !isNavigationBarHidden && navigationBar.frame.height < 1
        let inset = collapsed ? Self.fallbackInset : 0
        if additionalSafeAreaInsets.top != inset { additionalSafeAreaInsets.top = inset }
        fallbackButton.isHidden = !collapsed
        guard collapsed else { return }
        let nested = viewControllers.count > 1
        fallbackButton.configuration?.image = UIImage(systemName: nested ? "chevron.left" : "xmark")
        if fallbackButton.superview == nil {
            view.addSubview(fallbackButton)
            fallbackButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                fallbackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                fallbackButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
                fallbackButton.widthAnchor.constraint(equalToConstant: 36),
                fallbackButton.heightAnchor.constraint(equalToConstant: 36)
            ])
        }
        view.bringSubviewToFront(fallbackButton)
    }

    private func fallbackAction() {
        if viewControllers.count > 1 {
            popViewController(animated: true)
        } else {
            (parent as? RootVC)?.clearDuoDetail()
        }
    }

    // The pane is narrower than a phone screen and has its own heading; keep titles inline.
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.largeTitleDisplayMode = .never
    }
}

final class DuoDetailPaneView: UIView {
    private let placeholder = UILabel()
    private let divider = UIView()
    private(set) weak var current: UIViewController?
    private weak var base: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.tabGlass
        accessibilityIdentifier = "duo.detail"
        divider.backgroundColor = SettingsStyle.Color.tabEdge
        addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        placeholder.text = String(localized: "duo.detail.placeholder")
        placeholder.font = SettingsStyle.font(15, bold: false)
        placeholder.textColor = .secondaryLabel
        placeholder.textAlignment = .center
        placeholder.numberOfLines = 0
        addSubview(placeholder)
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            placeholder.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholder.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholder.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func refreshPlaceholder() {
        placeholder.isHidden = current != nil || base != nil
    }

    /// Content shown while no detail is open (e.g. the continued list of Subway / Cafeteria).
    func setBase(_ view: UIView?) {
        guard base !== view else { return }
        base?.removeFromSuperview()
        base = view
        if let view {
            insertSubview(view, at: 0)
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.topAnchor.constraint(equalTo: topAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
        refreshPlaceholder()
    }

    func clearBase(_ view: UIView) {
        if base === view { setBase(nil) }
    }

    func show(_ vc: UIViewController?, in parent: UIViewController) {
        if let old = current {
            // The host is added after the parent has already appeared, so UIKit won't forward appearance callbacks.
            old.beginAppearanceTransition(false, animated: false)
            old.willMove(toParent: nil)
            old.view.removeFromSuperview()
            old.removeFromParent()
            old.endAppearanceTransition()
        }
        current = vc
        refreshPlaceholder()
        guard let vc else { return }
        parent.addChild(vc)
        vc.beginAppearanceTransition(true, animated: false)
        insertSubview(vc.view, belowSubview: divider)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            vc.view.topAnchor.constraint(equalTo: topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        vc.didMove(toParent: parent)
        vc.endAppearanceTransition()
    }
}

extension UINavigationController {
    /// Pushes on phones; in the unfolded Duo layout opens the screen in the right-hand detail pane instead.
    func pushOrShowDuoDetail(_ viewController: UIViewController, animated: Bool = true) {
        if let root = duoWideRoot {
            if viewController.navigationItem.leftBarButtonItem == nil {
                viewController.navigationItem.leftBarButtonItem = DuoDetailNC.makeCloseItem { [weak root] in root?.clearDuoDetail() }
            }
            root.showDuoDetail(DuoDetailNC(rootViewController: viewController))
        } else {
            pushViewController(viewController, animated: animated)
        }
    }
}

extension UIViewController {
    /// Presents a sheet on phones; in the unfolded Duo layout shows it in the right-hand pane so nothing covers the fold.
    func presentOrShowDuoDetail(_ viewController: UIViewController, animated: Bool = true) {
        guard let root = duoWideRoot else {
            present(viewController, animated: animated, completion: nil)
            return
        }
        viewController.navigationItem.leftBarButtonItem = DuoDetailNC.makeCloseItem { [weak root] in root?.clearDuoDetail() }
        root.showDuoDetail(DuoDetailNC(rootViewController: viewController))
    }
}

/// Scrolling column hosted in the detail pane's default state; holds the cards a screen continues on the right.
final class DuoSecondaryColumnView: UIView {
    let stack = UIStackView()
    private let scroll = UIScrollView()
    private var topConstraint = NSLayoutConstraint()

    init(spacing: CGFloat) {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.background
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        stack.axis = .vertical
        stack.spacing = spacing
        [scroll, stack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        addSubview(scroll)
        scroll.addSubview(stack)
        topConstraint = stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 8)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            topConstraint,
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -HYUMetrics.Layout.screenBottom)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTopInset(_ value: CGFloat) {
        if abs(topConstraint.constant - value) > 0.5 { topConstraint.constant = value }
    }
}

extension UIViewController {
    /// In the unfolded layout, puts `column` in the detail pane's default state (only while this screen's tab is selected).
    /// Returns whether the layout is unfolded. Otherwise removes the column from the pane.
    @discardableResult
    func syncDuoSecondary(_ column: UIView) -> Bool {
        guard let root = duoWideRoot else {
            (tabBarController as? RootVC)?.duoDetailHost.clearBase(column)
            return false
        }
        if root.selectedViewController === navigationController {
            root.duoDetailHost.setBase(column)
        }
        return true
    }

    func releaseDuoSecondary(_ column: UIView) {
        (tabBarController as? RootVC)?.duoDetailHost.clearBase(column)
    }

    /// Sheet-style screens call this instead of `dismiss` so they also close when shown in the detail pane.
    func dismissOrClearDuoDetail(animated: Bool = true, completion: (() -> Void)? = nil) {
        if navigationController is DuoDetailNC, let root = duoWideRoot {
            root.clearDuoDetail()
            completion?()
        } else {
            dismiss(animated: animated, completion: completion)
        }
    }
}
