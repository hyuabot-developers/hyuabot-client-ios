import Api
import RxSwift
import UIKit

private final class CafeteriaPriceLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12) {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }
}

class CafeteriaMenuCellView: UITableViewCell {
    static let reuseIdentifier = "CafeteriaMenuCellView"
    private let menuLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .regular)
        $0.numberOfLines = 0
        $0.textAlignment = .left
        $0.lineBreakMode = .byCharWrapping
    }

    private let pricaLabel = CafeteriaPriceLabel().then {
        $0.font = .godo(size: 13, weight: .bold)
        $0.textAlignment = .center
        $0.textColor = .hanyangBlue
        $0.backgroundColor = UIColor(red: 0.92, green: 0.96, blue: 0.99, alpha: 1.0)
        $0.layer.cornerRadius = 10
        $0.layer.masksToBounds = true
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    private lazy var cellStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.menuLabel, self.pricaLabel])
        stackView.axis = .horizontal
        stackView.alignment = .firstBaseline
        stackView.spacing = 14
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        contentView.addSubview(cellStackView)
        selectionStyle = .none
        cellStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().inset(14)
        }
        pricaLabel.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(76)
            make.height.greaterThanOrEqualTo(32)
        }
    }

    private static let isKoreanApp: Bool = (Locale.current.language.languageCode?.identifier ?? "ko").hasPrefix("ko")
    private static let hangulRegex = try! NSRegularExpression(pattern: "\\p{Hangul}")

    static func localizedFood(_ food: String) -> String {
        let cleaned = food.replacingOccurrences(of: "\"", with: "")
        guard isKoreanApp else { return cleaned }
        let tokens = cleaned.components(separatedBy: .whitespaces)
        let filtered = tokens.filter { token in
            hangulRegex.firstMatch(in: token, range: NSRange(token.startIndex..., in: token)) != nil
        }
        let result = filtered.joined(separator: " ")
        return result.isEmpty ? cleaned : result
    }

    func setupUI(item: CafeteriaPageQuery.Data.Cafeterium.Menu) {
        menuLabel.setKoreanTranslatedText(Self.localizedFood(item.food))
        pricaLabel.text = String(
            format: String(localized: "cafeteria.menu.price.%@"),
            item.price.replacingOccurrences(of: "원", with: "")
        )
    }
}
