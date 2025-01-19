import UIKit
import RxSwift
import QueryAPI

class CafeteriaVC: UIViewController {
    private let disposeBag = DisposeBag()
    private lazy var breakfastVC = CafeteriaTabVC(cafeteriaType: .breakfast, showCafeteriaInfoVC: openCafeteriaInfoVC)
    private lazy var lunchVC = CafeteriaTabVC(cafeteriaType: .lunch, showCafeteriaInfoVC: openCafeteriaInfoVC)
    private lazy var dinnerVC = CafeteriaTabVC(cafeteriaType: .dinner, showCafeteriaInfoVC: openCafeteriaInfoVC)
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
        CafeteriaData.shared.cafeteriaMenu.subscribe(onNext: { cafeteriaList in
            var breakfast = [CafeteriaItem]()
            var lunch = [CafeteriaItem]()
            var dinner = [CafeteriaItem]()
            // Separate the menu into breakfast, lunch, and dinner
            cafeteriaList.forEach { cafeteria in
                let breakfastMenu = cafeteria.menu.filter({ $0.type.contains("조식") })
                let lunchMenu = cafeteria.menu.filter({ $0.type.contains("중식") })
                let dinnerMenu = cafeteria.menu.filter({ $0.type.contains("석식") })
                if breakfastMenu.count > 0 {
                    breakfast.append(CafeteriaItem(
                        id: cafeteria.id,
                        name: cafeteria.name,
                        runningTime: cafeteria.runningTime.breakfast,
                        menu: breakfastMenu
                    ))
                }
                if lunchMenu.count > 0 {
                    lunch.append(CafeteriaItem(
                        id: cafeteria.id,
                        name: cafeteria.name,
                        runningTime: cafeteria.runningTime.lunch,
                        menu: lunchMenu
                    ))
                }
                if dinnerMenu.count > 0 {
                    dinner.append(CafeteriaItem(
                        id: cafeteria.id,
                        name: cafeteria.name,
                        runningTime: cafeteria.runningTime.dinner,
                        menu: dinnerMenu
                    ))
                }
                CafeteriaData.shared.breakfastItems.onNext(breakfast)
                CafeteriaData.shared.lunchItems.onNext(lunch)
                CafeteriaData.shared.dinnerItems.onNext(dinner)
            }
            self.breakfastVC.reload()
            self.lunchVC.reload()
            self.dinnerVC.reload()
            self.loadingView.isHidden = true
        }).disposed(by: disposeBag)
    }
    
    @objc private func openFilterVC() {
    }
    
    @objc private func openCafeteriaInfoVC(cafeteriaID: Int) {
    }
}
