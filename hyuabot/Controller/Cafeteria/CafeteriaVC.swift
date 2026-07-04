import Api
import RxSwift
import UIKit

class CafeteriaVC: UIViewController {
    private static let actionButtonBackground = UIColor(red: 0.86, green: 0.93, blue: 0.98, alpha: 1.00)

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
        $0.accessibilityIdentifier = "cafeteria.previous_date"
        $0.addTarget(self, action: #selector(previousDateButtonTapped), for: .touchUpInside)
    }

    private lazy var feedDatePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .compact
        $0.locale = Locale(identifier: "ko_KR")
        $0.accessibilityIdentifier = "cafeteria.date_picker"
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        $0.transform = CGAffineTransform(scaleX: 1.02, y: 1.06)
        $0.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
    }

    private lazy var nextDateButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var icon = UIImage(systemName: "chevron.right")
        icon?.withTintColor(.plainButtonText, renderingMode: .alwaysOriginal)
        conf.image = icon
        $0.configuration = conf
        $0.tintColor = .plainButtonText
        $0.accessibilityIdentifier = "cafeteria.next_date"
        $0.addTarget(self, action: #selector(nextDateButtonTapped), for: .touchUpInside)
    }

    private lazy var shareButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.plain()
        configuration.background.backgroundColor = Self.actionButtonBackground
        configuration.baseForegroundColor = .hanyangBlue
        configuration.cornerStyle = .medium
        configuration.image = UIImage(systemName: "square.and.arrow.up")?.withConfiguration(UIImage.SymbolConfiguration(
            pointSize: 16,
            weight: .semibold
        ))
        configuration.attributedTitle = AttributedString(String(localized: "common.share"), attributes: AttributeContainer([
            .font: UIFont.godo(size: 14, weight: .bold)
        ]))
        configuration.imagePadding = 6
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 14)
        $0.configuration = configuration
        $0.accessibilityLabel = String(localized: "cafeteria.share")
        $0.accessibilityIdentifier = "cafeteria_share_button"
        $0.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
    }

    private lazy var shareBar = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.borderWidth = 1 / UIScreen.main.scale
        $0.layer.borderColor = UIColor.separator.cgColor
    }

    private lazy var shareBarLabel = UILabel().then {
        $0.text = String(localized: "cafeteria.action_bar.title")
        $0.textColor = .secondaryLabel
        $0.font = .godo(size: 13, weight: .bold)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.cafeteria)
        showCoachMarksIfNeeded()
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
            )
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
            )
        ], shouldMarkAsShown: false, onComplete: {
            CoachMarkManager.shared.markPageShown("cafeteria")
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupUI() {
        view.addSubview(viewPager)
        view.addSubview(previousDateButton)
        view.addSubview(feedDatePicker)
        view.addSubview(nextDateButton)
        view.addSubview(shareBar)
        shareBar.addSubview(shareBarLabel)
        shareBar.addSubview(shareButton)
        feedDatePicker.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(50)
        }
        previousDateButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalTo(feedDatePicker)
            make.width.height.equalTo(44)
        }
        nextDateButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(feedDatePicker)
            make.width.height.equalTo(44)
        }
        viewPager.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(shareBar.snp.top)
        }
        shareBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(feedDatePicker.snp.top)
            make.height.equalTo(54)
        }
        shareBarLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        shareButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
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
                        CafeteriaData.shared.breakfastItems
                            .onNext(data.cafeteria.filter { $0.menus.contains(where: { $0.type.contains("조식") }) }
                                .sorted(by: { $0.seq < $1.seq }))
                        CafeteriaData.shared.lunchItems
                            .onNext(data.cafeteria.filter { $0.menus.contains(where: { $0.type.contains("중식") }) }
                                .sorted(by: { $0.seq < $1.seq }))
                        CafeteriaData.shared.dinnerItems
                            .onNext(data.cafeteria.filter { $0.menus.contains(where: { $0.type.contains("석식") }) }
                                .sorted(by: { $0.seq < $1.seq }))
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
            breakfastVC
        case 1:
            lunchVC
        case 2:
            dinnerVC
        default:
            breakfastVC
        }
    }

    private func updateShareButtonVisibility() {
        let isLoading = (try? CafeteriaData.shared.isLoading.value()) ?? false
        shareButton.isEnabled = !isLoading && selectedMealVC.shareText() != nil
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
        present(vc, animated: true, completion: nil)
    }

    func scrollToMealTab(_ index: Int) {
        selectedMealIndex = index
        viewPager.tabView.moveToTab(index: index)
        viewPager.contentView.moveToPage(index: index)
        updateShareButtonVisibility()
    }

    func showMeal(date: Foundation.Date, mealIndex: Int) {
        loadViewIfNeeded()
        scrollToMealTab(mealIndex)
        CafeteriaData.shared.feedDate.onNext(date)
    }
}
