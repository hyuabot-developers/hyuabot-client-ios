//
//  BusRealtimeLogRequest.swift
//  hyuabot
//

import Api
import Apollo
import Foundation

/// The bus realtime page's log window: a small `logLimit` cap plus a `logAfter` time-of-day bound, both sent next
/// to the unchanged arrival `limit`, and the fallback for backends whose BusRouteStopInput lacks these fields.
enum BusRealtimeLogRequest {
    /// Max `log` rows per route-stop. With `logAfter` the backend returns only logs at or after that time plus the
    /// post-midnight (00:00-04:00) ones, most recent requested date first, so 15 rows cover the rows the page shows.
    static let logLimit: Int32 = 15

    /// Result of one fetch attempt: the page data, or the GraphQL error messages that explain why there is none.
    struct Attempt<Payload> {
        let data: Payload?
        let errorMessages: [String]
    }

    /// Result of `fetch`: the data to render (nil when every attempt failed) and the capability flag the caller
    /// must store for later polls.
    struct Outcome<Payload> {
        let data: Payload?
        let supportsLogWindow: Bool
    }

    /// "HH:mm" of `now` in the calendar BusRealtimeVC.serviceDate uses to drop past log times (the device's), so
    /// the backend never filters out a log the page would still show.
    static func logAfter(now: Foundation.Date, calendar: Calendar = .current) -> LocalTime {
        let components = calendar.dateComponents([.hour, .minute], from: now)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    /// Copies of `inputs` with the log window set (`logAfter` non-nil) or removed (nil: the legacy limit-only input).
    static func inputs(_ inputs: [BusRouteStopInput], logAfter: LocalTime?) -> [BusRouteStopInput] {
        inputs.map { input in
            var input = input
            if let logAfter {
                input.logLimit = .some(logLimit)
                input.logAfter = .some(logAfter)
            } else {
                input.logLimit = .none
                input.logAfter = .none
            }
            return input
        }
    }

    /// The only signal that the backend predates the log window. graphql-java reports an unknown variable field as
    /// "The variables input contains a field name 'logLimit' that is not defined for input object type
    /// 'BusRouteStopInput'" (production, 2026-11-14), naming whichever new field it meets first.
    /// Timeouts, 5xx and other errors never match.
    static func rejectsLogWindow(_ errorMessages: [String]) -> Bool {
        errorMessages.contains { message in
            message.contains("BusRouteStopInput") && (message.contains("'logLimit'") || message.contains("'logAfter'"))
        }
    }

    /// `message` of every entry in the `errors` array of a GraphQL response body; empty when the body is not one.
    static func graphQLErrorMessages(inResponseBody body: Foundation.Data) -> [String] {
        guard let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let errors = object["errors"] as? [[String: Any]]
        else {
            return []
        }
        return errors.compactMap { $0["message"] as? String }
    }

    /// Error messages carried by an error thrown from `ApolloClient.fetch`. With Apollo's
    /// `Accept: application/graphql-response+json` header the backend answers a validation error with HTTP 400,
    /// which Apollo throws as `ResponseCodeInterceptor.ResponseCodeError` holding the body in `chunk`.
    static func graphQLErrorMessages(in error: any Error) -> [String] {
        guard let responseCodeError = error as? ResponseCodeInterceptor.ResponseCodeError else {
            return []
        }
        return graphQLErrorMessages(inResponseBody: responseCodeError.chunk)
    }

    /// Fetches with the log window while `supportsLogWindow` is true. When that attempt returns no data, retries
    /// once with the legacy limit-only input so the page still renders. `supportsLogWindow` turns false only when the
    /// windowed attempt failed with the explicit unknown-field error (`rejectsLogWindow`); a transient failure
    /// followed by a successful legacy retry keeps it true, so the next poll asks for the window again.
    @MainActor
    static func fetch<Payload>(
        input: [BusRouteStopInput],
        logAfter: LocalTime,
        supportsLogWindow: Bool,
        attempt: @MainActor ([BusRouteStopInput]) async -> Attempt<Payload>
    ) async -> Outcome<Payload> {
        let legacyInput = inputs(input, logAfter: nil)
        guard supportsLogWindow else {
            let result = await attempt(legacyInput)
            return Outcome(data: result.data, supportsLogWindow: false)
        }
        let windowed = await attempt(inputs(input, logAfter: logAfter))
        if let data = windowed.data {
            return Outcome(data: data, supportsLogWindow: true)
        }
        let stillSupported = !rejectsLogWindow(windowed.errorMessages)
        let legacy = await attempt(legacyInput)
        return Outcome(data: legacy.data, supportsLogWindow: stillSupported)
    }
}
