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
    private lazy var helpImageView = UIImageView(image: UIImage(systemName: "questionmark.message")).then {
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
        self.routeAdapter?.intrinsicContentSize.height ?? 0
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(title: String, stop: ShuttleStopEnum, section: Int, isExpanded: Bool = false) {
        self.isExpanded = isExpanded
        self.routeAdapter?.removeFromSuperview()
        self.routeAdapter = nil
        
        self.routeAdapter = self.generateRouteAdapter(stop: stop, section: section)
        guard let routeAdapter = self.routeAdapter else { return }
        routeAdapter.isHidden = !isExpanded
        self.foldableView.addArrangedSubview(routeAdapter)
        self.contentView.backgroundColor = .hanyangBlue
        if foldableView.superview == nil {
            self.contentView.addSubview(foldableView)
            self.foldableView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        self.titleLabel.text = title
    }
    
    private func generateRouteAdapter(stop: ShuttleStopEnum, section: Int) -> ShuttleRouteAdapter {
        if (stop == .dormiotryOut) {
            if (section == 0) {
                return ShuttleRouteAdapter(
                    routes: [
                        ShuttleRouteItemView.Route(
                            color: .busRed,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 0,
                            labels: [
                                "shuttle.stop.dormitory.out": 0,
                                "shuttle.stop.shuttlecock.out": 5,
                                "shuttle.stop.station": 15,
                                "shuttle.stop.shuttlecock.in": 25,
                                "shuttle.stop.dormitory.in": 30,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .white,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.terminal",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 0,
                            labels: [
                                "shuttle.stop.dormitory.out": 0,
                                "shuttle.stop.shuttlecock.out": 5,
                                "shuttle.stop.station": 15,
                                "shuttle.stop.terminal": 20,
                                "shuttle.stop.shuttlecock.in": 30,
                                "shuttle.stop.dormitory.in": 35,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .hanyangGreen,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.jungang.station",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 0,
                            labels: [
                                "shuttle.stop.dormitory.out": 0,
                                "shuttle.stop.shuttlecock.out": 5,
                                "shuttle.stop.station": 15,
                                "shuttle.stop.jungang.station": 18,
                                "shuttle.stop.shuttlecock.in": 28,
                                "shuttle.stop.dormitory.in": 33,
                            ]
                        )
                    ],
                    labels: [
                        String.LocalizationValue("shuttle.type.direct"),
                        String.LocalizationValue("shuttle.type.circular"),
                        String.LocalizationValue("shuttle.type.jungang_station")
                    ]
                )
            } else if (section == 1) {
                return ShuttleRouteAdapter(
                    routes: [
                        ShuttleRouteItemView.Route(
                            color: .busRed,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.terminal",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 0,
                            labels: [
                                "shuttle.stop.dormitory.out": 0,
                                "shuttle.stop.shuttlecock.out": 5,
                                "shuttle.stop.terminal": 15,
                                "shuttle.stop.shuttlecock.in": 25,
                                "shuttle.stop.dormitory.in": 30,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .white,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.terminal",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 0,
                            labels: [
                                "shuttle.stop.dormitory.out": 0,
                                "shuttle.stop.shuttlecock.out": 5,
                                "shuttle.stop.station": 15,
                                "shuttle.stop.terminal": 20,
                                "shuttle.stop.shuttlecock.in": 30,
                                "shuttle.stop.dormitory.in": 35,
                            ]
                        )
                    ],
                    labels: [
                        String.LocalizationValue("shuttle.type.direct"),
                        String.LocalizationValue("shuttle.type.circular")
                    ]
                )
            } else if (section == 2) {
                return ShuttleRouteAdapter(
                    routes: [
                        ShuttleRouteItemView.Route(
                            color: .hanyangGreen,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.jungang.station",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 0,
                            labels: [
                                "shuttle.stop.dormitory.out": 0,
                                "shuttle.stop.shuttlecock.out": 5,
                                "shuttle.stop.station": 15,
                                "shuttle.stop.jungang.station": 18,
                                "shuttle.stop.shuttlecock.in": 28,
                                "shuttle.stop.dormitory.in": 33,
                            ]
                        )
                    ],
                    labels: [
                        String.LocalizationValue("shuttle.type.jungang_station")
                    ]
                )
            }
        } else if (stop == .shuttlecockOut) {
            if (section == 0) {
                return ShuttleRouteAdapter(
                    routes: [
                        ShuttleRouteItemView.Route(
                            color: .busRed,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -5,
                                "shuttle.stop.shuttlecock.out": 0,
                                "shuttle.stop.station": 10,
                                "shuttle.stop.shuttlecock.in": 20,
                                "shuttle.stop.dormitory.in": 25,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .white,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.terminal",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -5,
                                "shuttle.stop.shuttlecock.out": 0,
                                "shuttle.stop.station": 10,
                                "shuttle.stop.terminal": 15,
                                "shuttle.stop.shuttlecock.in": 25,
                                "shuttle.stop.dormitory.in": 30,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .hanyangGreen,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.jungang.station",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -5,
                                "shuttle.stop.shuttlecock.out": 0,
                                "shuttle.stop.station": 10,
                                "shuttle.stop.jungang.station": 13,
                                "shuttle.stop.shuttlecock.in": 23,
                                "shuttle.stop.dormitory.in": 28,
                            ]
                        )
                    ],
                    labels: [
                        String.LocalizationValue("shuttle.type.direct"),
                        String.LocalizationValue("shuttle.type.circular"),
                        String.LocalizationValue("shuttle.type.jungang_station")
                    ]
                )
            } else if (section == 1) {
                return ShuttleRouteAdapter(
                    routes: [
                        ShuttleRouteItemView.Route(
                            color: .busRed,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.terminal",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -5,
                                "shuttle.stop.shuttlecock.out": 0,
                                "shuttle.stop.terminal": 10,
                                "shuttle.stop.shuttlecock.in": 20,
                                "shuttle.stop.dormitory.in": 25,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .white,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.terminal",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -5,
                                "shuttle.stop.shuttlecock.out": 0,
                                "shuttle.stop.station": 10,
                                "shuttle.stop.terminal": 15,
                                "shuttle.stop.shuttlecock.in": 25,
                                "shuttle.stop.dormitory.in": 30,
                            ]
                        ),
                    ],
                    labels: [
                        String.LocalizationValue("shuttle.type.direct"),
                        String.LocalizationValue("shuttle.type.circular"),
                    ]
                )
            } else if (section == 2) {
                return ShuttleRouteAdapter(
                    routes: [
                        ShuttleRouteItemView.Route(
                            color: .hanyangGreen,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.jungang.station",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -5,
                                "shuttle.stop.shuttlecock.out": 0,
                                "shuttle.stop.station": 10,
                                "shuttle.stop.jungang.station": 13,
                                "shuttle.stop.shuttlecock.in": 23,
                                "shuttle.stop.dormitory.in": 28,
                            ]
                        )
                    ],
                    labels: [
                        String.LocalizationValue("shuttle.type.jungang_station")
                    ]
                )
            }
        } else if (stop == .station) {
            if (section == 0) {
                return ShuttleRouteAdapter(
                    routes: [
                        ShuttleRouteItemView.Route(
                            color: .busRed,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.station",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -15,
                                "shuttle.stop.station": 0,
                                "shuttle.stop.shuttlecock.in": 10,
                                "shuttle.stop.dormitory.in": 15,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .busRed,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.station",
                                "shuttle.stop.shuttlecock.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -15,
                                "shuttle.stop.station": 0,
                                "shuttle.stop.shuttlecock.in": 10,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .white,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.station",
                                "shuttle.stop.terminal",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -15,
                                "shuttle.stop.station": 0,
                                "shuttle.stop.terminal": 5,
                                "shuttle.stop.shuttlecock.in": 15,
                                "shuttle.stop.dormitory.in": 20,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .white,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.station",
                                "shuttle.stop.terminal",
                                "shuttle.stop.shuttlecock.in"
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -15,
                                "shuttle.stop.station": 0,
                                "shuttle.stop.terminal": 5,
                                "shuttle.stop.dormitory.in": 20,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .hanyangGreen,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.station",
                                "shuttle.stop.jungang.station",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -15,
                                "shuttle.stop.station": 0,
                                "shuttle.stop.jungang.station": 3,
                                "shuttle.stop.shuttlecock.in": 13,
                                "shuttle.stop.dormitory.in": 18,
                            ]
                        )
                    ],
                    labels: [
                        String.LocalizationValue("shuttle.type.direct.dormitory"),
                        String.LocalizationValue("shuttle.type.direct.shuttlecock"),
                        String.LocalizationValue("shuttle.type.circular.dormitory"),
                        String.LocalizationValue("shuttle.type.circular.shuttlecock"),
                        String.LocalizationValue("shuttle.type.jungang_station")
                    ]
                )
            } else if (section == 1) {
                return ShuttleRouteAdapter(
                    routes: [
                        ShuttleRouteItemView.Route(
                            color: .white,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.station",
                                "shuttle.stop.terminal",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -15,
                                "shuttle.stop.station": 0,
                                "shuttle.stop.terminal": 5,
                                "shuttle.stop.shuttlecock.in": 15,
                                "shuttle.stop.dormitory.in": 20,
                            ]
                        ),
                        ShuttleRouteItemView.Route(
                            color: .white,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.station",
                                "shuttle.stop.terminal",
                                "shuttle.stop.shuttlecock.in"
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -15,
                                "shuttle.stop.station": 0,
                                "shuttle.stop.terminal": 5,
                                "shuttle.stop.shuttlecock.in": 15
                            ]
                        ),
                    ],
                    labels: [
                        String.LocalizationValue("shuttle.type.circular.dormitory"),
                        String.LocalizationValue("shuttle.type.circular.shuttlecock"),
                    ]
                )
            } else if (section == 2) {
                return ShuttleRouteAdapter(
                    routes: [
                        ShuttleRouteItemView.Route(
                            color: .hanyangGreen,
                            stops: [
                                "shuttle.stop.dormitory.out",
                                "shuttle.stop.shuttlecock.out",
                                "shuttle.stop.station",
                                "shuttle.stop.jungang.station",
                                "shuttle.stop.shuttlecock.in",
                                "shuttle.stop.dormitory.in",
                            ],
                            currentStopIndex: 1,
                            labels: [
                                "shuttle.stop.dormitory.out": -15,
                                "shuttle.stop.shuttlecock.out": -10,
                                "shuttle.stop.station": 0,
                                "shuttle.stop.jungang.station": 3,
                                "shuttle.stop.shuttlecock.in": 13,
                                "shuttle.stop.dormitory.in": 18,
                            ]
                        )
                    ],
                    labels: [
                        String.LocalizationValue("shuttle.type.jungang_station")
                    ]
                )
            }
        } else if (stop == .terminal) {
            return ShuttleRouteAdapter(
                routes: [
                    ShuttleRouteItemView.Route(
                        color: .white,
                        stops: [
                            "shuttle.stop.dormitory.out",
                            "shuttle.stop.terminal",
                            "shuttle.stop.shuttlecock.in",
                            "shuttle.stop.dormitory.in",
                        ],
                        currentStopIndex: 1,
                        labels: [
                            "shuttle.stop.dormitory.out": -15,
                            "shuttle.stop.terminal": 0,
                            "shuttle.stop.shuttlecock.in": 10,
                            "shuttle.stop.dormitory.in": 15,
                        ]
                    ),
                    ShuttleRouteItemView.Route(
                        color: .white,
                        stops: [
                            "shuttle.stop.dormitory.out",
                            "shuttle.stop.terminal",
                            "shuttle.stop.shuttlecock.in",
                        ],
                        currentStopIndex: 1,
                        labels: [
                            "shuttle.stop.dormitory.out": -15,
                            "shuttle.stop.terminal": 0,
                            "shuttle.stop.shuttlecock.in": 10,
                        ]
                    )
                ],
                labels: [
                    String.LocalizationValue("shuttle.type.dormitory"),
                    String.LocalizationValue("shuttle.type.shuttlecock"),
                ]
            )
        }
        else if (stop == .jungangStation) {
           return ShuttleRouteAdapter(
               routes: [
                   ShuttleRouteItemView.Route(
                       color: .white,
                       stops: [
                           "shuttle.stop.dormitory.out",
                           "shuttle.stop.jungang.station",
                           "shuttle.stop.shuttlecock.in",
                           "shuttle.stop.dormitory.in",
                       ],
                       currentStopIndex: 1,
                       labels: [
                           "shuttle.stop.dormitory.out": -15,
                           "shuttle.stop.jungang.station": 0,
                           "shuttle.stop.shuttlecock.in": 10,
                           "shuttle.stop.dormitory.in": 15,
                       ]
                   ),
               ],
               labels: [
                   String.LocalizationValue("shuttle.type.dormitory"),
               ]
           )
        } else if (stop == .shuttlecockIn) {
            return ShuttleRouteAdapter(
                routes: [
                    ShuttleRouteItemView.Route(
                        color: .white,
                        stops: [
                            "shuttle.stop.dormitory.out",
                            "shuttle.stop.shuttlecock.in",
                            "shuttle.stop.dormitory.in",
                        ],
                        currentStopIndex: 1,
                        labels: [
                            "shuttle.stop.dormitory.out": -25,
                            "shuttle.stop.shuttlecock.in": 0,
                            "shuttle.stop.dormitory.in": 5,
                        ]
                    ),
                ],
                labels: [
                    String.LocalizationValue("shuttle.type.dormitory"),
                ]
            )
        }
        return ShuttleRouteAdapter(routes: [], labels: [])
    }
    
    func collapse() {
        guard isExpanded, let routeAdapter = routeAdapter else { return }
        isExpanded = false
        routeAdapter.isHidden = true
        onToggle?(false)
    }
    
    @objc private func toggleRouteAdapter() {
        AnalyticsManager.logSelect(.shuttleRouteToggle)
        guard let routeAdapter = self.routeAdapter else { return }
        isExpanded.toggle()
        routeAdapter.isHidden = !self.isExpanded
        onToggle?(isExpanded)
        if let tableView = self.superview as? UITableView {
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }
}
