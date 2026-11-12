//
//  BuildingVC.swift
//  hyuabot
//

import SnapKit
import UIKit
import WebKit

final class BuildingVC: UIViewController, WKNavigationDelegate {
    private let buildingName: String
    private let url: URL
    private let webView = WKWebView()
    private let captionLabel = UILabel()
    private let titleLabel = UILabel()
    private let progressTrack = UIView()
    private let progressBar = UIView()
    private let skeletonView = UIView()
    private let errorView = UIView()
    private let retryButton = UIButton(type: .system)
    private var didLoadOnce = false
    private var isLoading = false
    private var progressAnimationRunning = false

    init(buildingName: String, url: URL) {
        self.buildingName = buildingName
        self.url = url
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        HYUSheet.configure(self, detents: [.large()])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.mapBuilding)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        webView.load(URLRequest(url: url))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startProgressAnimationIfNeeded()
    }

    private func setupUI() {
        HYUSheet.applyBackground(to: view)
        configureHeader()
        configureProgress()
        configureWebBody()
        configureErrorView()
    }

    private func configureHeader() {
        captionLabel.text = String(localized: "map.sheet.caption")
        captionLabel.font = SettingsStyle.font(13)
        captionLabel.textColor = SettingsStyle.Color.secondaryText
        captionLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setKoreanTranslatedText(buildingName)
        titleLabel.font = SettingsStyle.font(20, bold: true)
        titleLabel.textColor = SettingsStyle.Color.text
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontForContentSizeCategory = true
        let header = UIStackView(arrangedSubviews: [captionLabel, titleLabel])
        header.axis = .vertical
        header.spacing = 2
        view.addSubview(header)

        let closeButton = HYUSheetCloseButton()
        closeButton.accessibilityIdentifier = "map.sheet.close"
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-12)
        }
        closeButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.trailing.equalToSuperview().offset(-9)
            make.centerY.equalTo(header.snp.centerY)
        }
    }

    private func configureProgress() {
        progressTrack.backgroundColor = SettingsStyle.Color.separator
        progressTrack.clipsToBounds = true
        progressTrack.isHidden = true
        progressBar.backgroundColor = SettingsStyle.Color.accent
        progressTrack.addSubview(progressBar)
        view.addSubview(progressTrack)
        progressTrack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(2)
        }
        progressBar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(progressTrack.snp.width).multipliedBy(0.4)
        }
    }

    private func configureWebBody() {
        webView.isOpaque = false
        webView.backgroundColor = SettingsStyle.Color.card
        webView.scrollView.backgroundColor = SettingsStyle.Color.card
        webView.layer.cornerRadius = HYUMetrics.Radius.card
        webView.layer.cornerCurve = .continuous
        webView.clipsToBounds = true
        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.equalTo(progressTrack.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        let skeletonStack = UIStackView()
        skeletonStack.axis = .vertical
        skeletonStack.alignment = .leading
        skeletonStack.spacing = 12
        let widths: [CGFloat] = [1, 0.70, 0.92, 0.86, 0.60]
        let heights: [CGFloat] = [180, 18, 12, 12, 12]
        let radii: [CGFloat] = [12, 9, 6, 6, 6]
        for index in widths.indices {
            let block = UIView()
            block.backgroundColor = SettingsStyle.Color.segmentBackground
            block.layer.cornerRadius = radii[index]
            block.layer.cornerCurve = .continuous
            skeletonStack.addArrangedSubview(block)
            block.snp.makeConstraints { make in
                make.width.equalTo(skeletonStack.snp.width).multipliedBy(widths[index])
                make.height.equalTo(heights[index])
            }
        }
        skeletonView.addSubview(skeletonStack)
        view.addSubview(skeletonView)
        skeletonStack.snp.makeConstraints { make in make.top.leading.trailing.equalToSuperview().inset(16) }
        skeletonView.snp.makeConstraints { make in make.edges.equalTo(webView) }
        setSkeletonVisible(true)
    }

    private func setSkeletonVisible(_ visible: Bool) {
        skeletonView.isHidden = !visible
        guard visible else {
            skeletonView.layer.removeAnimation(forKey: "skeleton-pulse")
            return
        }
        if !UIAccessibility.isReduceMotionEnabled,
           skeletonView.layer.animation(forKey: "skeleton-pulse") == nil {
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1
            pulse.toValue = 0.4
            pulse.duration = 0.7
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            skeletonView.layer.add(pulse, forKey: "skeleton-pulse")
        }
    }

    private func configureErrorView() {
        errorView.isHidden = true
        let iconCircle = UIView()
        iconCircle.backgroundColor = SettingsStyle.Color.segmentBackground
        iconCircle.layer.cornerRadius = 28
        iconCircle.layer.cornerCurve = .continuous
        let icon = UIImageView(image: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22)))
        icon.tintColor = SettingsStyle.Color.secondaryText
        iconCircle.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }
        iconCircle.snp.makeConstraints { $0.size.equalTo(56) }

        let title = UILabel()
        title.text = String(localized: "map.sheet.error.title")
        title.font = SettingsStyle.font(17, bold: true)
        title.textColor = SettingsStyle.Color.text
        title.textAlignment = .center
        title.adjustsFontForContentSizeCategory = true
        let message = UILabel()
        message.text = String(localized: "map.sheet.error.message")
        message.font = SettingsStyle.font(14)
        message.textColor = SettingsStyle.Color.secondaryText
        message.textAlignment = .center
        message.numberOfLines = 0
        message.adjustsFontForContentSizeCategory = true
        let textStack = UIStackView(arrangedSubviews: [title, message])
        textStack.axis = .vertical
        textStack.spacing = 4
        var retry = UIButton.Configuration.filled()
        let retryTitle = String(localized: "map.sheet.retry")
        retry.attributedTitle = AttributedString(
            retryTitle,
            attributes: AttributeContainer([.font: SettingsStyle.font(15, bold: true)])
        )
        retry.baseBackgroundColor = SettingsStyle.Color.accentFill
        retry.baseForegroundColor = SettingsStyle.Color.link
        retry.cornerStyle = .capsule
        retry.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        retryButton.configuration = retry
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        let stack = UIStackView(arrangedSubviews: [iconCircle, textStack, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        errorView.addSubview(stack)
        view.addSubview(errorView)
        stack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.leading.trailing.equalToSuperview().inset(32)
        }
        errorView.snp.makeConstraints { make in make.edges.equalTo(webView) }
    }

    private func setLoading(_ loading: Bool) {
        isLoading = loading
        progressTrack.isHidden = !loading
        setSkeletonVisible(loading && !didLoadOnce)
        if !loading {
            progressTrack.layer.removeAllAnimations()
            progressBar.layer.removeAllAnimations()
            progressAnimationRunning = false
        } else {
            startProgressAnimationIfNeeded()
        }
    }

    private func setError(_ shown: Bool) {
        errorView.isHidden = !shown
        webView.isHidden = shown
    }

    private func startProgressAnimationIfNeeded() {
        guard isLoading, !progressAnimationRunning, progressBar.bounds.width > 0 else { return }
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -progressBar.bounds.width
        animation.toValue = progressTrack.bounds.width * 2.6
        animation.duration = 1.1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = .infinity
        progressBar.layer.add(animation, forKey: "loading-progress")
        progressAnimationRunning = true
    }

    private func handleFailure(_ error: Error) {
        if (error as NSError).code != NSURLErrorCancelled {
            setError(true)
        }
        setLoading(webView.isLoading)
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true)
    }

    @objc
    private func retryTapped() {
        setError(false)
        setLoading(true)
        webView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        setError(false)
        setLoading(true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didLoadOnce = true
        setLoading(false)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        didLoadOnce = true
        setSkeletonVisible(false)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleFailure(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleFailure(error)
    }
}
