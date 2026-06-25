import UIKit

class ShuttleRealtimeTableFooterView2: UIView {
    private let showStopModal: (_ stop: ShuttleStopEnum) -> Void
    private let stopID: ShuttleStopEnum
    private var showEntireTimetable: ((_ stop: ShuttleStopEnum, _ section: Int) -> Void)?
    private var section: Int?
    let showEntireTimeTableButton1 = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "shuttle.show.entire.timetable.station"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }

    private let showEntireTimeTableButton2 = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "shuttle.show.entire.timetable.campus"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }

    private let showEntireTimeTableButton3 = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "shuttle.show.entire.timetable.terminal"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }

    private let showEntireTimeTableButton4 = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "shuttle.show.entire.timetable.jungang_stn"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }

    let showStopModalButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "shuttle.show.stop.modal"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }

    init(
        parentView: UIView,
        stopID: ShuttleStopEnum,
        showStopModal: @escaping (_ stop: ShuttleStopEnum) -> Void,
        showEntireTimetable: @escaping (_ stop: ShuttleStopEnum, _ section: Int) -> Void
    ) {
        self.showEntireTimetable = showEntireTimetable
        self.showStopModal = showStopModal
        self.stopID = stopID
        let visibleButtonCount = if stopID == .terminal || stopID == .jungangStation || stopID == .shuttlecockIn {
            2
        } else {
            4
        }
        super.init(frame: CGRect(x: 0, y: 0, width: parentView.frame.width, height: CGFloat(visibleButtonCount * 50)))
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        showStopModalButton.addTarget(self, action: #selector(showStopModalButtonTapped), for: .touchUpInside)
        showEntireTimeTableButton1.addTarget(self, action: #selector(showEntireTimeTable(_:)), for: .touchUpInside)
        showEntireTimeTableButton2.addTarget(self, action: #selector(showEntireTimeTable(_:)), for: .touchUpInside)
        showEntireTimeTableButton3.addTarget(self, action: #selector(showEntireTimeTable(_:)), for: .touchUpInside)
        showEntireTimeTableButton4.addTarget(self, action: #selector(showEntireTimeTable(_:)), for: .touchUpInside)
        if stopID == .dormiotryOut || stopID == .shuttlecockOut {
            showEntireTimeTableButton2.isHidden = true
        } else if stopID == .station {
            showEntireTimeTableButton1.isHidden = true
        } else if stopID == .terminal || stopID == .jungangStation || stopID == .shuttlecockIn {
            showEntireTimeTableButton1.isHidden = true
            showEntireTimeTableButton3.isHidden = true
            showEntireTimeTableButton4.isHidden = true
        }
        showEntireTimeTableButton1.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        showEntireTimeTableButton2.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        showEntireTimeTableButton3.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        showEntireTimeTableButton4.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        showStopModalButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        let verticalView = UIStackView(arrangedSubviews: [
            showEntireTimeTableButton1,
            showEntireTimeTableButton2,
            showEntireTimeTableButton3,
            showEntireTimeTableButton4,
            showStopModalButton
        ]).then {
            $0.axis = .vertical
            $0.spacing = 0
            $0.alignment = .fill
        }
        addSubview(verticalView)
        verticalView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }
    }

    @objc func showStopModalButtonTapped() {
        AnalyticsManager.logSelect(.shuttleShowStopModal)
        showStopModal(stopID)
    }

    @objc func showEntireTimeTable(_ sender: UIButton) {
        AnalyticsManager.logSelect(.shuttleShowEntireTimetable)
        guard let showEntireTimetable else { return }
        if stopID == .dormiotryOut || stopID == .shuttlecockOut {
            if sender == showEntireTimeTableButton1 {
                showEntireTimetable(stopID, 0)
            } else if sender == showEntireTimeTableButton3 {
                showEntireTimetable(stopID, 1)
            } else if sender == showEntireTimeTableButton4 {
                showEntireTimetable(stopID, 2)
            }
        } else if stopID == .station {
            if sender == showEntireTimeTableButton2 {
                showEntireTimetable(stopID, 0)
            } else if sender == showEntireTimeTableButton3 {
                showEntireTimetable(stopID, 1)
            } else if sender == showEntireTimeTableButton4 {
                showEntireTimetable(stopID, 2)
            }
        } else if stopID == .terminal || stopID == .jungangStation || stopID == .shuttlecockIn {
            showEntireTimetable(stopID, 0)
        }
    }
}
