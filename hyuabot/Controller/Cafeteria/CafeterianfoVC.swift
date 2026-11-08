//
//  CafeterianfoVC.swift
//  hyuabot
//

import Api
import MapKit
import RxSwift
import UIKit

class CafeteriaInfoVC: UIViewController {
    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let cardRadius: CGFloat = 16
        static let mapHeight: CGFloat = 148
        static let actionHeight: CGFloat = 48
    }

    private let cafeteriaID: Int
    private let cafeteriaInfo: BehaviorSubject<CafeteriaInfoQuery.Data.Cafeterium?> = BehaviorSubject(value: nil)
    private let disposeBag = DisposeBag()
    private var cafeteriaCoordinate: CLLocationCoordinate2D?
    private var hourTitleLabels: [UILabel] = []
    var onOpenMap: (() -> Void)?

    private let grabberView = UIView().then {
        $0.backgroundColor = SettingsStyle.Color.cafeteriaGrabber
        $0.layer.cornerRadius = 2.5
        $0.accessibilityElementsHidden = true
    }

    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = SettingsStyle.Color.text
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
        $0.accessibilityTraits = .header
    }

    private let captionLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .regular)
        $0.textColor = SettingsStyle.Color.secondaryText
        $0.numberOfLines = 2
    }

    private let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = SettingsStyle.Color.secondaryText
        $0.backgroundColor = SettingsStyle.Color.segmentBackground
        $0.layer.cornerRadius = 15
        $0.accessibilityLabel = String(localized: "close")
        $0.accessibilityIdentifier = "cafeteria.info.close"
    }

    private let mapCardView = UIView().then {
        $0.backgroundColor = SettingsStyle.Color.card
        $0.layer.cornerRadius = Layout.cardRadius
        $0.layer.masksToBounds = true
    }

    private let cafeteriaMapView = MKMapView().then {
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
        $0.font = .godo(size: 15, weight: .bold)
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

    private let runningTimeTitleLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .bold)
        $0.text = String(localized: "cafeteria.running.time")
        $0.textColor = SettingsStyle.Color.secondaryText
        $0.accessibilityTraits = .header
    }

    private let hoursCardView = UIView().then {
        $0.backgroundColor = SettingsStyle.Color.card
        $0.layer.cornerRadius = Layout.cardRadius
        $0.layer.masksToBounds = true
    }

    private let breakfastTimeLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .regular)
        $0.textColor = SettingsStyle.Color.commuterFaint
        $0.textAlignment = .right
        $0.font = SettingsStyle.monospacedDigitFont(15)
        $0.text = "–"
    }

    private let lunchTimeLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .regular)
        $0.textColor = SettingsStyle.Color.commuterFaint
        $0.textAlignment = .right
        $0.font = SettingsStyle.monospacedDigitFont(15)
        $0.text = "–"
    }

    private let dinnerTimeLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .regular)
        $0.textColor = SettingsStyle.Color.commuterFaint
        $0.textAlignment = .right
        $0.font = SettingsStyle.monospacedDigitFont(15)
        $0.text = "–"
    }

    private let openStatusChip = UILabel().then {
        $0.font = .godo(size: 12, weight: .medium)
        $0.text = String(localized: "cafeteria.status.open")
        $0.textColor = SettingsStyle.Color.link
        $0.backgroundColor = SettingsStyle.Color.accentFill
        $0.textAlignment = .center
        $0.layer.cornerRadius = 10
        $0.layer.masksToBounds = true
        $0.isHidden = true
        $0.font = .godo(size: 12, weight: .bold)
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
        sheet.preferredCornerRadius = 24
        sheet.prefersGrabberVisible = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.cafeteriaInfo)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "cafeteria.info.root"
        view.accessibilityViewIsModal = true
        view.backgroundColor = SettingsStyle.Color.background
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

    private func observeSubjects() {
        cafeteriaInfo.subscribe(onNext: { [weak self] cafeteria in
            guard let self, let cafeteria else { return }
            let name = CafeteriaDisplayLogic.cafeteriaName(seq: cafeteriaID)
            titleLabel.text = name
            let currentCampusID = UserDefaults.standard.integer(forKey: "campusID")
            let campusName = String(localized: currentCampusID == 1 ? "campus.seoul" : "campus.erica")
            captionLabel.text = String(format: String(localized: "cafeteria.info.caption.format"), campusName)
            view.accessibilityLabel = String(format: String(localized: "cafeteria.info.a11y.title.format"), name)
            mapCardView.isHidden = false

            let breakfast = cafeteria.runningTime.breakfast
            let lunch = cafeteria.runningTime.lunch
            let dinner = cafeteria.runningTime.dinner
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

            cafeteriaMapView.removeAnnotations(cafeteriaMapView.annotations)
            sheetPresentationController?.animateChanges {
                self.sheetPresentationController?.invalidateDetents()
            }
            guard cafeteria.latitude != 0 || cafeteria.longitude != 0 else {
                cafeteriaCoordinate = nil
                return
            }
            let coordinate = CLLocationCoordinate2D(latitude: cafeteria.latitude, longitude: cafeteria.longitude)
            cafeteriaCoordinate = coordinate
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = name
            cafeteriaMapView.addAnnotation(annotation)
            cafeteriaMapView.camera = MKMapCamera(
                lookingAtCenter: coordinate,
                fromDistance: 750,
                pitch: 0,
                heading: 0
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

        view.addSubview(grabberView)
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
        grabberView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(6)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 36, height: 5))
        }
        headerView.snp.makeConstraints { make in
            make.top.equalTo(grabberView.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
            make.height.equalTo(44)
        }
        titleStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-8)
        }
        closeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-7)
            make.size.equalTo(30)
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
            make.top.equalTo(mapCardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.height.equalTo(16)
        }
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
            $0.font = .godo(size: 15, weight: .bold)
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
