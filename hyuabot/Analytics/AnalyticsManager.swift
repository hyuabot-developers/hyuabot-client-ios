//
//  AnalyticsManager.swift
//  hyuabot
//
//  Central Firebase Analytics catalog.
//
//  All event names, screen names, and item identifiers live here so that the
//  set of tracked events is defined in a single place. The string values use
//  GA4-style snake_case and the GA4 reserved events (`screen_view`,
//  `select_content`) so that the Android client can adopt the exact same
//  catalog later for cross-platform unification.
//
//  Unification rule: when adding/changing an entry, keep the rawValue identical
//  to the Android client. The Swift case name may differ, but the rawValue is
//  the contract.
//

import UIKit
import FirebaseAnalytics
import FirebaseCrashlytics

// MARK: - Screens (GA4 `screen_view` -> screen_name)

/// Every user-visible screen. rawValue == GA4 `screen_name` (shared with Android).
enum AnalyticsScreen: String {
    // Shuttle
    case shuttleRealtime        = "shuttle_realtime"
    case shuttleTimetable       = "shuttle_timetable"
    case shuttleTimetableFilter = "shuttle_timetable_filter"
    case shuttleStopInfo        = "shuttle_stop_info"
    case shuttleVia             = "shuttle_via"
    case shuttleHelp            = "shuttle_help"
    // Bus
    case busRealtime            = "bus_realtime"
    case busTimetable           = "bus_timetable"
    case busStopInfo            = "bus_stop_info"
    case busDepartureLog        = "bus_departure_log"
    case busHelp                = "bus_help"
    // Subway
    case subwayRealtime         = "subway_realtime"
    case subwayTimetable        = "subway_timetable"
    // Cafeteria
    case cafeteria              = "cafeteria"
    case cafeteriaInfo          = "cafeteria_info"
    // Map
    case map                    = "map"
    case mapBuilding            = "map_building"
    // Others
    case readingRoom            = "reading_room"
    case contact                = "contact"
    case calendar               = "calendar"
    case setting                = "setting"
    case webView                = "web_view"
    case birthday               = "birthday"
}

// MARK: - Content types (GA4 `select_content` -> content_type)

/// What kind of element was selected. rawValue == GA4 `content_type` (shared with Android).
enum AnalyticsContentType: String {
    case button     = "button"
    case tab        = "tab"
    case listItem   = "list_item"
    case toggle     = "toggle"
    case menu       = "menu"
    case dateControl = "date_control"
}

// MARK: - Items (GA4 `select_content` -> item_id)

/// Every tappable element. rawValue == GA4 `item_id` (shared with Android).
enum AnalyticsItem: String {
    // Tab bar (RootVC)
    case tabShuttle     = "tab_shuttle"
    case tabBus         = "tab_bus"
    case tabSubway      = "tab_subway"
    case tabCafeteria   = "tab_cafeteria"
    case tabMap         = "tab_map"
    case tabReadingRoom = "tab_reading_room"
    case tabContact     = "tab_contact"
    case tabCalendar    = "tab_calendar"
    case tabSetting     = "tab_setting"
    case tabChat        = "tab_chat"
    case tabDonate      = "tab_donate"

    // Shuttle - realtime
    case shuttleArrivalByTimeSwitch = "shuttle_arrival_by_time_switch"
    case shuttleDepartureSwitch     = "shuttle_departure_switch"
    case shuttleOpenHelp            = "shuttle_open_help"
    case shuttleShowStopModal       = "shuttle_show_stop_modal"
    case shuttleShowEntireTimetable = "shuttle_show_entire_timetable"
    case shuttleRouteToggle         = "shuttle_route_toggle"
    case shuttleRefresh             = "shuttle_refresh"
    case shuttleSelectViaRow        = "shuttle_select_via_row"

    // Shuttle - timetable
    case shuttleOpenFilter          = "shuttle_open_filter"
    case shuttleFilterConfirm       = "shuttle_filter_confirm"
    case shuttleFilterSelectStart   = "shuttle_filter_select_start"
    case shuttleFilterSelectEnd     = "shuttle_filter_select_end"
    case shuttleFilterSelectPeriod  = "shuttle_filter_select_period"

    // Bus
    case busOpenHelp                = "bus_open_help"
    case busStopButton              = "bus_stop_button"
    case busShowEntireTimetable     = "bus_show_entire_timetable"
    case busShowDepartureLog        = "bus_show_departure_log"
    case busRefresh                 = "bus_refresh"

    // Subway
    case subwayShowEntireTimetable  = "subway_show_entire_timetable"
    case subwayRefresh              = "subway_refresh"

    // Cafeteria
    case cafeteriaPreviousDate      = "cafeteria_previous_date"
    case cafeteriaNextDate          = "cafeteria_next_date"
    case cafeteriaDateChanged       = "cafeteria_date_changed"
    case cafeteriaInfoButton        = "cafeteria_info_button"
    case cafeteriaShareButton       = "cafeteria_share_button"

    // Reading room
    case readingRoomRefresh         = "reading_room_refresh"
    case readingRoomAlarmToggle     = "reading_room_alarm_toggle"

    // Contact
    case contactSelectRow           = "contact_select_row"

    // Map
    case mapSelectSearchResult      = "map_select_search_result"

    // Setting
    case settingSelectCampus        = "setting_select_campus"
    case settingSelectTheme         = "setting_select_theme"
    case settingSelectRow           = "setting_select_row"

    // Birthday
    case birthdayDoNotShow          = "birthday_do_not_show"
    case birthdayDismiss            = "birthday_dismiss"
}

// MARK: - Manager

/// Thin wrapper over FirebaseAnalytics. The only place that calls `Analytics.logEvent`.
enum AnalyticsManager {
    private static let analyticsConsentKey = "analyticsConsent"

    static var isCollectionEnabled: Bool {
        if UserDefaults.standard.object(forKey: analyticsConsentKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: analyticsConsentKey)
    }

    static func applyCollectionSettings() {
        Analytics.setAnalyticsCollectionEnabled(isCollectionEnabled)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(isCollectionEnabled)
    }

    static func setCollectionEnabled(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: analyticsConsentKey)
        applyCollectionSettings()
    }

    /// Logs a GA4 `screen_view` event.
    static func logScreen(_ screen: AnalyticsScreen, class screenClass: AnyObject) {
        guard isCollectionEnabled else { return }
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screen.rawValue,
            AnalyticsParameterScreenClass: String(describing: type(of: screenClass))
        ])
    }

    /// Logs a GA4 `select_content` event for a tap/selection.
    /// - Parameters:
    ///   - item: the catalog identifier (becomes `item_id`).
    ///   - type: the kind of element (becomes `content_type`).
    ///   - name: optional human/contextual label (becomes `item_name`), e.g. the
    ///           selected stop, contact name, or building name.
    static func logSelect(_ item: AnalyticsItem,
                          type: AnalyticsContentType = .button,
                          name: String? = nil) {
        guard isCollectionEnabled else { return }
        var params: [String: Any] = [
            AnalyticsParameterContentType: type.rawValue,
            AnalyticsParameterItemID: item.rawValue
        ]
        if let name {
            params[AnalyticsParameterItemName] = name
        }
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: params)
    }
}

// MARK: - UIViewController convenience

extension UIViewController {
    /// Logs a `screen_view` for this controller. Call from `viewDidAppear`.
    func logScreenView(_ screen: AnalyticsScreen) {
        AnalyticsManager.logScreen(screen, class: self)
    }
}
