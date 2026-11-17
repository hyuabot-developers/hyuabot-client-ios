//
//  DuoSimulationContainerVC.swift
//  hyuabot
//
//  DEBUG-only: letterboxes RootVC at iPhone Duo point sizes so layouts can be checked on any simulator.
//

import UIKit

final class DuoSimulationContainerVC: UIViewController {
    private let root: UIViewController
    private let size: CGSize

    init(root: UIViewController, size: CGSize) {
        self.root = root
        self.size = size
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        addChild(root)
        view.addSubview(root.view)
        root.view.translatesAutoresizingMaskIntoConstraints = false
        root.view.clipsToBounds = true
        NSLayoutConstraint.activate([
            root.view.widthAnchor.constraint(equalToConstant: size.width),
            root.view.heightAnchor.constraint(equalToConstant: size.height),
            root.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            root.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        root.didMove(toParent: self)
    }
}
