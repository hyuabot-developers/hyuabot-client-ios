//
//  CafeterianfoVC.swift
//  hyuabot
//

import Api
import MapKit
import RxSwift
import SnapKit
import UIKit

class CafeteriaInfoVC: UIViewController {
    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let mapHeight: CGFloat = 148
        static let actionHeight: CGFloat = 48
    }

    private let cafeteriaID: Int
    private let cafeteriaInfo: BehaviorSubject<CafeteriaInfoQuery.Data.Cafeterium?> = BehaviorSubject(value: nil)
    private let disposeBag = DisposeBag()
    private var cafeteriaCoordinate: CLLocationCoordinate2D?
    private var hourTitleLabels: [UILabel] = []
    private var runningTimeBelowMapConstraint: Constraint?
    private var runningTimeBelowHeaderConstraint: Constraint?
    var onOpenMap: (() -> Void)?

    private let titleLabel = HYUSheet.makeTitleLabel()

    private let captionLabel = UILabel().then {
        $0.font = SettingsStyle.font(13)
        $0.textColor = SettingsStyle.Color.secondaryText
        $0.numberOfLines = 2
    }

    private let closeButton = HYUSheetCloseButton()

    let mapCardView = UIView().then {
        $0.backgroundColor = SettingsStyle.Color.card
        $0.layer.cornerRadius = HYUMetrics.Radius.card
        $0.layer.masksToBounds = true
    }

    let cafeteriaMapView = MKMapView().then {
        $0.isZoomEnabled = false
        $0.isScrollEnabled = false
        $0.isPitchEnabled = false
        $0.isRotateEnabled = false
        $0.isUserInteractionEnabled = false
        $0.accessibilityElementsHidden = true
    }

    private let mapActionIcon = UIImageView(image: UIImage(systemName: "mappin")).then {
        $0.tintColor = SettingsStyle.Color.link
        $0.contentMode = .scaleAspectFit
    }

    private let mapActionLabel = UILabel().then {
        $0.text = String(localized: "cafeteria.info.map.action")
        $0.font = SettingsStyle.font(15, bold: true)
        $0.textColor = SettingsStyle.Color.link
        $0.numberOfLines = 1
    }

    private let mapActionChevron = UIImageView(image: UIImage(systemName: "chevron.right")).then {
        $0.tintColor = SettingsStyle.Color.commuterFaint
        $0.contentMode = .scaleAspectFit
    }

    private let mapActionButton = UIButton(type: .system).then {
        $0.accessibilityIdentifier = "cafeteria.info.map_action"
        $0.accessibilityLabel = String(localized: "cafeteria.info.map.action")
    }

    let runningTimeTitleLabel = UILabel().then {
        $0.font = SettingsStyle.font(13, bold: true)
        $0.text = String(localized: "cafeteria.running.time")
        $0.textColor = SettingsStyle.Color.secondaryText
        $0.accessibilityTraits = .header
    }

    let hoursCardView = UIView().then {
        $0.backgroundColor = SettingsStyle.Color.card
        $0.layer.cornerRadius = HYUMetrics.Radius.card
        $0.layer.masksToBounds = true
    }

    private let breakfastTimeLabel = UILabel().then {
        $0.textColor = SettingsStyle.Color.commuterFaint
        $0.textAlignment = .right
        $0.font = SettingsStyle.monospacedDigitFont(15)
        $0.text = "–"
    }

    private let lunchTimeLabel = UILabel().then {
        $0.textColor = SettingsStyle.Color.commuterFaint
        $0.textAlignment = .right
        $0.font = SettingsStyle.monospacedDigitFont(15)
        $0.text = "–"
    }

    private let dinnerTimeLabel = UILabel().then {
        $0.textColor = SettingsStyle.Color.commuterFaint
        $0.textAlignment = .right
        $0.font = SettingsStyle.monospacedDigitFont(15)
        $0.text = "–"
    }

    private let openStatusChip = UILabel().then {
        $0.font = SettingsStyle.font(12)
        $0.text = String(localized: "cafeteria.status.open")
        $0.textColor = SettingsStyle.Color.link
        $0.backgroundColor = SettingsStyle.Color.accentFill
        $0.textAlignment = .center
        $0.layer.cornerRadius = 10
        $0.layer.masksToBounds = true
        $0.isHidden = true
        $0.font = SettingsStyle.font(12, bold: true)
    }

    init(cafeteriaID: Int) {
        self.cafeteriaID = cafeteriaID
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Call before presenting so the sheet uses the designed content-fitting height.
    func configureSheetPresentation() {
        modalPresentationStyle = .pageSheet
        guard let sheet = sheetPresentationController else { return }
        sheet.detents = [.custom(identifier: .init("cafeteria.info")) { [weak self] context in
            guard let self else { return context.maximumDetentValue }
            let width = UIScreen.main.bounds.width
            let fittingSize = view.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            // The page sheet already adds its own bottom inset, so only the card's trailing margin is needed.
            let laidOut = hoursCardView.frame.maxY + 14
            let height = hoursCardView.frame.height > 0 ? laidOut : fittingSize.height
            return min(height, context.maximumDetentValue)
        }]
        sheet.preferredCornerRadius = HYUMetrics.Radius.sheet
        sheet.prefersGrabberVisible = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.cafeteriaInfo)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "cafeteria.info.root"
        view.accessibilityViewIsModal = true
        HYUSheet.applyBackground(to: view)
        configureSheetPresentation()
        setupUI()
        fetchCafeteriaInfo()
        observeSubjects()
    }

    @objc
    private func closeSheet() {
        dismiss(animated: true)
    }

    @objc
    private func openMap() {
        dismiss(animated: true) { [weak self] in self?.onOpenMap?() }
    }

    private func fetchCafeteriaInfo() {
        let storedCampusID = UserDefaults.standard.integer(forKey: "campusID")
        let campusID = storedCampusID == 0 ? 2 : storedCampusID
        Task {
            let response = try? await Network.shared.client.fetch(query: CafeteriaInfoQuery(
                campusID: Int32(campusID), date: Foundation.Date.now.toLocalDateString()
            ))
            if let data = response?.data {
                self.cafeteriaInfo.onNext(data.cafeteria.first(where: { $0.seq == self.cafeteriaID }))
            }
        }
    }

    private func applyRunningTime(_ breakfast: String?, _ lunch: String?, _ dinner: String?) {
        breakfastTimeLabel.text = CafeteriaDisplayLogic.timeRangeText(breakfast) ?? String(localized: "cafeteria.info.closed")
        lunchTimeLabel.text = CafeteriaDisplayLogic.timeRangeText(lunch) ?? String(localized: "cafeteria.info.closed")
        dinnerTimeLabel.text = CafeteriaDisplayLogic.timeRangeText(dinner) ?? String(localized: "cafeteria.info.closed")
        for (title, label) in [
            (String(localized: "cafeteria.breakfast"), breakfastTimeLabel),
            (String(localized: "cafeteria.lunch"), lunchTimeLabel),
            (String(localized: "cafeteria.dinner"), dinnerTimeLabel)
        ] {
            label.accessibilityLabel = "\(title), \(label.text ?? "")"
        }
        for (time, label) in [(breakfast, breakfastTimeLabel), (lunch, lunchTimeLabel), (dinner, dinnerTimeLabel)] {
            label.textColor = CafeteriaDisplayLogic.timeRangeText(time) == nil ? SettingsStyle.Color.commuterFaint : SettingsStyle.Color
                .text
        }
        let now = Foundation.Date.now
        openStatusChip.isHidden = true
        for (index, pair) in [(breakfast, breakfastTimeLabel), (lunch, lunchTimeLabel), (dinner, dinnerTimeLabel)].enumerated() {
            let (time, label) = pair
            if CafeteriaDisplayLogic.isOpen(runningTime: time, now: now) {
                openStatusChip.isHidden = false
                openStatusChip.snp.remakeConstraints { make in
                    make.centerY.equalTo(self.hourTitleLabels[index])
                    make.trailing.equalToSuperview().offset(-12)
                    make.width.greaterThanOrEqualTo(64)
                    make.height.equalTo(20)
                }
                label.snp.remakeConstraints { make in
                    make.centerY.equalTo(self.hourTitleLabels[index])
                    make.trailing.lessThanOrEqualTo(self.openStatusChip.snp.leading).offset(-8)
                }
                break
            }
        }
    }

    static func mapCoordinate(latitude: Double, longitude: Double) -> CLLocationCoordinate2D? {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        guard !(latitude == 0 && longitude == 0), CLLocationCoordinate2DIsValid(coordinate) else { return nil }
        return coordinate
    }

    func updateMapCard(coordinate: CLLocationCoordinate2D?, title: String?) {
        cafeteriaMapView.removeAnnotations(cafeteriaMapView.annotations)
        cafeteriaCoordinate = coordinate
        if let coordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = title
            cafeteriaMapView.addAnnotation(annotation)
            cafeteriaMapView.camera = MKMapCamera(
                lookingAtCenter: coordinate,
                fromDistance: 750,
                pitch: 0,
                heading: 0
            )
            mapCardView.isHidden = false
            runningTimeBelowHeaderConstraint?.deactivate()
            runningTimeBelowMapConstraint?.activate()
        } else {
            mapCardView.isHidden = true
            runningTimeBelowMapConstraint?.deactivate()
            runningTimeBelowHeaderConstraint?.activate()
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
        sheetPresentationController?.animateChanges { self.sheetPresentationController?.invalidateDetents() }
    }

    private func observeSubjects() {
        cafeteriaInfo.subscribe(onNext: { [weak self] cafeteria in
            guard let self else { return }
            guard let cafeteria else {
                updateMapCard(coordinate: nil, title: nil)
                return
            }
            let name = CafeteriaDisplayLogic.cafeteriaName(seq: cafeteriaID)
            HYUSheet.setTitle(name, on: titleLabel)
            let currentCampusID = UserDefaults.standard.integer(forKey: "campusID")
            let campusName = String(localized: currentCampusID == 1 ? "campus.seoul" : "campus.erica")
            captionLabel.text = String(format: String(localized: "cafeteria.info.caption.format"), campusName)
            view.accessibilityLabel = String(format: String(localized: "cafeteria.info.a11y.title.format"), name)
            applyRunningTime(cafeteria.runningTime.breakfast, cafeteria.runningTime.lunch, cafeteria.runningTime.dinner)
            updateMapCard(
                coordinate: Self.mapCoordinate(latitude: cafeteria.latitude, longitude: cafeteria.longitude),
                title: name
            )
        }).disposed(by: disposeBag)
    }
}

extension CafeteriaInfoVC {
    private func setupUI() {
        let headerView = UIView()
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, captionLabel]).then {
            $0.axis = .vertical
            $0.spacing = 2
            $0.alignment = .leading
        }

        view.addSubview(headerView)
        view.addSubview(mapCardView)
        view.addSubview(runningTimeTitleLabel)
        view.addSubview(hoursCardView)
        headerView.addSubview(titleStack)
        headerView.addSubview(closeButton)
        mapCardView.addSubview(cafeteriaMapView)
        mapCardView.addSubview(mapActionButton)
        mapActionButton.addSubview(mapActionIcon)
        mapActionButton.addSubview(mapActionLabel)
        mapActionButton.addSubview(mapActionChevron)
        hoursCardView.addSubview(breakfastTimeLabel)
        hoursCardView.addSubview(lunchTimeLabel)
        hoursCardView.addSubview(dinnerTimeLabel)
        hoursCardView.addSubview(openStatusChip)
        cafeteriaMapView.delegate = self
        setupHeaderConstraints(headerView: headerView, titleStack: titleStack)
        setupContentConstraints(headerView: headerView)
    }

    private func setupHeaderConstraints(headerView: UIView, titleStack: UIStackView) {
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(HYUMetrics.Layout.sheetTitleTop)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(HYUMetrics.Layout.headerButtonHitHeight)
        }
        titleStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(HYUMetrics.Layout.sheetHorizontalInset)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-8)
        }
        closeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-HYUMetrics.Layout.sheetHorizontalInset)
            make.size.equalTo(HYUMetrics.Layout.headerButtonHitHeight)
        }
        closeButton.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
        mapActionButton.addTarget(self, action: #selector(openMap), for: .touchUpInside)
        let closeHitArea = UIControl()
        closeHitArea.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
        closeHitArea.accessibilityElementsHidden = true
        headerView.addSubview(closeHitArea)
        closeHitArea.snp.makeConstraints { make in
            make.center.equalTo(closeButton)
            make.size.equalTo(44)
        }
    }

    private func setupContentConstraints(headerView: UIView) {
        mapCardView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
        }
        mapCardView.isHidden = true
        cafeteriaMapView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.mapHeight)
        }
        mapActionButton.snp.makeConstraints { make in
            make.top.equalTo(cafeteriaMapView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(Layout.actionHeight)
        }
        mapActionIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        mapActionLabel.snp.makeConstraints { make in
            make.leading.equalTo(mapActionIcon.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(mapActionChevron.snp.leading).offset(-8)
        }
        mapActionChevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        runningTimeTitleLabel.snp.makeConstraints { make in
            runningTimeBelowMapConstraint = make.top.equalTo(mapCardView.snp.bottom).offset(12).constraint
            runningTimeBelowHeaderConstraint = make.top.equalTo(headerView.snp.bottom).offset(8).constraint
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.height.equalTo(16)
        }
        runningTimeBelowMapConstraint?.deactivate()
        hoursCardView.snp.makeConstraints { make in
            make.top.equalTo(runningTimeTitleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-12).priority(.high)
        }
        constrainHourRow(breakfastTimeLabel, title: String(localized: "cafeteria.breakfast"))
        constrainHourRow(lunchTimeLabel, title: String(localized: "cafeteria.lunch"))
        constrainHourRow(dinnerTimeLabel, title: String(localized: "cafeteria.dinner"))
        openStatusChip.snp.makeConstraints { make in
            make.centerY.equalTo(breakfastTimeLabel)
            make.trailing.equalToSuperview().offset(-12)
            make.width.greaterThanOrEqualTo(64)
            make.height.equalTo(20)
        }
    }

    private func constrainHourRow(_ label: UILabel, title: String) {
        let titleLabel = UILabel().then {
            $0.font = SettingsStyle.font(15, bold: true)
            $0.textColor = SettingsStyle.Color.text
            $0.text = title
        }
        titleLabel.isAccessibilityElement = false
        hoursCardView.addSubview(titleLabel)
        hourTitleLabels.append(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            if let previousTitle = hourTitleLabels.dropLast().last {
                make.top.equalTo(previousTitle.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
            make.width.greaterThanOrEqualTo(40)
            make.height.equalTo(36)
            if label === dinnerTimeLabel {
                make.bottom.equalToSuperview()
            }
        }
        label.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }
        if label !== breakfastTimeLabel {
            let separator = UIView().then { $0.backgroundColor = SettingsStyle.Color.separator }
            hoursCardView.addSubview(separator)
            separator.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.top)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.equalTo(1 / UIScreen.main.scale)
            }
        }
        label.accessibilityLabel = "\(title), \(label.text ?? "")"
    }
}

extension CafeteriaInfoVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let identifier = "cafeteriaInfoMarker"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.annotation = annotation
        let markerSize = CGSize(width: 36, height: 36)
        let renderer = UIGraphicsImageRenderer(size: markerSize)
        let markerImage = renderer.image { context in
            let circle = CGRect(origin: .zero, size: markerSize)
            SettingsStyle.Color.accent.setFill()
            context.cgContext.fillEllipse(in: circle)
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            let symbol = UIImage(systemName: "fork.knife", withConfiguration: symbolConfig)?
                .withTintColor(SettingsStyle.Color.onAccent, renderingMode: .alwaysOriginal)
            if let symbol {
                let symbolRect = CGRect(x: 9, y: 9, width: 18, height: 18)
                symbol.draw(in: symbolRect)
            }
        }
        view.image = markerImage
        view.centerOffset = .zero
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.25
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 3
        view.displayPriority = .required
        return view
    }
}
