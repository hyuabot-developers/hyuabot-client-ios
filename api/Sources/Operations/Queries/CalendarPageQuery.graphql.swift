// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct CalendarPageQuery: GraphQLQuery {
  public static let operationName: String = "CalendarPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query CalendarPageQuery { calendar { __typename version categories { __typename seq name events { __typename seq title description start end } } } }"#
    ))

  public init() {}

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("calendar", Calendar.self),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      CalendarPageQuery.Data.self
    ] }

    public var calendar: Calendar { __data["calendar"] }

    /// Calendar
    ///
    /// Parent Type: `AcademicCalendar`
    nonisolated public struct Calendar: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.AcademicCalendar }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("version", String.self),
        .field("categories", [Category].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CalendarPageQuery.Data.Calendar.self
      ] }

      public var version: String { __data["version"] }
      public var categories: [Category] { __data["categories"] }

      /// Calendar.Category
      ///
      /// Parent Type: `AcademicCalendarCategory`
      nonisolated public struct Category: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.AcademicCalendarCategory }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("seq", Int.self),
          .field("name", String.self),
          .field("events", [Event].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CalendarPageQuery.Data.Calendar.Category.self
        ] }

        public var seq: Int { __data["seq"] }
        public var name: String { __data["name"] }
        public var events: [Event] { __data["events"] }

        /// Calendar.Category.Event
        ///
        /// Parent Type: `AcademicCalendarEvent`
        nonisolated public struct Event: Api.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.AcademicCalendarEvent }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("seq", Int.self),
            .field("title", String.self),
            .field("description", String.self),
            .field("start", Api.Date.self),
            .field("end", Api.Date.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CalendarPageQuery.Data.Calendar.Category.Event.self
          ] }

          public var seq: Int { __data["seq"] }
          public var title: String { __data["title"] }
          public var description: String { __data["description"] }
          public var start: Api.Date { __data["start"] }
          public var end: Api.Date { __data["end"] }
        }
      }
    }
  }
}
