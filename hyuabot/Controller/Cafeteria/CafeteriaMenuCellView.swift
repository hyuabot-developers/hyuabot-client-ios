import Api
import RxSwift
import UIKit

class CafeteriaMenuCellView: UITableViewCell {
    static let reuseIdentifier = "CafeteriaMenuCellView"
    private let menuLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .regular)
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.lineBreakMode = .byCharWrapping
    }

    private let pricaLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .bold)
        $0.textAlignment = .center
        $0.textColor = .hanyangBlue
    }

    private lazy var cellStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.menuLabel, self.pricaLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
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
            make.horizontalEdges.equalToSuperview().inset(24)
            make.top.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
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
        menuLabel.text = Self.localizedFood(item.food)
        pricaLabel.text = String(
            format: String(localized: "cafeteria.menu.price.%@"),
            item.price.replacingOccurrences(of: "원", with: "")
        )
    }
}
