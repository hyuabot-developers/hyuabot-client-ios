import UIKit

class SearchEmptyCellView: UITableViewCell {
    static let reuseIdentifier = "SearchEmptyCellView"
    private let stateView = StateView(sourceScreen: .map)

    func configure(_ content: StateContent) {
        stateView.apply(content)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(stateView)
        selectionStyle = .none
        stateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stateView.apply(.empty(message: String(localized: "map.search.empty")))
    }
}
