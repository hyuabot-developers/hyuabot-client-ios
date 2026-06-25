import UIKit

class ShuttleRealtimeEmptyCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleRealtimeEmptyCellView"
    private let emptyLabel = UILabel().then {
        $0.text = String(localized: "shuttle.realtime.empty")
        $0.font = .godo(size: 16, weight: .regular)
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
        contentView.addSubview(emptyLabel)
        selectionStyle = .none
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(20)
        }
    }
}
