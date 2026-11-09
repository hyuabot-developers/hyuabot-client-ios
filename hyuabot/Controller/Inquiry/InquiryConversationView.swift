//
//  InquiryConversationView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class InquiryConversationView: UIView {
    var onSelectQuickReply: ((InquiryQuickReply) -> Void)?
    var onRetry: (() -> Void)?
    var onOpenTimetable: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()

    init() {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.background
        configureScrollView()
        configureContent()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configureScrollView() {
        scrollView.backgroundColor = SettingsStyle.Color.background
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.accessibilityIdentifier = "inquiry.scroll"
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
            $0.height.greaterThanOrEqualTo(scrollView.frameLayoutGuide)
            $0.height.equalTo(scrollView.frameLayoutGuide).priority(.low)
        }
    }

    private func configureContent() {
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        contentView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.greaterThanOrEqualToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(16)
        }
    }

    func render(_ content: InquiryConversationContent) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        appendWelcomeIfNeeded(content)
        appendQuickListIfNeeded(content)
        appendChatRows(content.chatRows)
        appendAnswerIfNeeded(content.answer)
        appendErrorIfNeeded(content.showsError)
        setNeedsLayout()
        layoutIfNeeded()
        if scrollView.contentSize.height <= scrollView.bounds.height {
            scrollToBottom(animated: false)
        }
    }

    private func appendWelcomeIfNeeded(_ content: InquiryConversationContent) {
        if content.showsWelcome { stack.addArrangedSubview(InquiryWelcomeView()) }
    }

    private func appendQuickListIfNeeded(_ content: InquiryConversationContent) {
        guard content.showsQuickList else { return }
        let list = InquiryQuickReplyListView()
        list.onSelect = { [weak self] reply in self?.onSelectQuickReply?(reply) }
        stack.addArrangedSubview(list)
    }

    private func appendChatRows(_ rows: [InquiryChatRow]) {
        guard !rows.isEmpty else { return }
        let rowStack = UIStackView()
        rowStack.axis = .vertical
        rowStack.spacing = 0
        rowStack.alignment = .fill
        var previous: UIView?
        for row in rows {
            let view = InquiryChatRowViews.make(for: row)
            rowStack.addArrangedSubview(view)
            if let previous { rowStack.setCustomSpacing(row.topSpacing, after: previous) }
            previous = view
        }
        stack.addArrangedSubview(rowStack)
    }

    private func appendAnswerIfNeeded(_ answer: InquiryQuickReply?) {
        guard let answer else { return }
        let question = InquiryTextBubbleView(
            side: .trailing, fillColor: SettingsStyle.Color.accent,
            textColor: SettingsStyle.Color.onAccent, maxWidth: 270
        )
        question.setText(answer.question)
        question.accessibilityIdentifier = "inquiry.answer.question"
        let card: UIView
        switch answer {
        case .lostItem: card = ShuttleLostItemNoticeView()
        case .timetable:
            let notice = InquiryTimetableNoticeView()
            notice.onOpenTimetable = { [weak self] in self?.onOpenTimetable?() }
            card = notice
        }
        let response = InquiryUI.column(side: .leading, views: [
            InquiryUI.captionRow(String(localized: "inquiry.bot.quickReplyLabel"), side: .leading), card
        ])
        stack.addArrangedSubview(InquiryUI.column(side: .trailing, views: [question]))
        stack.addArrangedSubview(response)
    }

    private func appendErrorIfNeeded(_ showsError: Bool) {
        guard showsError else { return }
        let error = InquiryErrorCardView()
        error.onRetry = { [weak self] in self?.onRetry?() }
        stack.addArrangedSubview(error)
    }

    func scrollToBottom(animated: Bool) {
        setNeedsLayout()
        layoutIfNeeded()
        let y = max(
            -scrollView.adjustedContentInset.top,
            scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
        )
        scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
    }
}
