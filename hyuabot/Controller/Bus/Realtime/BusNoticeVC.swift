//
//  BusNoticeVC.swift
//  hyuabot
//

import UIKit
import WebKit

final class BusNoticeVC: UIViewController {
    private let url: URL
    private let webView = WKWebView()

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        webView.load(URLRequest(url: url))
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.busSheetBackground
        let title = UILabel()
        title.accessibilityIdentifier = "bus.notice.title"
        title.attributedText = SettingsStyle.attributedText(
            String(localized: "notice.title"), font: SettingsStyle.font(20, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 26
        )
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.accessibilityIdentifier = "bus.notice.web"
        view.addSubview(title)
        view.addSubview(webView)
        title.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(11)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(52)
        }
        webView.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(3)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
}
