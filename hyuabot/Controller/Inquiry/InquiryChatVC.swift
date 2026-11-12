//
//  InquiryChatVC.swift
//  hyuabot
//

import FirebaseMessaging
import SnapKit
import UIKit
import UserNotifications

final class InquiryChatVC: UIViewController, SettingsStyledScreen {
    private var thread: InquiryThreadDTO?
    private var messages: [InquiryMessageDTO] = []
    private var lastAdminMessageId = 0
    private var hasLoaded = false
    private var loadFailed = false
    private var selectedQuickReply: InquiryQuickReply?
    private var renderedContent: InquiryConversationContent?
    private var pollingTimer: Timer?
    private var streamTask: Task<Void, Never>?
    private var didBecomeActiveObserver: NSObjectProtocol?
    private let entryScreen: String
    private let entryScreenName: String

    init(entryScreen: String = "campus", entryScreenName: String? = nil) {
        self.entryScreen = entryScreen
        self.entryScreenName = entryScreenName ?? String(localized: "tabbar.campus")
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeDidBecomeActiveObserver()
    }

    private let conversationView = InquiryConversationView()
    private let composerView = InquiryComposerView()
    private let bottomFill = UIView().then {
        $0.backgroundColor = SettingsStyle.Color.card
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "inquiry.title")
        view.backgroundColor = SettingsStyle.Color.background
        SettingsNavigationStyle.apply(to: self)
        configureLayout()
        conversationView.onSelectQuickReply = { [weak self] reply in self?.selectQuickReply(reply) }
        composerView.onSelectChip = { [weak self] reply in self?.selectQuickReply(reply) }
        conversationView.onRetry = { [weak self] in self?.retryLoad() }
        conversationView.onOpenTimetable = { [weak self] in self?.openTimetable() }
        composerView.onSend = { [weak self] text in self?.handleSend(text) }
        composerView.onBeginEditing = { [weak self] in self?.conversationView.scrollToBottom(animated: true) }
        render(scrollToBottom: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        InquiryPush.isChatVisible = true
        clearDeliveredInquiryNotifications()
        observeDidBecomeActive()
        navigationController?.setNavigationBarHidden(false, animated: false)
        SettingsNavigationStyle.screenWillAppear(self)
        loadInitialIfNeeded()
        startPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = true
        SettingsNavigationStyle.screenWillDisappear(self)
        InquiryPush.isChatVisible = false
        removeDidBecomeActiveObserver()
        stopPolling()
        streamTask?.cancel()
        streamTask = nil
    }

    private func configureLayout() {
        view.addSubview(conversationView)
        view.addSubview(bottomFill)
        view.addSubview(composerView)

        conversationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(composerView.snp.top)
        }
        composerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        bottomFill.snp.makeConstraints { make in
            make.top.equalTo(composerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
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
            loadFailed = true
            render(scrollToBottom: true)
            return
        }
        loadFailed = false
        thread = resolved
        preparePushNotifications()
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

    private func observeDidBecomeActive() {
        guard didBecomeActiveObserver == nil else { return }
        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearDeliveredInquiryNotifications()
        }
    }

    private func removeDidBecomeActiveObserver() {
        guard let didBecomeActiveObserver else { return }
        NotificationCenter.default.removeObserver(didBecomeActiveObserver)
        self.didBecomeActiveObserver = nil
    }

    private func clearDeliveredInquiryNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiers = notifications
                .filter { InquiryPush.isInquiryPayload($0.request.content.userInfo) }
                .map(\.request.identifier)
            guard !identifiers.isEmpty else { return }
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
        }
    }

    private func preparePushNotifications() {
        // The registration token is delivered to MessagingDelegate (AppDelegate), which uploads it.
        Messaging.messaging().register { _ in }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
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
        render(scrollToBottom: scrollToBottom || hasNewAdmin)
        if hasNewAdmin {
            Task { await InquiryService.shared.markRead(threadId: threadId) }
        }
    }

    private func render(scrollToBottom: Bool) {
        let content = InquiryChatModel.content(messages: messages, loadFailed: loadFailed, selected: selectedQuickReply)
        if content != renderedContent {
            conversationView.render(content)
            composerView.setChips(visible: content.showsChips, selected: content.answer)
            renderedContent = content
        }
        if scrollToBottom {
            conversationView.scrollToBottom(animated: true)
        }
    }

    private func selectQuickReply(_ reply: InquiryQuickReply) {
        selectedQuickReply = reply
        render(scrollToBottom: true)
    }

    private func retryLoad() {
        loadFailed = false
        hasLoaded = false
        render(scrollToBottom: false)
        loadInitialIfNeeded()
    }

    private func openTimetable() {
        navigationController?.pushViewController(
            ShuttleTimetableVC(stopID: "shuttle.stop.dormitory.out", destination: "shuttle.destination.shorten.station"),
            animated: true
        )
    }

    private func handleSend(_ text: String) {
        guard !text.isEmpty, let thread else { return }
        composerView.clearDraft()
        Task { [weak self] in
            guard let self else { return }
            _ = await InquiryService.shared.send(threadId: thread.id, body: text)
            await refreshMessages(scrollToBottom: true)
        }
    }
}
