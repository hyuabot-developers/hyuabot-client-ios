// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubwayRealtimePageQuery: GraphQLQuery {
  public static let operationName: String = "SubwayRealtimePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query SubwayRealtimePageQuery($start: Time!) { subway(id_: ["K449", "K251", "K456", "K258"], start: $start) { __typename id realtime { __typename up { __typename stop location time trainNo express last status terminal { __typename id } updatedAt } down { __typename stop location time trainNo express last status terminal { __typename id } updatedAt } } timetable { __typename up { __typename weekdays time terminal { __typename id } } down { __typename weekdays time terminal { __typename id } } } } }"#
    ))

  public var start: Time

  public init(start: Time) {
    self.start = start
  }

  public var __variables: Variables? { ["start": start] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("subway", [Subway].self, arguments: [
        "id_": ["K449", "K251", "K456", "K258"],
        "start": .variable("start")
      ]),
    ] }

    /// Subway query
    public var subway: [Subway] { __data["subway"] }

    /// Subway
    ///
    /// Parent Type: `StationQuery`
    public struct Subway: QueryAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.StationQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("realtime", Realtime.self),
        .field("timetable", Timetable.self),
      ] }

      /// Station ID
      public var id: String { __data["id"] }
      /// Realtime
      public var realtime: Realtime { __data["realtime"] }
      /// Timetable
      public var timetable: Timetable { __data["timetable"] }

      /// Subway.Realtime
      ///
      /// Parent Type: `RealtimeListQuery`
      public struct Realtime: QueryAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.RealtimeListQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("up", [Up].self),
          .field("down", [Down].self),
        ] }

        /// Up
        public var up: [Up] { __data["up"] }
        /// Down
        public var down: [Down] { __data["down"] }

        /// Subway.Realtime.Up
        ///
        /// Parent Type: `RealtimeQuery`
        public struct Up: QueryAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.RealtimeQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("stop", Int.self),
            .field("location", String.self),
            .field("time", Double.self),
            .field("trainNo", String.self),
            .field("express", Bool.self),
            .field("last", Bool.self),
            .field("status", Int.self),
            .field("terminal", Terminal.self),
            .field("updatedAt", QueryAPI.DateTime.self),
          ] }

          /// Stop
          public var stop: Int { __data["stop"] }
          /// Location
          public var location: String { __data["location"] }
          /// Time
          public var time: Double { __data["time"] }
          /// Train number
          public var trainNo: String { __data["trainNo"] }
          /// Is express
          public var express: Bool { __data["express"] }
          /// Is last
          public var last: Bool { __data["last"] }
          /// Status
          public var status: Int { __data["status"] }
          /// Terminal station
          public var terminal: Terminal { __data["terminal"] }
          /// Updated at
          public var updatedAt: QueryAPI.DateTime { __data["updatedAt"] }

          /// Subway.Realtime.Up.Terminal
          ///
          /// Parent Type: `TimetableStation`
          public struct Terminal: QueryAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.TimetableStation }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
            ] }

            /// Station ID
            public var id: String { __data["id"] }
          }
        }

        /// Subway.Realtime.Down
        ///
        /// Parent Type: `RealtimeQuery`
        public struct Down: QueryAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.RealtimeQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("stop", Int.self),
            .field("location", String.self),
            .field("time", Double.self),
            .field("trainNo", String.self),
            .field("express", Bool.self),
            .field("last", Bool.self),
            .field("status", Int.self),
            .field("terminal", Terminal.self),
            .field("updatedAt", QueryAPI.DateTime.self),
          ] }

          /// Stop
          public var stop: Int { __data["stop"] }
          /// Location
          public var location: String { __data["location"] }
          /// Time
          public var time: Double { __data["time"] }
          /// Train number
          public var trainNo: String { __data["trainNo"] }
          /// Is express
          public var express: Bool { __data["express"] }
          /// Is last
          public var last: Bool { __data["last"] }
          /// Status
          public var status: Int { __data["status"] }
          /// Terminal station
          public var terminal: Terminal { __data["terminal"] }
          /// Updated at
          public var updatedAt: QueryAPI.DateTime { __data["updatedAt"] }

          /// Subway.Realtime.Down.Terminal
          ///
          /// Parent Type: `TimetableStation`
          public struct Terminal: QueryAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.TimetableStation }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
            ] }

            /// Station ID
            public var id: String { __data["id"] }
          }
        }
      }

      /// Subway.Timetable
      ///
      /// Parent Type: `TimetableListQuery`
      public struct Timetable: QueryAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.TimetableListQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("up", [Up].self),
          .field("down", [Down].self),
        ] }

        /// Up
        public var up: [Up] { __data["up"] }
        /// Down
        public var down: [Down] { __data["down"] }

        /// Subway.Timetable.Up
        ///
        /// Parent Type: `TimetableQuery`
        public struct Up: QueryAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.TimetableQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("weekdays", Bool.self),
            .field("time", String.self),
            .field("terminal", Terminal.self),
          ] }

          /// Is weekdays
          public var weekdays: Bool { __data["weekdays"] }
          /// Departure time
          public var time: String { __data["time"] }
          /// Terminal station
          public var terminal: Terminal { __data["terminal"] }

          /// Subway.Timetable.Up.Terminal
          ///
          /// Parent Type: `TimetableStation`
          public struct Terminal: QueryAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.TimetableStation }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
            ] }

            /// Station ID
            public var id: String { __data["id"] }
          }
        }

        /// Subway.Timetable.Down
        ///
        /// Parent Type: `TimetableQuery`
        public struct Down: QueryAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.TimetableQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("weekdays", Bool.self),
            .field("time", String.self),
            .field("terminal", Terminal.self),
          ] }

          /// Is weekdays
          public var weekdays: Bool { __data["weekdays"] }
          /// Departure time
          public var time: String { __data["time"] }
          /// Terminal station
          public var terminal: Terminal { __data["terminal"] }

          /// Subway.Timetable.Down.Terminal
          ///
          /// Parent Type: `TimetableStation`
          public struct Terminal: QueryAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.TimetableStation }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
            ] }

            /// Station ID
            public var id: String { __data["id"] }
          }
        }
      }
    }
  }
}
