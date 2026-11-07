//
//  CommuterBusVC.swift
//  hyuabot
//

import UIKit

final class CommuterBusVC: UIViewController, SettingsStyledScreen {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "campus.commuter.title")
        navigationItem.title = title
        view.backgroundColor = SettingsStyle.Color.background
        view.accessibilityIdentifier = "commuter.root"
        SettingsNavigationStyle.apply(to: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        SettingsNavigationStyle.screenWillAppear(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingsNavigationStyle.screenWillDisappear(self)
    }
}
