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
        if noticeView != nil {
            let noticeContainer = UIView().then {
                $0.backgroundColor = .hanyangBlue
                $0.addSubview(self.noticeView!)
            }
            addSubview(noticeContainer)
            if optionView != nil {
                addSubview(optionView!)
                noticeView!.snp.makeConstraints { make in
                    make.top.equalToSuperview()
                    make.bottom.equalToSuperview().inset(5)
                    make.leading.trailing.equalToSuperview().inset(10)
                }
                optionView!.snp.makeConstraints { make in
                    make.top.equalTo(self.tabView.snp.bottom)
                    make.leading.trailing.equalToSuperview()
                }
                noticeContainer.snp.makeConstraints { make in
                    make.top.equalTo(self.optionView!.snp.bottom)
                    make.leading.trailing.equalToSuperview()
                    make.height.equalTo(30)
                }
                contentView.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.top.equalTo(noticeContainer.snp.bottom)
                }
            } else {
                noticeView!.snp.makeConstraints { make in
                    make.top.equalToSuperview().inset(10)
                    make.bottom.equalToSuperview().inset(5)
                    make.leading.trailing.equalToSuperview().inset(10)
                }
                noticeContainer.snp.makeConstraints { make in
                    make.top.equalTo(self.tabView.snp.bottom)
                    make.leading.trailing.equalToSuperview()
                    make.height.equalTo(40)
                }
                contentView.snp.makeConstraints { make in
                    make.top.equalTo(noticeContainer.snp.bottom)
                    make.leading.trailing.bottom.equalToSuperview()
                }
            }
        } else {
            if optionView != nil {
                addSubview(optionView!)
                optionView!.snp.makeConstraints { make in
                    make.top.equalTo(self.tabView.snp.bottom)
                    make.leading.trailing.equalToSuperview()
                }
                contentView.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.top.equalTo(self.optionView!.snp.bottom)
                }
            } else {
                contentView.snp.makeConstraints { make in
                    make.top.equalTo(self.tabView.snp.bottom)
                    make.leading.trailing.bottom.equalToSuperview()
                }
            }
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
        tabView.moveToTab(index: index)
        onPageChanged?(index)
    }
}
