//
//  InquiryChatVC.swift
//  hyuabot
//

import MapKit
import SnapKit
import UIKit

final class InquiryChatVC: UIViewController {
    private static let officeCoordinate = CLLocationCoordinate2D(
        latitude: 37.29275316695924,
        longitude: 126.83714484865253
    )

    private struct MessageSection {
        let date: Date
        var messages: [InquiryMessageDTO]
    }

    private var thread: InquiryThreadDTO?
    private var messages: [InquiryMessageDTO] = []
    private var lastAdminMessageId = 0
    private var hasLoaded = false
    private var didReportFailure = false
    private var noticeDismissed = false
    private var pollingTimer: Timer?
    private var streamTask: Task<Void, Never>?
    private let entryScreen: String
    private let entryScreenName: String

    init(entryScreen: String = "campus", entryScreenName: String? = nil) {
        self.entryScreen = entryScreen
        self.entryScreenName = entryScreenName ?? String(localized: "tabbar.campus")
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var messageSections: [MessageSection] {
        var sections: [MessageSection] = []
        for message in messages {
            let date = Self.messageDate(from: message.createdAt) ?? Date.distantPast
            if let last = sections.indices.last {
                if Calendar.current.isDate(sections[last].date, inSameDayAs: date) {
                    sections[last].messages.append(message)
                } else {
                    sections.append(MessageSection(date: date, messages: [message]))
                }
            } else {
                sections.append(MessageSection(date: date, messages: [message]))
            }
        }
        return sections
    }

    private let tableView = UITableView().then {
        $0.separatorStyle = .none
        $0.backgroundColor = .systemGroupedBackground
        $0.keyboardDismissMode = .interactive
        $0.allowsSelection = false
        $0.accessibilityIdentifier = "inquiry.table"
        $0.register(InquiryMessageCellView.self, forCellReuseIdentifier: InquiryMessageCellView.reuseIdentifier)
    }

    private let emptyLabel = UILabel().then {
        $0.text = String(localized: "inquiry.empty")
        $0.font = .godo(size: 15, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.isHidden = true
    }

    private let conversationStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 8
    }

    private let noticeContainer = UIView()

    private let noticeCard = UIView().then {
        $0.backgroundColor = .secondarySystemGroupedBackground
        $0.layer.cornerRadius = 16
        $0.layer.cornerCurve = .continuous
    }

    private let noticeTitleLabel = UILabel().then {
        $0.text = String(localized: "inquiry.shuttleLost.title")
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    private let noticeDetailLabel = UILabel().then {
        $0.text = String(localized: "inquiry.shuttleLost.detail")
        $0.font = .godo(size: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

    private let noticeCloseButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .secondaryLabel
        $0.accessibilityLabel = String(localized: "inquiry.shuttleLost.close")
        $0.accessibilityIdentifier = "inquiry.shuttle_lost.dismiss"
    }

    private let officeMapView = MKMapView().then {
        $0.isZoomEnabled = false
        $0.isScrollEnabled = false
        $0.isPitchEnabled = false
        $0.isRotateEnabled = false
        $0.isUserInteractionEnabled = false
        $0.layer.cornerRadius = 10
        $0.layer.cornerCurve = .continuous
        $0.clipsToBounds = true
        $0.accessibilityIdentifier = "inquiry.shuttle_lost.map_preview"
    }

    private let officeMapButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = String(localized: "inquiry.shuttleLost.map")
        configuration.baseForegroundColor = .hanyangBlue
        $0.configuration = configuration
        $0.accessibilityIdentifier = "inquiry.shuttle_lost.open_map"
    }

    private let officeCallButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.filled()
        configuration.title = String(localized: "inquiry.shuttleLost.call")
        configuration.baseBackgroundColor = .hanyangBlue
        $0.configuration = configuration
        $0.accessibilityIdentifier = "inquiry.shuttle_lost.call"
    }

    private let inputContainer = UIView().then {
        $0.backgroundColor = .secondarySystemGroupedBackground
    }

    private let inputField = UITextField().then {
        $0.placeholder = String(localized: "inquiry.input.placeholder")
        $0.font = .godo(size: 15, weight: .regular)
        $0.borderStyle = .roundedRect
        $0.returnKeyType = .send
        $0.accessibilityIdentifier = "inquiry.input"
    }

    private let sendButton = UIButton(type: .system).then {
        $0.setTitle(String(localized: "inquiry.send"), for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .godo(size: 15, weight: .bold)
        $0.backgroundColor = .systemBlue
        $0.layer.cornerRadius = 24
        $0.layer.cornerCurve = .continuous
        $0.accessibilityIdentifier = "inquiry.send_button"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "inquiry.title")
        view.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        inputField.delegate = self
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        noticeCloseButton.addTarget(self, action: #selector(dismissNotice), for: .touchUpInside)
        officeMapButton.addTarget(self, action: #selector(openOfficeMap), for: .touchUpInside)
        officeCallButton.addTarget(self, action: #selector(callOffice), for: .touchUpInside)
        configureLayout()
        configureOfficeMap()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        loadInitialIfNeeded()
        startPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPolling()
        streamTask?.cancel()
        streamTask = nil
    }

    private func configureLayout() {
        view.addSubview(conversationStack)
        view.addSubview(inputContainer)
        view.addSubview(emptyLabel)
        conversationStack.addArrangedSubview(noticeContainer)
        conversationStack.addArrangedSubview(tableView)
        noticeContainer.addSubview(noticeCard)
        noticeCard.addSubview(noticeTitleLabel)
        noticeCard.addSubview(noticeDetailLabel)
        noticeCard.addSubview(noticeCloseButton)
        noticeCard.addSubview(officeMapView)
        let actionRow = UIStackView(arrangedSubviews: [officeMapButton, officeCallButton])
        actionRow.axis = .horizontal
        actionRow.distribution = .fillEqually
        actionRow.spacing = 8
        noticeCard.addSubview(actionRow)
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)

        noticeCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        noticeTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().inset(12)
            make.trailing.equalTo(noticeCloseButton.snp.leading).offset(-8)
        }
        noticeCloseButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(4)
            make.width.height.equalTo(44)
        }
        noticeDetailLabel.snp.makeConstraints { make in
            make.top.equalTo(noticeCloseButton.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        officeMapView.snp.makeConstraints { make in
            make.top.equalTo(noticeDetailLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(88)
        }
        actionRow.snp.makeConstraints { make in
            make.top.equalTo(officeMapView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(44)
        }

        inputContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        inputField.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
            make.height.equalTo(48)
        }
        sendButton.snp.makeConstraints { make in
            make.leading.equalTo(inputField.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(inputField)
            make.width.equalTo(64)
            make.height.equalTo(inputField)
        }
        conversationStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputContainer.snp.top)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.leading.trailing.equalTo(tableView).inset(40)
        }
    }

    private func configureOfficeMap() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = Self.officeCoordinate
        annotation.title = String(localized: "inquiry.shuttleLost.office")
        officeMapView.addAnnotation(annotation)
        officeMapView.setRegion(
            MKCoordinateRegion(
                center: Self.officeCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.0012, longitudeDelta: 0.0012)
            ),
            animated: false
        )
    }

    @objc
    private func dismissNotice() {
        noticeDismissed = true
        noticeContainer.isHidden = true
    }

    @objc
    private func openOfficeMap() {
        let office = MKMapItem(placemark: MKPlacemark(coordinate: Self.officeCoordinate))
        office.name = String(localized: "inquiry.shuttleLost.office")
        office.openInMaps()
    }

    @objc
    private func callOffice() {
        guard let url = URL(string: "tel:0314004412") else { return }
        UIApplication.shared.open(url)
    }

    private func loadInitialIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        Task { [weak self] in
            guard let self else { return }
            let resolved = await InquiryService.shared.openThread(
                subject: nil,
                entryScreen: entryScreen,
                entryScreenName: entryScreenName
            )
            await setThread(resolved)
        }
    }

    @MainActor
    private func setThread(_ resolved: InquiryThreadDTO?) async {
        guard let resolved else {
            reportFailure()
            return
        }
        thread = resolved
        await refreshMessages(scrollToBottom: true)
        startStream(threadId: resolved.id)
    }

    private func startStream(threadId: String) {
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            while !Task.isCancelled {
                await InquiryService.shared.streamEvents { [weak self] event in
                    guard event.threadId == threadId else { return }
                    await self?.refreshMessages(scrollToBottom: true)
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refreshMessages(scrollToBottom: false) }
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    @MainActor
    private func refreshMessages(scrollToBottom: Bool) async {
        guard let thread else { return }
        let fetched = await InquiryService.shared.messages(threadId: thread.id, after: nil)
        apply(fetched, scrollToBottom: scrollToBottom, threadId: thread.id)
    }

    @MainActor
    private func apply(_ fetched: [InquiryMessageDTO], scrollToBottom: Bool, threadId: String) {
        let maxAdminId = fetched.filter { $0.senderType == "ADMIN" }.map(\.id).max() ?? 0
        let hasNewAdmin = maxAdminId > lastAdminMessageId
        lastAdminMessageId = max(lastAdminMessageId, maxAdminId)
        messages = fetched
        emptyLabel.isHidden = !fetched.isEmpty
        tableView.reloadData()
        if scrollToBottom || hasNewAdmin {
            scrollToLastRow()
        }
        if hasNewAdmin {
            Task { await InquiryService.shared.markRead(threadId: threadId) }
        }
    }

    private func scrollToLastRow() {
        guard let lastSection = messageSections.indices.last,
              let lastRow = messageSections[lastSection].messages.indices.last else { return }
        let indexPath = IndexPath(row: lastRow, section: lastSection)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    private static func messageDate(from raw: String) -> Date? {
        ISO8601DateFormatter().date(from: String(raw.split(separator: "[", maxSplits: 1).first ?? ""))
    }

    private static func sectionTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
    }

    private func reportFailure() {
        guard !didReportFailure else { return }
        didReportFailure = true
        showToastMessage(
            image: UIImage(systemName: "exclamationmark.triangle.fill"),
            message: String(localized: "inquiry.loadFailed")
        )
    }

    @objc
    private func handleSend() {
        let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty, let thread else { return }
        inputField.text = ""
        Task { [weak self] in
            guard let self else { return }
            _ = await InquiryService.shared.send(threadId: thread.id, body: text)
            await refreshMessages(scrollToBottom: true)
        }
    }
}

extension InquiryChatVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        messageSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messageSections[section].messages.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = Self.sectionTitle(for: messageSections[section].date)
        label.font = .godo(size: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center

        let header = UIView()
        header.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard messageSections.indices.contains(indexPath.section),
              messageSections[indexPath.section].messages.indices.contains(indexPath.row),
              let cell = tableView.dequeueReusableCell(
                  withIdentifier: InquiryMessageCellView.reuseIdentifier,
                  for: indexPath
              ) as? InquiryMessageCellView
        else { return UITableViewCell() }
        cell.configure(with: messageSections[indexPath.section].messages[indexPath.row])
        return cell
    }
}

extension InquiryChatVC: UITableViewDelegate {}

extension InquiryChatVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        noticeContainer.isHidden = true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        noticeContainer.isHidden = noticeDismissed
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
