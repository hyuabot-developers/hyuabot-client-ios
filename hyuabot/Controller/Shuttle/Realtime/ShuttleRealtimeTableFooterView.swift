import UIKit

class ShuttleRealtimeTableFooterView: UIView {
    private let showStopModal: ((_ stop: ShuttleStopEnum) -> Void)
    private let stopID: ShuttleStopEnum
    private let showStopModalButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "shuttle.show.stop.modal"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }
    
    init(parentView: UIView, stopID: ShuttleStopEnum, showStopModal: @escaping (_ stop: ShuttleStopEnum) -> Void) {
        self.showStopModal = showStopModal
        self.stopID = stopID
        super.init(frame: CGRect(x: 0, y: 0, width: parentView.frame.width, height: 90))
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.addSubview(showStopModalButton)
        self.showStopModalButton.addTarget(self, action: #selector(showStopModalButtonTapped), for: .touchUpInside)
        self.showStopModalButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    @objc func showStopModalButtonTapped() {
        self.showStopModal(stopID)
    }
}
