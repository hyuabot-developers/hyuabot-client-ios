import UIKit

class ViewPager: UIView {
    let sizeConfiguration: TabView.TabSizeConfiguration
    let navigationBarEnabled: Bool
    let contentView: ContentView = ContentView()
    let optionView: UIView?
    let noticeView: UIView?
    lazy var tabView: TabView = TabView(sizeConfiguration: self.sizeConfiguration)
    
    init(sizeConfiguration: TabView.TabSizeConfiguration, optionView: UIView? = nil, noticeView: UIView? = nil, navigationBarEnabled: Bool = false) {
        self.sizeConfiguration = sizeConfiguration
        self.navigationBarEnabled = navigationBarEnabled
        self.optionView = optionView
        self.noticeView = noticeView
        super.init(frame: .zero)
        self.setupUI()
        self.tabView.delegate = self
        self.contentView.delegate = self
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let topPadding = scene?.windows.first?.safeAreaInsets.top ?? .zero
        self.addSubview(self.tabView)
        self.addSubview(self.contentView)
        self.tabView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(self.sizeConfiguration.height + (self.navigationBarEnabled ? .zero : topPadding))
        }
        if (noticeView != nil) {
            let noticeContainer = UIView().then {
                $0.backgroundColor = .hanyangBlue
                $0.addSubview(self.noticeView!)
            }
            self.addSubview(noticeContainer)
            if (optionView != nil) {
                self.addSubview(self.optionView!)
                self.noticeView!.snp.makeConstraints { make in
                    make.top.equalToSuperview()
                    make.bottom.equalToSuperview().inset(5)
                    make.leading.trailing.equalToSuperview().inset(10)
                }
                self.optionView!.snp.makeConstraints { make in
                    make.top.equalTo(self.tabView.snp.bottom)
                    make.leading.trailing.equalToSuperview()
                }
                noticeContainer.snp.makeConstraints { make in
                    make.top.equalTo(self.optionView!.snp.bottom)
                    make.leading.trailing.equalToSuperview()
                    make.height.equalTo(30)
                }
                self.contentView.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.top.equalTo(noticeContainer.snp.bottom)
                }
            }
            else {
                self.noticeView!.snp.makeConstraints { make in
                    make.top.equalToSuperview().inset(10)
                    make.bottom.equalToSuperview().inset(5)
                    make.leading.trailing.equalToSuperview().inset(10)
                }
                noticeContainer.snp.makeConstraints { make in
                    make.top.equalTo(self.tabView.snp.bottom)
                    make.leading.trailing.equalToSuperview()
                    make.height.equalTo(40)
                }
                self.contentView.snp.makeConstraints { make in
                    make.top.equalTo(noticeContainer.snp.bottom)
                    make.leading.trailing.bottom.equalToSuperview()
                }
            }
        } else {
            if (optionView != nil) {
                self.addSubview(self.optionView!)
                self.optionView!.snp.makeConstraints { make in
                    make.top.equalTo(self.tabView.snp.bottom)
                    make.leading.trailing.equalToSuperview()
                }
                self.contentView.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.top.equalTo(self.optionView!.snp.bottom)
                }
            }
            else {
                self.contentView.snp.makeConstraints { make in
                    make.top.equalTo(self.tabView.snp.bottom)
                    make.leading.trailing.bottom.equalToSuperview()
                }
            }
        }
    }
}

extension ViewPager: TabViewDelegate {
    func didMoveToTab(index: Int) {
        self.contentView.moveToPage(index: index)
    }
}

extension ViewPager: ContentViewDelegate {
    func didMoveToPage(index: Int) {
        self.tabView.moveToTab(index: index)
    }
}
