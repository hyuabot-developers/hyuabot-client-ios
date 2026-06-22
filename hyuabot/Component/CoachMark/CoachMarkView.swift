import UIKit
import SnapKit

// MARK: - CoachMarkTooltipView

private class CoachMarkTooltipView: UIView {
    var onNext: (() -> Void)?
    var onPrev: (() -> Void)?
    var onSkip: (() -> Void)?

    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 1
    }
    private let messageLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }
    private lazy var skipButton = UIButton(type: .system).then {
        $0.titleLabel?.font = .godo(size: 13, weight: .regular)
        $0.setTitleColor(.tertiaryLabel, for: .normal)
        $0.setTitle(String(localized: "coach.skip"), for: .normal)
        $0.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
    }
    private lazy var prevButton = UIButton(type: .system).then {
        $0.titleLabel?.font = .godo(size: 14, weight: .bold)
        $0.setTitle(String(localized: "coach.prev"), for: .normal)
        $0.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
    }
    private lazy var nextButton = UIButton(type: .system).then {
        $0.titleLabel?.font = .godo(size: 14, weight: .bold)
        $0.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    private let counterLabel = UILabel().then {
        $0.font = .godo(size: 12, weight: .regular)
        $0.textColor = .tertiaryLabel
        $0.textAlignment = .right
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        layer.cornerRadius = 14
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)

        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(skipButton)
        addSubview(prevButton)
        addSubview(nextButton)
        addSubview(counterLabel)

        counterLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(16)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(counterLabel.snp.leading).offset(-8)
        }
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        nextButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(10)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(14)
        }
        prevButton.snp.makeConstraints { make in
            make.trailing.equalTo(nextButton.snp.leading).offset(-12)
            make.centerY.equalTo(nextButton)
        }
        skipButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalTo(nextButton)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, message: String, buttonTitle: String, current: Int, total: Int) {
        titleLabel.text = title
        messageLabel.text = message
        nextButton.setTitle(buttonTitle, for: .normal)
        counterLabel.text = "\(current) / \(total)"
        prevButton.isHidden = current <= 1
        skipButton.isHidden = total <= 1 || current == total
    }

    @objc private func nextTapped() { onNext?() }
    @objc private func prevTapped() { onPrev?() }
    @objc private func skipTapped() { onSkip?() }
}

// MARK: - CoachMarkView

class CoachMarkView: UIView {
    var onComplete: (() -> Void)?
    var onSkip: (() -> Void)?

    private let maskLayer = CAShapeLayer()
    private let tooltip = CoachMarkTooltipView()
    private var items: [CoachMarkItem] = []
    private var currentIndex = 0
    private var didShowItem = false
    private var skippedByUser = false

    init() {
        super.init(frame: .zero)
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = UIColor.black.withAlphaComponent(0.65).cgColor
        layer.addSublayer(maskLayer)

        addSubview(tooltip)
        tooltip.onNext = { [weak self] in self?.advance() }
        tooltip.onPrev = { [weak self] in self?.goBack() }
        tooltip.onSkip = { [weak self] in
            self?.skippedByUser = true
            self?.dismiss()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = bounds
    }

    // MARK: - Public

    func present(items: [CoachMarkItem]) {
        self.items = items
        didShowItem = false
        alpha = 0
        UIView.animate(withDuration: 0.25) { self.alpha = 1 }
        show(at: 0)
    }

    // MARK: - Private

    private func show(at index: Int) {
        guard index < items.count else { dismiss(); return }
        currentIndex = index
        let item = items[index]

        guard let targetView = item.targetView else { show(at: index + 1); return }
        guard let superview = targetView.superview else { show(at: index + 1); return }
        let targetFrame = superview.convert(targetView.frame, to: self)
        guard targetFrame.width > 0, targetFrame.height > 0 else { show(at: index + 1); return }
        let holeRect = targetFrame.insetBy(dx: -10, dy: -8)
        didShowItem = true

        let path = UIBezierPath(rect: bounds)
        path.append(UIBezierPath(roundedRect: holeRect, cornerRadius: 10))

        let anim = CABasicAnimation(keyPath: "path")
        anim.fromValue = maskLayer.path ?? UIBezierPath(rect: bounds).cgPath
        anim.toValue = path.cgPath
        anim.duration = 0.2
        maskLayer.add(anim, forKey: "path")
        maskLayer.path = path.cgPath

        let isLast = index == items.count - 1
        tooltip.configure(
            title: item.title,
            message: item.message,
            buttonTitle: isLast ? String(localized: "coach.done") : String(localized: "coach.next"),
            current: index + 1,
            total: items.count
        )

        positionTooltip(relativeTo: holeRect)
    }

    private func positionTooltip(relativeTo holeRect: CGRect) {
        let maxWidth: CGFloat = min(bounds.width - 40, 320)
        let fittingSize = tooltip.systemLayoutSizeFitting(
            CGSize(width: maxWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let tooltipH = fittingSize.height

        let belowY = holeRect.maxY + 14
        let aboveY = holeRect.minY - tooltipH - 14
        let topEdge = safeAreaInsets.top + 16
        let bottomEdge = bounds.height - safeAreaInsets.bottom - 16

        let tooltipY: CGFloat
        if belowY + tooltipH < bottomEdge {
            tooltipY = belowY
        } else if aboveY >= topEdge {
            tooltipY = aboveY
        } else {
            tooltipY = max(topEdge, bounds.midY - tooltipH / 2)
        }
        let tooltipX = max(20, min(bounds.width - maxWidth - 20, holeRect.midX - maxWidth / 2))

        tooltip.alpha = 0
        tooltip.frame = CGRect(x: tooltipX, y: tooltipY, width: maxWidth, height: tooltipH)
        UIView.animate(withDuration: 0.2) { self.tooltip.alpha = 1 }
    }

    private func advance() {
        UIView.animate(withDuration: 0.15, animations: {
            self.tooltip.alpha = 0
        }) { _ in
            self.show(at: self.currentIndex + 1)
        }
    }

    private func goBack() {
        guard currentIndex > 0 else { return }
        UIView.animate(withDuration: 0.15, animations: {
            self.tooltip.alpha = 0
        }) { _ in
            self.show(at: self.currentIndex - 1)
        }
    }

    private func dismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            guard self.didShowItem else { return }
            if self.skippedByUser, let skipHandler = self.onSkip {
                skipHandler()
            } else {
                self.onComplete?()
            }
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard !tooltip.frame.contains(gesture.location(in: self)) else { return }
        advance()
    }
}

// MARK: - UIViewController extension

extension UIViewController {
    @discardableResult
    func presentCoachMarks(
        pageId: String,
        items: [CoachMarkItem],
        version: Int = 1,
        shouldMarkAsShown: Bool = true,
        onSkip: (() -> Void)? = nil,
        onComplete: (() -> Void)? = nil
    ) -> Bool {
        guard CoachMarkManager.shared.shouldShowPage(pageId, version: version) else { return false }
        let validItems = items.filter { item in
            guard let view = item.targetView else { return false }
            return view.window != nil && !view.isHidden
        }
        guard !validItems.isEmpty else { return false }
        guard let window = view.window,
              !window.subviews.contains(where: { $0 is CoachMarkView }) else { return false }

        let overlay = CoachMarkView()
        overlay.frame = window.bounds
        window.addSubview(overlay)
        overlay.onComplete = {
            if shouldMarkAsShown {
                CoachMarkManager.shared.markPageShown(pageId, version: version)
            }
            onComplete?()
        }
        overlay.onSkip = {
            if shouldMarkAsShown {
                CoachMarkManager.shared.markPageShown(pageId, version: version)
            }
            onSkip?()
        }
        overlay.present(items: validItems)
        return true
    }
}
