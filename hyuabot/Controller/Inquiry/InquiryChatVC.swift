//
//  InquiryChatVC.swift
//  hyuabot
//

import SnapKit
import UIKit

final class InquiryChatVC: UIViewController {
    private var thread: InquiryThreadDTO?
    private var messages: [InquiryMessageDTO] = []
    private var lastAdminMessageId = 0
    private var hasLoaded = false
    private var didReportFailure = false
    private var pollingTimer: Timer?

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
        $0.titleLabel?.font = .godo(size: 15, weight: .bold)
        $0.accessibilityIdentifier = "inquiry.send_button"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "inquiry.title")
        view.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        inputField.delegate = self
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        configureLayout()
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
    }

    private func configureLayout() {
        view.addSubview(tableView)
        view.addSubview(inputContainer)
        view.addSubview(emptyLabel)
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)

        inputContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        inputField.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
            make.height.greaterThanOrEqualTo(36)
        }
        sendButton.snp.makeConstraints { make in
            make.leading.equalTo(inputField.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(inputField)
            make.width.greaterThanOrEqualTo(44)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputContainer.snp.top)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.leading.trailing.equalTo(tableView).inset(40)
        }
    }

    private func loadInitialIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        Task { [weak self] in
            guard let self else { return }
            var resolved = await InquiryService.shared.activeThread()
            if resolved == nil {
                resolved = await InquiryService.shared.openThread(
                    subject: nil,
                    entryScreen: "campus",
                    entryScreenName: String(localized: "tabbar.campus")
                )
            }
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
    }

    private func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
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
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard messages.indices.contains(indexPath.row),
              let cell = tableView.dequeueReusableCell(
                  withIdentifier: InquiryMessageCellView.reuseIdentifier,
                  for: indexPath
              ) as? InquiryMessageCellView
        else { return UITableViewCell() }
        cell.configure(with: messages[indexPath.row])
        return cell
    }
}

extension InquiryChatVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
