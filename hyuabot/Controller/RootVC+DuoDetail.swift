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

    // The pane is narrower than a phone screen and has its own heading; keep titles inline.
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.largeTitleDisplayMode = .never
    }
}

final class DuoDetailPaneView: UIView {
    private let placeholder = UILabel()
    private let divider = UIView()
    private(set) weak var current: UIViewController?

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

    func show(_ vc: UIViewController?, in parent: UIViewController) {
        if let old = current {
            old.willMove(toParent: nil)
            old.view.removeFromSuperview()
            old.removeFromParent()
        }
        current = vc
        placeholder.isHidden = vc != nil
        guard let vc else { return }
        parent.addChild(vc)
        insertSubview(vc.view, belowSubview: divider)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            vc.view.topAnchor.constraint(equalTo: topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        vc.didMove(toParent: parent)
    }
}

extension UINavigationController {
    /// Pushes on phones; in the unfolded Duo layout opens the screen in the right-hand detail pane instead.
    func pushOrShowDuoDetail(_ viewController: UIViewController, animated: Bool = true) {
        if let root = duoWideRoot {
            root.showDuoDetail(DuoDetailNC(rootViewController: viewController))
        } else {
            pushViewController(viewController, animated: animated)
        }
    }
}
