//
//  ShuttleExpandedTransferCellView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class ShuttleExpandedTransferCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleExpandedTransferCellView"

    private weak var transferView: ShuttleTransferInfoView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground
        selectionStyle = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clearContent()
    }

    static func preferredHeight(transferView: ShuttleTransferInfoView?) -> CGFloat {
        guard let transferView, transferView.preferredHeight > 0 else { return 0 }
        return transferView.preferredHeight
    }

    func setup(transferView: ShuttleTransferInfoView) {
        clearContent()
        self.transferView = transferView
        contentView.addSubview(transferView)
        transferView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(transferView.preferredHeight)
        }
    }

    private func clearContent() {
        transferView?.removeFromSuperview()
        transferView = nil
    }
}
