import UIKit

class ShuttleRealtimeTableFooterView2: UIView {
    private let showStopModal: ((_ stop: ShuttleStopEnum) -> Void)
    private let stopID: ShuttleStopEnum
    private var showEntireTimetable: ((_ stop: ShuttleStopEnum, _ section: Int) -> Void)?
    private var section: Int?
    private let showEntireTimeTableButton1 = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "shuttle.show.entire.timetable.station"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }
    private let showEntireTimeTableButton2 = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "shuttle.show.entire.timetable.campus"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }
    private let showEntireTimeTableButton3 = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "shuttle.show.entire.timetable.terminal"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }
    private let showEntireTimeTableButton4 = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "shuttle.show.entire.timetable.jungang_stn"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }
    
    private let showStopModalButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "shuttle.show.stop.modal"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }
    
    init(parentView: UIView, stopID: ShuttleStopEnum, showStopModal: @escaping (_ stop: ShuttleStopEnum) -> Void, showEntireTimetable: @escaping (_ stop: ShuttleStopEnum, _ section: Int) -> Void) {
        self.showEntireTimetable = showEntireTimetable
        self.showStopModal = showStopModal
        self.stopID = stopID
        super.init(frame: CGRect(x: 0, y: 0, width: parentView.frame.width, height: 200))
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.showStopModalButton.addTarget(self, action: #selector(showStopModalButtonTapped), for: .touchUpInside)
        self.showEntireTimeTableButton1.addTarget(self, action: #selector(showEntireTimeTable(_:)), for: .touchUpInside)
        self.showEntireTimeTableButton2.addTarget(self, action: #selector(showEntireTimeTable(_:)), for: .touchUpInside)
        self.showEntireTimeTableButton3.addTarget(self, action: #selector(showEntireTimeTable(_:)), for: .touchUpInside)
        self.showEntireTimeTableButton4.addTarget(self, action: #selector(showEntireTimeTable(_:)), for: .touchUpInside)
        if (self.stopID == .dormiotryOut || self.stopID == .shuttlecockOut) {
            self.showEntireTimeTableButton2.isHidden = true
        } else if (self.stopID == .station) {
            self.showEntireTimeTableButton1.isHidden = true
        } else if (self.stopID == .terminal || self.stopID == .jungangStation || self.stopID == .shuttlecockIn) {
            self.showEntireTimeTableButton1.isHidden = true
            self.showEntireTimeTableButton3.isHidden = true
            self.showEntireTimeTableButton4.isHidden = true
        }
        self.showEntireTimeTableButton1.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        self.showEntireTimeTableButton2.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        self.showEntireTimeTableButton3.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        self.showEntireTimeTableButton4.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        self.showStopModalButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        let verticalView = UIStackView(arrangedSubviews: [showEntireTimeTableButton1, showEntireTimeTableButton2, showEntireTimeTableButton3, showEntireTimeTableButton4, showStopModalButton]).then {
            $0.axis = .vertical
            $0.spacing = 0
            $0.alignment = .fill
            
        }
        self.addSubview(verticalView)
        verticalView.snp.makeConstraints({ make in
            make.leading.top.trailing.equalToSuperview()
        })
    }
    
    @objc func showStopModalButtonTapped() {
        self.showStopModal(stopID)
    }
    
    
    @objc func showEntireTimeTable(_ sender: UIButton) {
        guard let showEntireTimetable = self.showEntireTimetable else { return }
        if (self.stopID == .dormiotryOut || self.stopID == .shuttlecockOut) {
            if (sender == self.showEntireTimeTableButton1) {
                showEntireTimetable(self.stopID, 0)
            } else if (sender == self.showEntireTimeTableButton3) {
                showEntireTimetable(self.stopID, 1)
            } else if (sender == self.showEntireTimeTableButton4) {
                showEntireTimetable(self.stopID, 2)
            }
        } else if (self.stopID == .station) {
            if (sender == self.showEntireTimeTableButton2) {
                showEntireTimetable(self.stopID, 0)
            } else if (sender == self.showEntireTimeTableButton3) {
                showEntireTimetable(self.stopID, 1)
            } else if (sender == self.showEntireTimeTableButton4) {
                showEntireTimetable(self.stopID, 2)
            }
        } else if (self.stopID == .terminal || self.stopID == .jungangStation || self.stopID == .shuttlecockIn) {
            showEntireTimetable(self.stopID, 0)
        }
    }
}
