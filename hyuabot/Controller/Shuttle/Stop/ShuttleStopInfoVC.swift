import UIKit
import QueryAPI

class ShuttleStopInfoVC: UIViewController {
    private let stop: ShuttleStopEnum
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
    }
    
    private lazy var contentView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.backgroundColor = .systemBackground
    }
    
    init(stop: ShuttleStopEnum) {
        self.stop = stop
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.contentView)
        if self.stop == .dormiotryOut {
            self.titleLabel.text = String(localized: "shuttle.stop.dormitory.out")
        } else if self.stop == .shuttlecockOut {
            self.titleLabel.text = String(localized: "shuttle.stop.shuttlecock.out")
        } else if self.stop == .station {
            self.titleLabel.text = String(localized: "shuttle.stop.station")
        } else if self.stop == .terminal {
            self.titleLabel.text = String(localized: "shuttle.stop.terminal")
        } else if self.stop == .jungangStation {
            self.titleLabel.text = String(localized: "shuttle.stop.jungang.station")
        } else if self.stop == .shuttlecockIn {
            self.titleLabel.text = String(localized: "shuttle.stop.shuttlecock.in")
        } else {
            self.titleLabel.text = String(localized: "shuttle.stop.dormitory.out")
        }
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.contentView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}
