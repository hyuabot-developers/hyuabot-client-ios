import UIKit
import RxSwift

class ShuttleTimetableVC: UIViewController {
    private let stopID: String.LocalizationValue
    private let destination: String.LocalizationValue
    private let disposeBag = DisposeBag()
    private lazy var weekdaysVC = ShuttleTimetableTabVC(isWeekdays: true)
    private lazy var weekendsVC = ShuttleTimetableTabVC(isWeekdays: false)
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fillEqually(height: 60, spacing: 0))
        viewPager.tabView.tabs = [
            TabItem(title: String(localized: "shuttle.timetable.weekdays")),
            TabItem(title: String(localized: "shuttle.timetable.weekends"))
        ]
        viewPager.contentView.pages = [weekdaysVC.view, weekendsVC.view]
        return viewPager
    }()
    private lazy var filterButton = UIButton().then {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .hanyangGreen
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "line.3.horizontal.decrease")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        $0.configuration = config
        $0.addTarget(self, action: #selector(openFilterVC), for: .touchUpInside)
    }
    
    init(stopID: String.LocalizationValue, destination: String.LocalizationValue) {
        self.stopID = stopID
        self.destination = destination
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
        ShuttleTimetableData.shared.options.onNext(ShuttleTimetableOptions(
            start: self.stopID,
            end: self.destination,
            date: Date.now,
            period: nil
        ))
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(viewPager)
        self.view.addSubview(filterButton)
        self.viewPager.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        self.filterButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(20)
            make.width.height.equalTo(50)
        }
    }
    
    private func observeSubjects() {
        ShuttleTimetableData.shared.options.subscribe(onNext: { options in
            guard let options = options else { return }
            self.navigationItem.title = "\(String(localized: options.start)) → \(String(localized: options.end))"
        }).disposed(by: disposeBag)
    }
    
    @objc private func openFilterVC() {
        let vc = ShuttleTimetableFilterVC()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { _ in
                return 800
            })]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
}
