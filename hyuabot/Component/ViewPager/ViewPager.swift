//
//  ViewPager.swift
//  hyuabot
//

import UIKit

class ViewPager: UIView {
    let sizeConfiguration: TabView.TabSizeConfiguration
    let navigationBarEnabled: Bool
    let contentView: ContentView = .init()
    let optionView: UIView?
    let noticeView: UIView?
    var onPageChanged: ((Int) -> Void)?
    lazy var tabView: TabView = .init(sizeConfiguration: self.sizeConfiguration)

    init(
        sizeConfiguration: TabView.TabSizeConfiguration,
        optionView: UIView? = nil,
        noticeView: UIView? = nil,
        navigationBarEnabled: Bool = false
    ) {
        self.sizeConfiguration = sizeConfiguration
        self.navigationBarEnabled = navigationBarEnabled
        self.optionView = optionView
        self.noticeView = noticeView
        super.init(frame: .zero)
        setupUI()
        tabView.delegate = self
        contentView.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let topPadding = scene?.windows.first?.safeAreaInsets.top ?? .zero
        addSubview(tabView)
        addSubview(contentView)
        tabView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(self.sizeConfiguration.height + (self.navigationBarEnabled ? .zero : topPadding))
        }
        if let noticeView {
            setupNoticeView(noticeView)
        } else if let optionView {
            setupOptionView(optionView)
        } else {
            setupContentView(topView: tabView)
        }
    }

    private func setupNoticeView(_ noticeView: UIView) {
        let noticeContainer = UIView().then {
            $0.backgroundColor = .hanyangBlue
            $0.addSubview(noticeView)
        }
        addSubview(noticeContainer)
        noticeView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(5)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        if let optionView {
            addSubview(optionView)
            optionView.snp.makeConstraints { make in
                make.top.equalTo(tabView.snp.bottom)
                make.leading.trailing.equalToSuperview()
            }
            noticeContainer.snp.makeConstraints { make in
                make.top.equalTo(optionView.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(40)
            }
            setupContentView(topView: noticeContainer)
        } else {
            noticeContainer.snp.makeConstraints { make in
                make.top.equalTo(tabView.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(40)
            }
            setupContentView(topView: noticeContainer)
        }
    }

    private func setupOptionView(_ optionView: UIView) {
        addSubview(optionView)
        optionView.snp.makeConstraints { make in
            make.top.equalTo(tabView.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        setupContentView(topView: optionView)
    }

    private func setupContentView(topView: UIView) {
        contentView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension ViewPager: TabViewDelegate {
    func didMoveToTab(index: Int) {
        contentView.moveToPage(index: index)
        onPageChanged?(index)
    }
}

extension ViewPager: ContentViewDelegate {
    func didMoveToPage(index: Int) {
        guard tabView.currentIndex != index else { return }
        tabView.moveToTab(index: index)
        onPageChanged?(index)
    }
}
