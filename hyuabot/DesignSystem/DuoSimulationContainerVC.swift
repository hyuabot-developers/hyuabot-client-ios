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
        widthConstraint = root.view.widthAnchor.constraint(equalToConstant: size.width)
        heightConstraint = root.view.heightAnchor.constraint(equalToConstant: size.height)
        NSLayoutConstraint.activate([
            widthConstraint, heightConstraint,
            root.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            root.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        root.didMove(toParent: self)
        // `-DuoToggleEvery N` flips between unfolded and folded every N seconds to exercise fold/unfold.
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-DuoToggleEvery"), args.indices.contains(idx + 1),
           let seconds = TimeInterval(args[idx + 1]), seconds > 0 {
            Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in self?.toggleFold() }
        }
    }

    private var widthConstraint = NSLayoutConstraint()
    private var heightConstraint = NSLayoutConstraint()

    private func toggleFold() {
        let unfolded = widthConstraint.constant >= DuoLayout.wideThreshold
        widthConstraint.constant = unfolded ? 466 : 951
        heightConstraint.constant = unfolded ? 678 : 669
        view.layoutIfNeeded()
    }
}
