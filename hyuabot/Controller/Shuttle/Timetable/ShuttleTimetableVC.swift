import UIKit
import RxSwift

class ShuttleTimetableVC: UIViewController {
    private let stopID: String.LocalizationValue
    private let destination: String.LocalizationValue
    private let disposeBag = DisposeBag()
    private let options = BehaviorSubject<ShuttleTimetableOptions?>(value: nil)
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
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
        self.options.onNext(ShuttleTimetableOptions(
            start: self.stopID,
            end: self.destination,
            date: Date.now,
            period: nil
        ))
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(viewPager)
        self.viewPager.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func observeSubjects() {
        self.options.subscribe(onNext: { options in
            guard let options = options else { return }
            self.navigationItem.title = "\(String(localized: options.start)) → \(String(localized: options.end))"
        }).disposed(by: disposeBag)
    }
}
