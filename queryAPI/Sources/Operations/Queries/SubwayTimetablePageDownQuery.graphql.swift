// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubwayTimetablePageDownQuery: GraphQLQuery {
  public static let operationName: String = "SubwayTimetablePageDownQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query SubwayTimetablePageDownQuery($station: String!) { subway(id_: [$station]) { __typename timetable { __typename down { __typename weekdays time hour minute terminal { __typename id } } } } }"#
    ))

  public var station: String

  public init(station: String) {
    self.station = station
  }

  public var __variables: Variables? { ["station": station] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("subway", [Subway].self, arguments: ["id_": [.variable("station")]]),
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
        .field("timetable", Timetable.self),
      ] }

      /// Timetable
      public var timetable: Timetable { __data["timetable"] }

      /// Subway.Timetable
      ///
      /// Parent Type: `TimetableListQuery`
      public struct Timetable: QueryAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.TimetableListQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("down", [Down].self),
        ] }

        /// Down
        public var down: [Down] { __data["down"] }

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
            .field("hour", Int.self),
            .field("minute", Int.self),
            .field("terminal", Terminal.self),
          ] }

          /// Is weekdays
          public var weekdays: Bool { __data["weekdays"] }
          /// Departure time
          public var time: String { __data["time"] }
          /// Departure hour
          public var hour: Int { __data["hour"] }
          /// Departure minute
          public var minute: Int { __data["minute"] }
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
