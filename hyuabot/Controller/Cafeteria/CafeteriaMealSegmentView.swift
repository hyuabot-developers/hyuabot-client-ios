//
//  CafeteriaMealSegmentView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CafeteriaMealSegmentView: UIView {
    var onSelect: ((CafeteriaMeal) -> Void)?

    private let control = HYUSegmentedControl(buttonIdentifierPrefix: "cafeteria.meal")

    init() {
        super.init(frame: .zero)
        accessibilityIdentifier = "cafeteria.meal_segment"
        accessibilityLabel = String(localized: "cafeteria.meal.segment.a11y")
        addSubview(control)
        control.snp.makeConstraints { $0.edges.equalToSuperview() }
        control.onSelect = { [weak self] index in
            guard let self, CafeteriaMeal.allCases.indices.contains(index) else { return }
            onSelect?(CafeteriaMeal.allCases[index])
        }
        configure(selected: .breakfast)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(selected: CafeteriaMeal) {
        control.configure(titles: CafeteriaMeal.allCases.map(\.title), selected: selected.rawValue)
    }
}
