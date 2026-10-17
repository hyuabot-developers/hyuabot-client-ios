import UIKit

class ShuttleRealtimeEmptyCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleRealtimeEmptyCellView"
    private let stateView = StateView(sourceScreen: .shuttleRealtime)

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
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground
        selectionStyle = .none
        contentView.addSubview(stateView)
        stateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stateView.apply(.empty(message: String(localized: "shuttle.realtime.empty")))
    }
}
