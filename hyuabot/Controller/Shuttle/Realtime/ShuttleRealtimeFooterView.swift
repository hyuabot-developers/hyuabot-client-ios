import SnapKit
import Then
import UIKit

private final class ExtendedHitAreaButton: UIButton {
    var minimumHitArea = CGSize(width: 44, height: 44)

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let widthInset = min(0, bounds.width - minimumHitArea.width) / 2
        let heightInset = min(0, bounds.height - minimumHitArea.height) / 2
        return bounds.insetBy(dx: widthInset, dy: heightInset).contains(point)
    }
}

class ShuttleRealtimeFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ShuttleRealtimeFooterView"
    static let timetableButtonHeight: CGFloat = 50
    static let connectorSpacing: CGFloat = 8
    private var showEntireTimetable: ((_ stop: ShuttleStopEnum, _ section: Int) -> Void)?
    private var showBusAlternativeStop: ((_ alternative: ShuttleBusAlternativeDisplayData) -> Void)?
    private var stopID: ShuttleStopEnum?
    private var section: Int?
    private var alternatives: [ShuttleBusAlternativeDisplayData] = []
    private weak var transferView: ShuttleTransferInfoView?
    private var transferConnectorView: TransferConnectorView?

    private let transferContainer = UIView()
    let busAlternativeContainer = UIView()
    private let transferConnectorSpacer = UIView()
    private let busAlternativeStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.alignment = .fill
    }

    let showEntireTimeTableButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "shuttle.show.entire.timetable"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView().then {
            $0.backgroundColor = .systemBackground
        }
        contentView.backgroundColor = .systemBackground
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.clipsToBounds = false
        transferContainer.backgroundColor = .systemBackground
        busAlternativeContainer.backgroundColor = .systemBackground
        busAlternativeContainer.addSubview(busAlternativeStackView)
        busAlternativeStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        showEntireTimeTableButton.snp.makeConstraints { make in
            make.height.equalTo(Self.timetableButtonHeight)
        }
        transferConnectorSpacer.snp.makeConstraints { make in
            make.height.equalTo(Self.connectorSpacing)
        }

        let stackView = UIStackView(arrangedSubviews: [
            busAlternativeContainer,
            transferConnectorSpacer,
            transferContainer,
            showEntireTimeTableButton
        ]).then {
            $0.axis = .vertical
            $0.spacing = 0
            $0.alignment = .fill
        }
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        showEntireTimeTableButton.addTarget(self, action: #selector(showEntireTimeTable), for: .touchUpInside)
        transferContainer.isHidden = true
        busAlternativeContainer.isHidden = true
        transferConnectorSpacer.isHidden = true
    }

    func setupUI(
        stopID: ShuttleStopEnum,
        section: Int,
        transferView: ShuttleTransferInfoView?,
        busAlternatives: [ShuttleBusAlternativeDisplayData],
        forceShow: Bool = false,
        showEntireTimetable: @escaping (_ stop: ShuttleStopEnum, _ section: Int) -> Void,
        showBusAlternativeStop: @escaping (_ alternative: ShuttleBusAlternativeDisplayData) -> Void
    ) {
        self.stopID = stopID
        self.section = section
        self.showEntireTimetable = showEntireTimetable
        self.showBusAlternativeStop = showBusAlternativeStop
        setTransferView(transferView)

        let alternatives = forceShow && busAlternatives.isEmpty
            ? [ShuttleBusAlternativeDisplayData(
                routeName: String(localized: String
                    .LocalizationValue(stopID == .station ? "shuttle.bus.alternative.route.campus" : "shuttle.bus.alternative.route")),
                minutes: nil,
                color: .busGreen,
                busStopName: "",
                busStopLatitude: 0,
                busStopLongitude: 0
            )]
            : busAlternatives
        if self.stopID == stopID,
           self.section == section,
           self.alternatives == alternatives,
           busAlternativeContainer.isHidden == alternatives.isEmpty
        {
            return
        }

        for arrangedSubview in busAlternativeStackView.arrangedSubviews {
            busAlternativeStackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        self.alternatives = alternatives

        guard !alternatives.isEmpty else {
            busAlternativeContainer.isHidden = true
            return
        }

        for (index, alternative) in alternatives.enumerated() {
            let row = makeAlternativeRow(alternative: alternative, index: index)
            busAlternativeStackView.addArrangedSubview(row)
            row.snp.makeConstraints { make in
                make.height.equalTo(ShuttleRealtimeCellView.informationRowHeight)
            }
        }
        busAlternativeContainer.isHidden = false
    }

    private func setTransferView(_ transferView: ShuttleTransferInfoView?) {
        updateTransferConnector(transferView)
        if self.transferView === transferView, transferView?.superview === transferContainer {
            transferContainer.isHidden = transferView?.preferredHeight == 0
            return
        }
        transferContainer.subviews.forEach { $0.removeFromSuperview() }
        self.transferView = transferView
        guard let transferView, transferView.preferredHeight > 0 else {
            transferContainer.isHidden = true
            return
        }
        transferContainer.addSubview(transferView)
        transferView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        transferContainer.isHidden = false
    }

    private func updateTransferConnector(_ transferView: ShuttleTransferInfoView?) {
        transferConnectorView?.removeFromSuperview()
        transferConnectorView = nil
        guard let title = transferView?.inlineConnectorTitle,
              let tintColor = transferView?.inlineConnectorTintColor
        else {
            transferConnectorSpacer.isHidden = true
            return
        }
        transferConnectorSpacer.isHidden = false
        let connector = TransferConnectorView(title: title, tintColor: tintColor)
        contentView.addSubview(connector)
        connector.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.centerX.equalToSuperview()
            make.centerY.equalTo(transferContainer.snp.top).offset(-Self.connectorSpacing / 2)
        }
        transferConnectorView = connector
    }

    private func makeAlternativeRow(alternative: ShuttleBusAlternativeDisplayData, index: Int) -> UIView {
        let row = UIView()
        row.backgroundColor = .systemBackground
        let accent = UIView().then {
            $0.backgroundColor = alternative.color
        }
        let route = UILabel().then {
            $0.font = .godo(size: 16, weight: .bold)
            $0.textColor = alternative.color
            $0.text = alternative.routeName
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.75
        }
        let time = UILabel().then {
            $0.font = .godo(size: 16, weight: .medium)
            $0.textAlignment = .right
            if let minutes = alternative.minutes {
                $0.text = String(format: String(localized: "shuttle.bus.alternative.time.%lld"), minutes)
            } else {
                $0.text = String(localized: "shuttle.bus.alternative.no.data")
            }
        }
        let infoButton = ExtendedHitAreaButton(type: .system).then {
            $0.tag = index
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
            $0.setImage(UIImage(systemName: "info.circle", withConfiguration: symbolConfiguration), for: .normal)
            $0.tintColor = alternative.color
            $0.accessibilityLabel = String(localized: "coach.shuttle.footer.title")
            $0.addTarget(self, action: #selector(showAlternativeStop(_:)), for: .touchUpInside)
            let hasStopInfo = alternative.busStopLatitude != 0 && alternative.busStopLongitude != 0
            $0.isEnabled = hasStopInfo
            $0.alpha = hasStopInfo ? 1 : 0.38
        }

        row.addSubview(accent)
        row.addSubview(route)
        row.addSubview(time)
        row.addSubview(infoButton)
        accent.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(4)
        }
        route.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        time.snp.makeConstraints { make in
            make.trailing.equalTo(infoButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(route.snp.trailing).offset(8)
        }
        return row
    }

    @objc private func showAlternativeStop(_ sender: UIButton) {
        guard alternatives.indices.contains(sender.tag) else { return }
        showBusAlternativeStop?(alternatives[sender.tag])
    }

    @objc func showEntireTimeTable() {
        AnalyticsManager.logSelect(.shuttleShowEntireTimetable)
        guard let stopID, let section else { return }
        showEntireTimetable?(stopID, section)
    }
}
