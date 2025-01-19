import UIKit
import RxSwift
import QueryAPI

class CafeteriaVC: UIViewController {
    private let disposeBag = DisposeBag()
    private lazy var breakfastVC = UIViewController()
    private lazy var lunchVC = UIViewController()
    private lazy var dinnerVC = UIViewController()
    private lazy var filterButton = UIButton().then {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .hanyangGreen
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "line.horizontal.3.decrease")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        $0.configuration = config
        $0.addTarget(self, action: #selector(openFilterVC), for: .touchUpInside)
    }
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fillEqually(height: 60, spacing: 0))
        // Add the content pages to the view pager
        viewPager.contentView.pages = [
            breakfastVC.view,
            lunchVC.view,
            dinnerVC.view
        ]
        // Set the titles for each page
        viewPager.tabView.tabs = [
            TabItem(title: String(localized: "cafeteria.tab.breakfast")),
            TabItem(title: String(localized: "cafeteria.tab.lunch")),
            TabItem(title: String(localized: "cafeteria.tab.dinner"))
        ]
        return viewPager
    }()
    private let loadingSpinner = UIActivityIndicatorView().then {
        $0.style = .large
        $0.color = .label
    }
    private let loadingLabel = UILabel().then {
        $0.text = String(localized: "cafeteria.loading")
        $0.font = .godo(size: 16, weight: .regular)
        $0.textColor = .label
    }
    private lazy var loadingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [loadingSpinner, loadingLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.backgroundColor = .systemBackground
        return stackView
    }()
    private lazy var loadingView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.addSubview(loadingStackView)
        loadingStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setupUI() {
        self.view.addSubview(viewPager)
        self.view.addSubview(loadingView)
        self.view.addSubview(filterButton)
        self.viewPager.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        self.filterButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(20)
            make.width.height.equalTo(50)
        }
        self.loadingView.snp.makeConstraints { make in
            make.edges.equalTo(viewPager)
        }
    }
    
    private func observeSubjects() {
        CafeteriaData.shared.feedDate.subscribe(onNext: { feedDate in
            let dateForm = DateFormatter().then {
                $0.dateFormat = "yyyy-MM-dd"
            }
            let date = dateForm.string(from: feedDate)
            Network.shared.client.fetch(query: CafeteriaPageQuery(date: date, campusID: 2)) { result in
                if case .success(let data) = result {
                    if let data = data.data {
                        CafeteriaData.shared.cafeteriaMenu.onNext(data.menu)
                    }
                }
            }
        }).disposed(by: disposeBag)
        CafeteriaData.shared.cafeteriaMenu.subscribe(onNext: { menu in
            self.loadingView.isHidden = true
        }).disposed(by: disposeBag)
    }
    
    @objc private func openFilterVC() {
    }
}
