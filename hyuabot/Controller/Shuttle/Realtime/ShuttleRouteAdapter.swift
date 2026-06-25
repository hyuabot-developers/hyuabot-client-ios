import UIKit

class ShuttleRouteAdapter: UIView {
    private let routes: [ShuttleRouteItemView.Route]
    private let labels: [String.LocalizationValue]
    private let headerView: UIView = {
        let view = UIView()
        let headerView = ShuttleRouteHeaderView()
        view.addSubview(headerView)
        view.snp.makeConstraints {
            $0.height.equalTo(28)
        }
        headerView.backgroundColor = .clear
        headerView.snp.makeConstraints {
            $0.height.equalToSuperview()
            $0.leading.equalToSuperview().offset(80).priority(.high)
            $0.trailing.equalToSuperview()
        }
        return view
    }()

    private lazy var stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.addArrangedSubview(headerView)
    }

    init(routes: [ShuttleRouteItemView.Route], labels: [String.LocalizationValue]) {
        self.routes = routes
        self.labels = labels
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .hanyangBlue
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        for (index, route) in routes.enumerated() {
            let rowView = UIView()
            let label = UILabel().then {
                $0.text = index < labels.count ? String(localized: labels[index]).replacingOccurrences(of: " ", with: "\n") : ""
                $0.font = .godo(size: 16, weight: .bold)
                $0.textColor = .white
                $0.textAlignment = .center
                $0.numberOfLines = 2
                $0.lineBreakMode = .byWordWrapping
                $0.adjustsFontSizeToFitWidth = true
                $0.minimumScaleFactor = 0.5
            }
            let routeView = ShuttleRouteItemView().then {
                $0.bind(data: route)
            }
            rowView.addSubview(label)
            rowView.addSubview(routeView)
            label.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.centerY.equalToSuperview().offset(-6)
                make.width.equalTo(80).priority(.high)
            }
            routeView.snp.makeConstraints { make in
                make.leading.equalTo(label.snp.trailing)
                make.trailing.top.bottom.equalToSuperview()
            }
            rowView.snp.makeConstraints { make in
                make.height.equalTo(60).priority(.high)
            }
            stackView.addArrangedSubview(rowView)
        }
    }
}
