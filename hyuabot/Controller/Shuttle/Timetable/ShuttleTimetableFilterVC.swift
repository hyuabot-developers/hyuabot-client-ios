//
//  ShuttleTimetableFilterVC.swift
//  hyuabot
//

import RxSwift
import SnapKit
import UIKit

final class ShuttleTimetableFilterVC: UIViewController {
    private let disposeBag = DisposeBag()
    private let availableStartStop: [String.LocalizationValue] = [
        "shuttle.stop.dormitory.out", "shuttle.stop.shuttlecock.out", "shuttle.stop.station",
        "shuttle.stop.terminal", "shuttle.stop.jungang.station", "shuttle.stop.shuttlecock.in"
    ]
    private let availablePeriods: [String.LocalizationValue] = [
        "shuttle.period.semester", "shuttle.period.vacation_session", "shuttle.period.vacation", "shuttle.period.custom"
    ]
    private var availableEndStops: [String.LocalizationValue] = []
    private let datePicker: UIDatePicker = .init().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .compact
        $0.locale = Locale(identifier: "ko_KR")
    }

    private lazy var startSegment = SubwaySegmentView(buttonIdentifierPrefix: "shuttle.timetable.filter.start", columns: 3)
    private lazy var endSegment = SubwaySegmentView(buttonIdentifierPrefix: "shuttle.timetable.filter.end", columns: 3)
    private lazy var periodSegment = SubwaySegmentView(buttonIdentifierPrefix: "shuttle.timetable.filter.period", columns: 4)
    private var applyButton: UIButton?
    private lazy var sheetView = HYUSheetView(title: String(localized: "shuttle.timetable.filter"))
    var sheetHeight: CGFloat {
        view.layoutIfNeeded()
        return sheetView.contentHeight
    }

    private var selectedStartStop: String.LocalizationValue?
    private var selectedEndStop: String.LocalizationValue?
    private var selectedPeriod: String.LocalizationValue?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.shuttleTimetableFilter)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildSheet()
        observeSubjects()
        startSegment.onSelect = { [weak self] index in
            guard let self else { return }
            selectStartStop(availableStartStop[index])
        }
        endSegment.onSelect = { [weak self] index in
            guard let self, availableEndStops.indices.contains(index) else { return }
            selectEndStop(availableEndStops[index])
        }
        periodSegment.onSelect = { [weak self] index in
            guard let self else { return }
            selectPeriod(availablePeriods[index])
        }
    }

    private func segmentItems(_ values: [String.LocalizationValue]) -> [SubwaySegmentView.Item] {
        values.map { SubwaySegmentView.Item(title: String(localized: $0), dotColors: [], count: nil) }
    }

    private func buildSheet() {
        view.backgroundColor = SettingsStyle.Color.busSheetBackground
        view.addSubview(sheetView)
        sheetView.snp.makeConstraints { $0.edges.equalToSuperview() }
        sheetView.showsCloseButton(true, identifier: "shuttle.timetable.filter.close")
        sheetView.closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        let stack = sheetView.contentStack
        stack.spacing = 12
        stack.addArrangedSubview(HYUSheetView.sectionHeader(String(localized: "shuttle.timetable.filter.start"), isFirst: true))
        stack.addArrangedSubview(startSegment)
        stack.addArrangedSubview(HYUSheetView.sectionHeader(String(localized: "shuttle.timetable.filter.end")))
        stack.addArrangedSubview(endSegment)
        stack.addArrangedSubview(HYUSheetView.sectionHeader(String(localized: "shuttle.timetable.filter.period")))
        stack.addArrangedSubview(periodSegment)
        let dateRow = HYUSheetView.card()
        dateRow.axis = .horizontal
        dateRow.alignment = .center
        dateRow.spacing = 8
        dateRow.isLayoutMarginsRelativeArrangement = true
        dateRow.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        dateRow.snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }
        let dateLabel = UILabel()
        dateLabel.text = String(localized: "shuttle.timetable.filter.date")
        dateLabel.font = SettingsStyle.font(15, bold: true)
        dateRow.addArrangedSubview(dateLabel)
        dateRow.addArrangedSubview(UIView())
        dateRow.addArrangedSubview(datePicker)
        stack.addArrangedSubview(dateRow)
        let apply = HYUSheetView.primaryButton(
            title: String(localized: "shuttle.timetable.filter.ok"),
            identifier: "shuttle.timetable.filter.ok"
        )
        apply.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
        applyButton = apply
        stack.addArrangedSubview(apply)
        stack.setCustomSpacing(20, after: dateRow)
        startSegment.configure(items: segmentItems(availableStartStop), selected: 0)
        configureEndStops(for: availableStartStop[0], selectingDefault: true)
        periodSegment.configure(items: segmentItems(availablePeriods), selected: 0)
        updateApplyTitle()
    }

    private func updateApplyTitle() {
        guard let applyButton, let start = selectedStartStop, let end = selectedEndStop else { return }
        var config = applyButton.configuration
        config?.attributedTitle = AttributedString(
            String(format: String(localized: "shuttle.timetable.filter.ok.%1$@.%2$@"), String(localized: start), String(localized: end)),
            attributes: AttributeContainer([.font: SettingsStyle.font(16, bold: true)])
        )
        applyButton.configuration = config
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true)
    }

    private func observeSubjects() {
        ShuttleTimetableData.shared.options.subscribe(onNext: { [weak self] options in
            guard let self, let options else { return }
            selectStartStop(options.start, log: false, selectingDefault: false)
            selectEndStop(options.end, log: false)
            selectPeriod(options.period ?? "shuttle.period.custom", log: false)
            if let date = options.date {
                datePicker.date = date
            }
        }).disposed(by: disposeBag)
    }

    private func configureEndStops(for start: String.LocalizationValue, selectingDefault: Bool) {
        if start == "shuttle.stop.dormitory.out" || start == "shuttle.stop.shuttlecock.out" {
            availableEndStops = [
                "shuttle.destination.shorten.station",
                "shuttle.destination.shorten.terminal",
                "shuttle.destination.shorten.jungang_station"
            ]
        } else if start == "shuttle.stop.station" {
            availableEndStops = [
                "shuttle.destination.shorten.campus",
                "shuttle.destination.shorten.terminal",
                "shuttle.destination.shorten.jungang_station"
            ]
        } else {
            availableEndStops = ["shuttle.destination.shorten.campus"]
        }
        let currentIndex = availableEndStops
            .firstIndex(where: { String(localized: $0) == (selectedEndStop.map { String(localized: $0) } ?? "") })
        let selected = currentIndex ?? 0
        if selectingDefault || currentIndex == nil {
            selectedEndStop = availableEndStops.first
        }
        endSegment.configure(items: segmentItems(availableEndStops), selected: selected)
    }

    private func selectStartStop(_ stop: String.LocalizationValue, log: Bool = true, selectingDefault: Bool = true) {
        if log {
            AnalyticsManager.logSelect(.shuttleFilterSelectStart, type: .menu)
        }
        selectedStartStop = stop
        startSegment.configure(
            items: segmentItems(availableStartStop),
            selected: availableStartStop.firstIndex(where: { String(localized: $0) == String(localized: stop) }) ?? 0
        )
        configureEndStops(for: stop, selectingDefault: selectingDefault)
        updateApplyTitle()
    }

    private func selectEndStop(_ stop: String.LocalizationValue, log: Bool = true) {
        if log {
            AnalyticsManager.logSelect(.shuttleFilterSelectEnd, type: .menu)
        }
        selectedEndStop = stop
        endSegment.configure(
            items: segmentItems(availableEndStops),
            selected: availableEndStops.firstIndex(where: { String(localized: $0) == String(localized: stop) }) ?? 0
        )
        updateApplyTitle()
    }

    private func selectPeriod(_ period: String.LocalizationValue, log: Bool = true) {
        if log {
            AnalyticsManager.logSelect(.shuttleFilterSelectPeriod, type: .menu)
        }
        selectedPeriod = period
        periodSegment.configure(
            items: segmentItems(availablePeriods),
            selected: availablePeriods.firstIndex(where: { String(localized: $0) == String(localized: period) }) ?? 0
        )
        datePicker.isEnabled = period == "shuttle.period.custom"
    }

    @objc
    private func okButtonTapped() {
        AnalyticsManager.logSelect(.shuttleFilterConfirm)
        guard let selectedStartStop, let selectedEndStop else { return }
        if selectedPeriod == "shuttle.period.custom" {
            ShuttleTimetableData.shared.options.onNext(ShuttleTimetableOptions(
                start: selectedStartStop,
                end: selectedEndStop,
                date: datePicker.date,
                period: nil
            ))
        } else {
            ShuttleTimetableData.shared.options.onNext(ShuttleTimetableOptions(
                start: selectedStartStop,
                end: selectedEndStop,
                date: nil,
                period: selectedPeriod
            ))
        }
        dismiss(animated: true)
    }
}
