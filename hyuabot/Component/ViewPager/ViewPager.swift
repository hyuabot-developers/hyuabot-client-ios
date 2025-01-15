import UIKit

class ViewPager: UIView {
    let sizeConfiguration: TabView.TabSizeConfiguration
    let contentView: ContentView = ContentView()
    lazy var tabView: TabView = TabView(sizeConfiguration: self.sizeConfiguration)
    
    init(sizeConfiguration: TabView.TabSizeConfiguration) {
        self.sizeConfiguration = sizeConfiguration
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
            make.height.equalTo(self.sizeConfiguration.height + topPadding)
        }
        self.contentView.snp.makeConstraints { make in
            make.top.equalTo(self.tabView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
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
