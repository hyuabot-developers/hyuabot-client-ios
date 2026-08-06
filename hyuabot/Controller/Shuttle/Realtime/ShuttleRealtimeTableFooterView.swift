import UIKit

class ShuttleRealtimeTableFooterView: UIView {
    private let showStopModal: @MainActor (_ stop: ShuttleStopEnum) -> Void
    private let stopID: ShuttleStopEnum
    let showStopModalButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "shuttle.show.stop.modal"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }

    init(parentView: UIView, stopID: ShuttleStopEnum, showStopModal: @escaping @MainActor (_ stop: ShuttleStopEnum) -> Void) {
        self.showStopModal = showStopModal
        self.stopID = stopID
        super.init(frame: CGRect(x: 0, y: 0, width: parentView.frame.width, height: 90))
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        backgroundColor = .systemBackground
        addSubview(showStopModalButton)
        showStopModalButton.addTarget(self, action: #selector(showStopModalButtonTapped), for: .touchUpInside)
        showStopModalButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(40)
        }
    }

    @objc func showStopModalButtonTapped() {
        AnalyticsManager.logSelect(.shuttleShowStopModal)
        showStopModal(stopID)
    }
}
