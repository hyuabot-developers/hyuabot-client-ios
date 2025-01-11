import UIKit
import RxSwift

class ShuttleTimetableFilterVC: UIViewController {
    private let disposeBag = DisposeBag()
    private let availableStartStop: [String.LocalizationValue] = [
        "shuttle.stop.dormitory.out",
        "shuttle.stop.shuttlecock.out",
        "shuttle.stop.station",
        "shuttle.stop.terminal",
        "shuttle.stop.jungang.station",
        "shuttle.stop.shuttlecock.in"
    ]
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.timetable.filter")
    }
    private lazy var startStopButton: UIButton = UIButton().then {
        var conf = UIButton.Configuration.bordered()
        var title = AttributedString.init(String(localized: "shuttle.show.stop.modal"))
        title.font = .godo(size: 16, weight: .medium)
        title.foregroundColor = .label
        conf.attributedTitle = title
        $0.configuration = conf
        // Available start stops
        let items = self.availableStartStop.map { stop in
            UIAction(title: String(localized: stop), handler: { _ in
                self.selectStartStop(stop)
            })
        }
        let menu = UIMenu(title: "", children: items)
        $0.menu = menu
        $0.showsMenuAsPrimaryAction = true
    }
    private let endStopButton: UIButton = UIButton().then {
        var conf = UIButton.Configuration.bordered()
        var title = AttributedString.init(String(localized: "shuttle.show.stop.modal"))
        title.font = .godo(size: 16, weight: .medium)
        title.foregroundColor = .label
        conf.attributedTitle = title
        $0.configuration = conf
    }
    private lazy var routeSearchStackView: UIStackView = UIStackView().then {
        let arrowView = UILabel().then {
            $0.font = .godo(size: 16, weight: .medium)
            $0.text = "→"
            $0.textAlignment = .center
        }
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.alignment = .center
        $0.addArrangedSubview(startStopButton)
        $0.addArrangedSubview(arrowView)
        $0.addArrangedSubview(endStopButton)
    }
    private lazy var contentView = UIStackView().then {
        let routeFilterTitle = UILabel().then {
            $0.font = .godo(size: 16, weight: .bold)
            $0.text = String(localized: "shuttle.timetable.filter.route")
        }
        $0.backgroundColor = .systemBackground
        $0.axis = .vertical
        $0.alignment = .fill
        $0.distribution = .fill
        $0.spacing = 20
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        $0.addArrangedSubview(routeFilterTitle)
        $0.addArrangedSubview(routeSearchStackView)
        $0.addArrangedSubview(UIView())
    }
    private var selectedStartStop: String.LocalizationValue? = nil
    private var selectedEndStop: String.LocalizationValue? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.contentView)
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.contentView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    private func observeSubjects() {
        ShuttleTimetableData.shared.options.subscribe(onNext: { options in
            guard let options = options else { return }
            // Set the title of the start and end stop buttons
            self.selectStartStop(options.start)
            self.setEndStopTitle(options.end)
            // Set the selected value
            self.selectedStartStop = options.start
            self.selectedEndStop = options.end
        }).disposed(by: disposeBag)
    }
    
    private func setStartStopTitle(_ title: String.LocalizationValue) {
        var startStopConfig = self.startStopButton.configuration
        var startStopTitle = AttributedString.init(String(localized: title))
        startStopTitle.font = .godo(size: 16, weight: .medium)
        startStopTitle.foregroundColor = .label
        startStopConfig?.attributedTitle = startStopTitle
        self.startStopButton.configuration = startStopConfig
    }
    
    private func setEndStopTitle(_ title: String.LocalizationValue) {
        var endStopConfig = self.endStopButton.configuration
        var endStopTitle = AttributedString.init(String(localized: title))
        endStopTitle.font = .godo(size: 16, weight: .medium)
        endStopTitle.foregroundColor = .label
        endStopConfig?.attributedTitle = endStopTitle
        self.endStopButton.configuration = endStopConfig
    }
    
    private func selectStartStop(_ stop: String.LocalizationValue) {
        self.setStartStopTitle(stop)
        self.selectedStartStop = stop
        if stop == "shuttle.stop.dormitory.out" || stop == "shuttle.stop.shuttlecock.out" {
            self.setEndStopTitle("shuttle.destination.shorten.station")
            self.selectedEndStop = "shuttle.destination.shorten.station"
            let availableEndStops: [String.LocalizationValue] = [
                "shuttle.destination.shorten.station",
                "shuttle.destination.shorten.terminal",
                "shuttle.destination.shorten.jungang_station"
            ]
            let items = availableEndStops.map { stop in
                UIAction(title: String(localized: stop), handler: { _ in
                    self.setEndStopTitle(stop)
                    self.selectedEndStop = stop
                })
            }
            let menu = UIMenu(title: "", children: items)
            self.endStopButton.menu = menu
            self.endStopButton.showsMenuAsPrimaryAction = true
        } else if stop == "shuttle.stop.station" {
            self.setEndStopTitle("shuttle.destination.shorten.campus")
            self.selectedEndStop = "shuttle.destination.shorten.campus"
            let availableEndStops: [String.LocalizationValue] = [
                "shuttle.destination.shorten.campus",
                "shuttle.destination.shorten.terminal",
                "shuttle.destination.shorten.jungang_station"
            ]
            let items = availableEndStops.map { stop in
                UIAction(title: String(localized: stop), handler: { _ in
                    self.setEndStopTitle(stop)
                    self.selectedEndStop = stop
                })
            }
            let menu = UIMenu(title: "", children: items)
            self.endStopButton.menu = menu
            self.endStopButton.showsMenuAsPrimaryAction = true
        } else {
            self.setEndStopTitle("shuttle.destination.shorten.campus")
            self.selectedEndStop = "shuttle.destination.shorten.campus"
            let menu = UIMenu(title: "", children: [
                UIAction(title: String(localized: "shuttle.destination.shorten.campus"), handler: { _ in
                    self.setEndStopTitle("shuttle.destination.shorten.campus")
                    self.selectedEndStop = "shuttle.destination.shorten.campus"
                })
            ])
            self.endStopButton.menu = menu
            self.endStopButton.showsMenuAsPrimaryAction = true
        }
    }
}
