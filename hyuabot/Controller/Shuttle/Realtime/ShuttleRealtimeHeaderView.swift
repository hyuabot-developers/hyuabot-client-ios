//
//  ShuttleRealtimeHeaderView.swift
//  hyuabot
//

import UIKit

class ShuttleRealtimeHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ShuttleRealtimeHeaderView"
    var onToggle: ((Bool) -> Void)?
    private(set) var isExpanded: Bool = false
    private var routeAdapter: ShuttleRouteAdapter?
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .white
        $0.textAlignment = .center
    }

    lazy var helpImageView = UIImageView(image: UIImage(systemName: "questionmark.message")).then {
        $0.tintColor = .white
        $0.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleRouteAdapter))
        $0.addGestureRecognizer(tapGesture)
    }

    private lazy var headerView = UIView().then {
        $0.addSubview(titleLabel)
        $0.addSubview(helpImageView)
        $0.snp.makeConstraints { make in
            make.height.equalTo(50).priority(.high)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.helpImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-24)
            make.size.equalTo(20)
        }
    }

    private lazy var foldableView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.addArrangedSubview(headerView)
    }

    var routeAdapterHeight: CGFloat {
        routeAdapter?.intrinsicContentSize.height ?? 0
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(title: String, stop: ShuttleStopEnum, section: Int, isExpanded: Bool = false) {
        self.isExpanded = isExpanded
        self.routeAdapter?.removeFromSuperview()
        self.routeAdapter = nil

        self.routeAdapter = ShuttleRealtimeHeaderRoutes.adapter(stop: stop, section: section)
        guard let routeAdapter else { return }
        routeAdapter.isHidden = !isExpanded
        foldableView.addArrangedSubview(routeAdapter)
        contentView.backgroundColor = .hanyangBlue
        if foldableView.superview == nil {
            contentView.addSubview(foldableView)
            foldableView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        titleLabel.text = title
    }

    func collapse() {
        guard isExpanded, let routeAdapter else { return }
        isExpanded = false
        routeAdapter.isHidden = true
        onToggle?(false)
    }

    @objc
    private func toggleRouteAdapter() {
        AnalyticsManager.logSelect(.shuttleRouteToggle)
        guard let routeAdapter else { return }
        isExpanded.toggle()
        routeAdapter.isHidden = !isExpanded
        onToggle?(isExpanded)
        if let tableView = superview as? UITableView {
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }
}
