import UIKit
import RxSwift
import Api

class CafeteriaVC: UIViewController {
    private let disposeBag = DisposeBag()
    private var selectedMealIndex = 0
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
        viewPager.onPageChanged = { [weak self] index in
            self?.selectedMealIndex = index
            self?.updateShareButtonVisibility()
        }
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
    private lazy var shareButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .hanyangGreen
        configuration.cornerStyle = .medium
        configuration.image = UIImage(systemName: "square.and.arrow.up")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        configuration.background.strokeColor = .white.withAlphaComponent(0.9)
        configuration.background.strokeWidth = 1
        $0.configuration = configuration
        $0.tintColor = .white
        $0.accessibilityLabel = String(localized: "cafeteria.share")
        $0.accessibilityIdentifier = "cafeteria_share_button"
        $0.isHidden = true
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.22
        $0.layer.shadowRadius = 8
        $0.layer.shadowOffset = CGSize(width: 0, height: 3)
        $0.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.logScreenView(.cafeteria)
        self.showCoachMarksIfNeeded()
    }

    private func showCoachMarksIfNeeded() {
        guard CoachMarkManager.shared.shouldShowPage("cafeteria") else { return }
        presentCoachMarks(pageId: "cafeteria", items: [
            CoachMarkItem(
                id: "cafeteria.date",
                targetView: feedDatePicker,
                title: String(localized: "coach.cafeteria.date.title"),
                message: String(localized: "coach.cafeteria.date.message")
            ),
            CoachMarkItem(
                id: "cafeteria.tabs",
                targetView: viewPager.tabView,
                title: String(localized: "coach.cafeteria.tabs.title"),
                message: String(localized: "coach.cafeteria.tabs.message")
            ),
        ], shouldMarkAsShown: false, onComplete: { [weak self] in
            self?.showHeaderCoachMarkWhenReady()
        })
    }

    private func showHeaderCoachMarkWhenReady() {
        let isLoaded = (try? CafeteriaData.shared.lunchItems.value())?.isEmpty == false
        if isLoaded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.presentHeaderCoachMark()
            }
        } else {
            CafeteriaData.shared.lunchItems
                .filter { !$0.isEmpty }
                .take(1)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self?.presentHeaderCoachMark()
                    }
                })
                .disposed(by: disposeBag)
        }
    }

    private func presentHeaderCoachMark() {
        presentCoachMarks(pageId: "cafeteria", items: [
            CoachMarkItem(
                id: "cafeteria.header.info",
                targetViewProvider: { [weak self] in self?.breakfastVC.firstSectionHeaderInfoButton },
                title: String(localized: "coach.cafeteria.header.info.title"),
                message: String(localized: "coach.cafeteria.header.info.message")
            ),
        ], shouldMarkAsShown: false, onComplete: {
            CoachMarkManager.shared.markPageShown("cafeteria")
        })
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
        self.view.addSubview(previousDateButton)
        self.view.addSubview(feedDatePicker)
        self.view.addSubview(nextDateButton)
        self.view.addSubview(shareButton)
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
        self.shareButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(feedDatePicker.snp.top).offset(-20)
            make.width.height.equalTo(50)
        }
        self.viewPager.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(feedDatePicker.snp.top)
        }
    }
    
    private func observeSubjects() {
        let campusID = UserDefaults.standard.integer(forKey: "campusID") == 0 ? 2 : UserDefaults.standard.integer(forKey: "campusID")
        CafeteriaData.shared.feedDate.subscribe(onNext: { feedDate in
            CafeteriaData.shared.isLoading.onNext(true)
            self.updateShareButtonVisibility()
            let dateForm = DateFormatter().then {
                $0.dateFormat = "yyyy-MM-dd"
            }
            let date = dateForm.string(from: feedDate)
            self.feedDatePicker.date = feedDate
            Task {
                let response = try? await Network.shared.client.fetch(query: CafeteriaPageQuery(date: date, campusID: Int32(campusID)))
                await MainActor.run {
                    if let data = response?.data {
                        CafeteriaData.shared.breakfastItems.onNext(data.cafeteria.filter({ $0.menus.contains(where: { $0.type.contains("조식") }) }).sorted(by: { $0.seq < $1.seq }))
                        CafeteriaData.shared.lunchItems.onNext(data.cafeteria.filter({ $0.menus.contains(where: { $0.type.contains("중식") }) }).sorted(by: { $0.seq < $1.seq }))
                        CafeteriaData.shared.dinnerItems.onNext(data.cafeteria.filter({ $0.menus.contains(where: { $0.type.contains("석식") }) }).sorted(by: { $0.seq < $1.seq }))
                        self.breakfastVC.reload()
                        self.lunchVC.reload()
                        self.dinnerVC.reload()
                    }
                    CafeteriaData.shared.isLoading.onNext(false)
                    self.updateShareButtonVisibility()
                }
            }
        }).disposed(by: disposeBag)
    }

    private var selectedMealVC: CafeteriaTabVC {
        switch selectedMealIndex {
        case 0:
            return breakfastVC
        case 1:
            return lunchVC
        case 2:
            return dinnerVC
        default:
            return breakfastVC
        }
    }

    private func updateShareButtonVisibility() {
        let isLoading = (try? CafeteriaData.shared.isLoading.value()) ?? false
        shareButton.isHidden = isLoading || selectedMealVC.shareText() == nil
    }
    
    @objc private func previousDateButtonTapped() {
        AnalyticsManager.logSelect(.cafeteriaPreviousDate, type: .dateControl)
        let date = Calendar.current.date(byAdding: .day, value: -1, to: feedDatePicker.date)
        CafeteriaData.shared.feedDate.onNext(date!)
    }
    @objc private func datePickerValueChanged() {
        AnalyticsManager.logSelect(.cafeteriaDateChanged, type: .dateControl)
        CafeteriaData.shared.feedDate.onNext(feedDatePicker.date)
    }
    @objc private func nextDateButtonTapped() {
        AnalyticsManager.logSelect(.cafeteriaNextDate, type: .dateControl)
        let date = Calendar.current.date(byAdding: .day, value: 1, to: feedDatePicker.date)
        CafeteriaData.shared.feedDate.onNext(date!)
    }
    @objc private func shareButtonTapped() {
        selectedMealVC.presentShareSheet(sourceView: shareButton)
    }
    @objc private func openCafeteriaInfoVC(cafeteriaID: Int) {
        let vc = CafeteriaInfoVC(cafeteriaID: cafeteriaID)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }

    func scrollToMealTab(_ index: Int) {
        selectedMealIndex = index
        viewPager.tabView.moveToTab(index: index)
        viewPager.contentView.moveToPage(index: index)
        updateShareButtonVisibility()
    }
}
