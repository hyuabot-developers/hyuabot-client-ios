import Api
import FirebaseMessaging
import RxSwift
import UIKit

class ReadingRoomCellView: UITableViewCell {
    static let reuseIdentifier = "ReadingRoomCellView"
    private var item: ReadingRoomPageQuery.Data.ReadingRoom?
    private var showSubscribeToastMessage: ((String) -> Void)?
    private var showUnsubscribeToastMessage: ((String) -> Void)?
    private let nameLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.numberOfLines = 1
    }

    lazy var alarmButton = UIButton().then {
        $0.setImage(UIImage(systemName: "bell"), for: .normal)
        $0.tintColor = .plainButtonText
        $0.addTarget(self, action: #selector(alarmButtonTapped), for: .touchUpInside)
    }

    private let seatLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.numberOfLines = 1
    }

    private let occupancyProgressView = UIProgressView(progressViewStyle: .bar).then {
        $0.trackTintColor = .separator.withAlphaComponent(0.35)
        $0.progressTintColor = .systemGreen
        $0.layer.cornerRadius = 2
        $0.clipsToBounds = true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        selectionStyle = .none
        contentView.addSubview(nameLabel)
        contentView.addSubview(alarmButton)
        contentView.addSubview(seatLabel)
        contentView.addSubview(occupancyProgressView)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(12)
            make.trailing.lessThanOrEqualTo(self.seatLabel.snp.leading).offset(-10)
        }
        alarmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(self.nameLabel)
            make.width.height.equalTo(32)
        }
        seatLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self.alarmButton.snp.leading).offset(-10)
            make.centerY.equalTo(self.nameLabel)
        }
        occupancyProgressView.snp.makeConstraints { make in
            make.top.equalTo(self.nameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(4)
        }
    }

    func setupUI(
        item: ReadingRoomPageQuery.Data.ReadingRoom,
        showSubscribeToastMessage: @escaping (String) -> Void,
        showUnsubscribeToastMessage: @escaping (String) -> Void
    ) {
        self.item = item
        self.showSubscribeToastMessage = showSubscribeToastMessage
        self.showUnsubscribeToastMessage = showUnsubscribeToastMessage
        nameLabel.text = getLocalizedString(readingRoomID: item.seq)
        seatLabel.text = "\(item.seats.available) / \(item.seats.active)"
        let progress = ReadingRoomDisplayLogic.occupancyRatio(occupied: item.seats.occupied, active: item.seats.active)
        occupancyProgressView.setProgress(progress, animated: false)
        occupancyProgressView.progressTintColor = ReadingRoomDisplayLogic.occupancyColor(progress: progress)
        let itemKey = "reading_room_\(item.seq)"
        let notifiedRooms = UserDefaults.standard.stringArray(forKey: "readingRoomNotificationArray") ?? []
        if notifiedRooms.contains(itemKey) {
            alarmButton.setImage(UIImage(systemName: "bell.fill"), for: .normal)
        } else {
            alarmButton.setImage(UIImage(systemName: "bell"), for: .normal)
        }
    }

    private func getLocalizedString(readingRoomID: Int) -> String {
        String(localized: ReadingRoomDisplayLogic.localizationKey(for: readingRoomID))
    }

    @objc func alarmButtonTapped() {
        AnalyticsManager.logSelect(.readingRoomAlarmToggle, type: .toggle)
        guard let item else { return }
        guard let showSubscribeToastMessage else { return }
        guard let showUnsubscribeToastMessage else { return }
        let itemKey = "reading_room_\(item.seq)"
        let notifiedRooms = UserDefaults.standard.stringArray(forKey: "readingRoomNotificationArray") ?? []
        if notifiedRooms.contains(itemKey) {
            UserDefaults.standard.set(notifiedRooms.filter { $0 != itemKey }, forKey: "readingRoomNotificationArray")
            Messaging.messaging().unsubscribe(fromTopic: itemKey) { _ in
                showUnsubscribeToastMessage(self.getLocalizedString(readingRoomID: item.seq))
            }
            alarmButton.setImage(UIImage(systemName: "bell"), for: .normal)
        } else {
            var newNotifiedRooms = notifiedRooms
            newNotifiedRooms.append(itemKey)
            UserDefaults.standard.set(newNotifiedRooms, forKey: "readingRoomNotificationArray")
            Messaging.messaging().subscribe(toTopic: itemKey) { _ in
                showSubscribeToastMessage(self.getLocalizedString(readingRoomID: item.seq))
            }
            alarmButton.setImage(UIImage(systemName: "bell.fill"), for: .normal)
        }
    }
}
