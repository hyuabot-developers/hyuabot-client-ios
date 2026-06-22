import UIKit
import Api
import RxSwift
import FirebaseMessaging

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
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.selectionStyle = .none
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.alarmButton)
        self.contentView.addSubview(self.seatLabel)
        self.contentView.addSubview(self.occupancyProgressView)
        self.nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(12)
            make.trailing.lessThanOrEqualTo(self.seatLabel.snp.leading).offset(-10)
        }
        self.alarmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(self.nameLabel)
            make.width.height.equalTo(32)
        }
        self.seatLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self.alarmButton.snp.leading).offset(-10)
            make.centerY.equalTo(self.nameLabel)
        }
        self.occupancyProgressView.snp.makeConstraints { make in
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
        self.nameLabel.text = getLocalizedString(readingRoomID: item.seq)
        self.seatLabel.text = "\(item.seats.available) / \(item.seats.active)"
        let progress = item.seats.active > 0 ? Float(item.seats.occupied) / Float(item.seats.active) : 0
        self.occupancyProgressView.setProgress(progress, animated: false)
        self.occupancyProgressView.progressTintColor = occupancyColor(progress: progress)
        let itemKey = "reading_room_\(item.seq)"
        let notifiedRooms = UserDefaults.standard.stringArray(forKey: "readingRoomNotificationArray") ?? []
        if (notifiedRooms.contains(itemKey)) {
            self.alarmButton.setImage(UIImage(systemName: "bell.fill"), for: .normal)
        } else {
            self.alarmButton.setImage(UIImage(systemName: "bell"), for: .normal)
        }
    }

    private func occupancyColor(progress: Float) -> UIColor {
        if progress >= 0.9 { return .systemRed }
        if progress >= 0.7 { return .systemOrange }
        return .systemGreen
    }
    
    private func getLocalizedString(readingRoomID: Int) -> String {
        var readingRoomName: String.LocalizationValue
        switch readingRoomID {
            case 1: readingRoomName = "reading_room_1"
            case 53: readingRoomName = "reading_room_53"
            case 54: readingRoomName = "reading_room_54"
            case 55: readingRoomName = "reading_room_55"
            case 56: readingRoomName = "reading_room_56"
            case 61: readingRoomName = "reading_room_61"
            case 63: readingRoomName = "reading_room_63"
            case 131: readingRoomName = "reading_room_131"
            case 132: readingRoomName = "reading_room_132"
            default: readingRoomName = "Unknown"
        }
        return String(localized: readingRoomName)
    }
    
    @objc func alarmButtonTapped() {
        AnalyticsManager.logSelect(.readingRoomAlarmToggle, type: .toggle)
        guard let item = self.item else { return }
        guard let showSubscribeToastMessage = self.showSubscribeToastMessage else { return }
        guard let showUnsubscribeToastMessage = self.showUnsubscribeToastMessage else { return }
        let itemKey = "reading_room_\(item.seq)"
        let notifiedRooms = UserDefaults.standard.stringArray(forKey: "readingRoomNotificationArray") ?? []
        if (notifiedRooms.contains(itemKey)) {
            UserDefaults.standard.set(notifiedRooms.filter { $0 != itemKey }, forKey: "readingRoomNotificationArray")
            Messaging.messaging().unsubscribe(fromTopic: itemKey) { error in
                showUnsubscribeToastMessage(self.getLocalizedString(readingRoomID: item.seq))
            }
            self.alarmButton.setImage(UIImage(systemName: "bell"), for: .normal)
        } else {
            var newNotifiedRooms = notifiedRooms
            newNotifiedRooms.append(itemKey)
            UserDefaults.standard.set(newNotifiedRooms, forKey: "readingRoomNotificationArray")
            Messaging.messaging().subscribe(toTopic: itemKey) { error in
                showSubscribeToastMessage(self.getLocalizedString(readingRoomID: item.seq))
            }
            self.alarmButton.setImage(UIImage(systemName: "bell.fill"), for: .normal)
        }
    }
}
