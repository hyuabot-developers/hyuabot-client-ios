import Api
import MapKit
import RxSwift
import SnapKit
import UIKit

enum MapScreenMode {
    case browse
    case building(MapPageQuery.Data.Building)
    case searching
    case result(RoomItem)
}

class MapVC: UIViewController, SettingsStyledScreen, UIGestureRecognizerDelegate {
    let disposeBag = DisposeBag()
    var mode: MapScreenMode = .browse
    var isLoadingSearch = false
    var searchFailed = false
    var isLoadingBuildings = false
    var searchGate = MapRequestGate()
    var buildingGate = MapRequestGate()
    var isReconcilingAnnotations = false
    weak var savedPopGestureDelegate: UIGestureRecognizerDelegate?

    static let campusCenter = CLLocationCoordinate2D(latitude: 37.29650544998881, longitude: 126.83513202158153)

    let mapView = MKMapView().then {
        $0.camera = MKMapCamera(lookingAtCenter: campusCenter, fromDistance: 4000, pitch: 0, heading: 0)
        $0.isZoomEnabled = true
        $0.isScrollEnabled = true
        $0.isPitchEnabled = true
        $0.accessibilityIdentifier = "map.view"
        $0.register(MapPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: MapPinAnnotationView.reuseIdentifier)
    }
    let searchBarView = MapSearchBarView()
    let statusPill = MapStatusPillView()
    let recenterButton = MapRecenterButton()
    let buildingCard = MapBuildingCardView()
    let resultsContainer = UIView()
    let resultsCountLabel = UILabel()
    let searchResultView = UITableView(frame: .zero, style: .plain)
    var recenterBottomConstraint: Constraint?
    var recenterCardConstraint: Constraint?

    var isSearchMode: Bool { if case .searching = mode { return true }; return false }
    var isResultMode: Bool { if case .result = mode { return true }; return false }
    var canReturnToCampus: Bool { (navigationController?.viewControllers.count ?? 0) > 1 }

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.title = String(localized: "tabbar.map")
        setupUI()
        setupActions()
        observeSubjects()
        observeSearch()
        searchBarView.onBeginEditing = { [weak self] in self?.enterSearch() }
        searchBarView.onTextChange = { [weak self] in self?.onTextChange($0) }
        searchBarView.onClear = { [weak self] in self?.onClear() }
        searchBarView.onBack = { [weak self] in self?.exitSearch() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        SettingsNavigationStyle.screenWillAppear(self)
        updateAccessibilityActions()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadBuildingsIfNeeded()
        logScreenView(.map)
        savedPopGestureDelegate = navigationController?.interactivePopGestureRecognizer?.delegate
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        showCoachMarksIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !mapView.bounds.isEmpty {
            reloadBuildingsIfNeeded()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = savedPopGestureDelegate
        navigationController?.setNavigationBarHidden(false, animated: animated)
        SettingsNavigationStyle.screenWillDisappear(self)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === navigationController?.interactivePopGestureRecognizer ? canReturnToCampus && !isSearchMode : true
    }

    override func accessibilityPerformEscape() -> Bool {
        if isSearchMode { exitSearch(); return true }
        if canReturnToCampus { navigationController?.popViewController(animated: true); return true }
        return false
    }

    func setupUI() {
        view.backgroundColor = SettingsStyle.Color.background
        resultsContainer.backgroundColor = SettingsStyle.Color.background
        resultsContainer.isHidden = true
        buildingCard.isHidden = true
        resultsCountLabel.font = SettingsStyle.monospacedDigitFont(13)
        resultsCountLabel.textColor = SettingsStyle.Color.secondaryText
        searchResultView.backgroundColor = .clear
        searchResultView.separatorStyle = .none
        searchResultView.rowHeight = UITableView.automaticDimension
        searchResultView.estimatedRowHeight = 64
        searchResultView.keyboardDismissMode = .onDrag
        searchResultView.showsVerticalScrollIndicator = false
        searchResultView.contentInset.bottom = 12
        searchResultView.delegate = self
        searchResultView.dataSource = self
        searchResultView.register(SearchResultCellView.self, forCellReuseIdentifier: SearchResultCellView.reuseIdentifier)
        searchResultView.register(SearchEmptyCellView.self, forCellReuseIdentifier: SearchEmptyCellView.reuseIdentifier)
        searchResultView.register(MapSearchSkeletonCellView.self, forCellReuseIdentifier: MapSearchSkeletonCellView.reuseIdentifier)
        resultsContainer.addSubview(resultsCountLabel)
        resultsContainer.addSubview(searchResultView)

        [mapView, resultsContainer, buildingCard, recenterButton, statusPill, searchBarView].forEach(view.addSubview)
        mapView.snp.makeConstraints { $0.edges.equalToSuperview() }
        searchBarView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        statusPill.snp.makeConstraints {
            $0.top.equalTo(searchBarView.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        }
        resultsContainer.snp.makeConstraints { $0.edges.equalToSuperview() }
        resultsCountLabel.snp.makeConstraints {
            $0.top.equalTo(searchBarView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(18)
        }
        searchResultView.snp.makeConstraints {
            $0.top.equalTo(resultsCountLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        buildingCard.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        recenterButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(44)
            recenterBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12).constraint
            recenterCardConstraint = $0.bottom.equalTo(buildingCard.snp.top).offset(-12).constraint
            recenterCardConstraint?.deactivate()
        }
    }

    func setupActions() {
        recenterButton.addTarget(self, action: #selector(recenter), for: .touchUpInside)
        buildingCard.onDeselect = { [weak self] in
            guard let self else { return }
            if self.isResultMode { self.showAllBuildings() } else {
                self.mapView.selectedAnnotations.forEach { self.mapView.deselectAnnotation($0, animated: true) }
            }
        }
        buildingCard.onShowAll = { [weak self] in self?.showAllBuildings() }
        buildingCard.onOpenGuide = { [weak self] in self?.openGuide() }
    }

    func observeSubjects() {
        MapData.shared.searchMode.subscribe(onNext: { [weak self] searching in
            guard let self, !searching else { return }
            self.reloadBuildings()
        }).disposed(by: disposeBag)
        MapData.shared.buildingResult.subscribe(onNext: { [weak self] in self?.applyBuildings($0) }).disposed(by: disposeBag)
    }

    func showCoachMarksIfNeeded() {
        presentCoachMarks(pageId: "map", items: [
            CoachMarkItem(
                id: "map.search",
                targetView: searchBarView,
                title: String(localized: "coach.map.search.title"),
                message: String(localized: "coach.map.search.message")
            ),
            CoachMarkItem(
                id: "map.map",
                targetView: mapView,
                title: String(localized: "coach.map.map.title"),
                message: String(localized: "coach.map.map.message")
            )
        ])
    }

    func updateAccessibilityActions() {
        if canReturnToCampus {
            searchBarView.accessibilityCustomActions = [UIAccessibilityCustomAction(
                name: String(localized: "map.back_to_campus")
            ) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
                return true
            }]
        } else {
            searchBarView.accessibilityCustomActions = nil
        }
    }

    func enterSearch() {
        if isResultMode {
            searchBarView.text = ""
            MapData.shared.searchKeyword.onNext(nil)
        }
        mapView.selectedAnnotations.forEach { mapView.deselectAnnotation($0, animated: false) }
        mode = .searching
        searchBarView.setSearching(true)
        statusPill.isHidden = true
        recenterButton.isHidden = true
        buildingCard.isHidden = true
    }

    func exitSearch() {
        invalidateSearch()
        searchBarView.text = ""
        searchBarView.textField.resignFirstResponder()
        resultsContainer.isHidden = true
        MapData.shared.searchKeyword.onNext(nil)
        mode = .browse
        searchBarView.setSearching(false)
        statusPill.isHidden = false
        recenterButton.isHidden = false
        MapData.shared.searchMode.onNext(false)
    }

    func showCard(_ content: MapBuildingCardView.Content) {
        buildingCard.apply(content)
        buildingCard.isHidden = false
        updateRecenterPosition(animated: true)
    }

    func hideCard() {
        buildingCard.isHidden = true
        updateRecenterPosition(animated: true)
    }

    func updateRecenterPosition(animated: Bool) {
        let update = {
            if self.buildingCard.isHidden {
                self.recenterCardConstraint?.deactivate()
                self.recenterBottomConstraint?.activate()
            } else {
                self.recenterBottomConstraint?.deactivate()
                self.recenterCardConstraint?.activate()
            }
            self.view.layoutIfNeeded()
        }
        if animated { UIView.animate(withDuration: 0.22, animations: update) } else { update() }
    }

    func invalidateSearch() {
        searchGate.invalidate()
        isLoadingSearch = false
        searchFailed = false
    }
}
