import UIKit
import RxSwift
import Api

class CafeteriaVC: UIViewController {
    private let disposeBag = DisposeBag()
    private lazy var breakfastVC = CafeteriaTabVC(cafeteriaType: .breakfast, showCafeteriaInfoVC: openCafeteriaInfoVC)
    private lazy var lunchVC = CafeteriaTabVC(cafeteriaType: .lunch, showCafeteriaInfoVC: openCafeteriaInfoVC)
    private lazy var dinnerVC = CafeteriaTabVC(cafeteriaType: .dinner, showCafeteriaInfoVC: openCafeteriaInfoVC)
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
    
    private lazy var previousDateButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var icon = UIImage(systemName: "chevron.left")
        icon?.withTintColor(.plainButtonText, renderingMode: .alwaysOriginal)
        conf.image = icon
        $0.configuration = conf
        $0.tintColor = .plainButtonText
        $0.addTarget(self, action: #selector(previousDateButtonTapped), for: .touchUpInside)
    }
    private lazy var feedDatePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .compact
        $0.locale = Locale(identifier: "ko_KR")
        $0.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
    }
    private lazy var nextDateButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var icon = UIImage(systemName: "chevron.right")
        icon?.withTintColor(.plainButtonText, renderingMode: .alwaysOriginal)
        conf.image = icon
        $0.configuration = conf
        $0.tintColor = .plainButtonText
        $0.addTarget(self, action: #selector(nextDateButtonTapped), for: .touchUpInside)
    }
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
        self.view.addSubview(previousDateButton)
        self.view.addSubview(feedDatePicker)
        self.view.addSubview(nextDateButton)
        self.feedDatePicker.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(50)
        }
        self.previousDateButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalTo(feedDatePicker)
        }
        self.nextDateButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(feedDatePicker)
        }
        self.viewPager.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(feedDatePicker.snp.top)
        }
        self.loadingView.snp.makeConstraints { make in
            make.edges.equalTo(viewPager)
        }
    }
    
    private func observeSubjects() {
        let campusID = UserDefaults.standard.integer(forKey: "campusID") == 0 ? 2 : UserDefaults.standard.integer(forKey: "campusID")
        CafeteriaData.shared.feedDate.subscribe(onNext: { feedDate in
            let dateForm = DateFormatter().then {
                $0.dateFormat = "yyyy-MM-dd"
            }
            let date = dateForm.string(from: feedDate)
            self.feedDatePicker.date = feedDate
            Task {
                let response = try? await Network.shared.client.fetch(query: CafeteriaPageQuery(date: date, campusID: Int32(campusID)))
                if let data = response?.data {
                    CafeteriaData.shared.breakfastItems.onNext(data.cafeteria.filter({ $0.menus.contains(where: { $0.type.contains("조식") }) }).sorted(by: { $0.seq < $1.seq }))
                    CafeteriaData.shared.lunchItems.onNext(data.cafeteria.filter({ $0.menus.contains(where: { $0.type.contains("중식") }) }).sorted(by: { $0.seq < $1.seq }))
                    CafeteriaData.shared.dinnerItems.onNext(data.cafeteria.filter({ $0.menus.contains(where: { $0.type.contains("석식") }) }).sorted(by: { $0.seq < $1.seq }))
                    self.breakfastVC.reload()
                    self.lunchVC.reload()
                    self.dinnerVC.reload()
                    self.loadingView.isHidden = true
                }
            }
        }).disposed(by: disposeBag)
    }
    
    @objc private func previousDateButtonTapped() {
        let date = Calendar.current.date(byAdding: .day, value: -1, to: feedDatePicker.date)
        CafeteriaData.shared.feedDate.onNext(date!)
    }
    @objc private func datePickerValueChanged() {
        CafeteriaData.shared.feedDate.onNext(feedDatePicker.date)
    }
    @objc private func nextDateButtonTapped() {
        let date = Calendar.current.date(byAdding: .day, value: 1, to: feedDatePicker.date)
        CafeteriaData.shared.feedDate.onNext(date!)
    }
    @objc private func openCafeteriaInfoVC(cafeteriaID: Int) {
        let vc = CafeteriaInfoVC(cafeteriaID: cafeteriaID)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
}
