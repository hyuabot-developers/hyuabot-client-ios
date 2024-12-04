// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubwayTimetablePageDownQuery: GraphQLQuery {
  public static let operationName: String = "SubwayTimetablePageDownQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query SubwayTimetablePageDownQuery($station: String!) { subway(id_: [$station]) { __typename timetable { __typename down { __typename weekdays time terminal { __typename id } } } } }"#
    ))

  public var station: String

  public init(station: String) {
    self.station = station
  }

  public var __variables: Variables? { ["station": station] }

  public struct Data: GraphQL.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("subway", [Subway].self, arguments: ["id_": [.variable("station")]]),
    ] }

    /// Subway query
    public var subway: [Subway] { __data["subway"] }

    /// Subway
    ///
    /// Parent Type: `StationQuery`
    public struct Subway: GraphQL.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.StationQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("timetable", Timetable.self),
      ] }

      /// Timetable
      public var timetable: Timetable { __data["timetable"] }

      /// Subway.Timetable
      ///
      /// Parent Type: `TimetableListQuery`
      public struct Timetable: GraphQL.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.TimetableListQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("down", [Down].self),
        ] }

        /// Down
        public var down: [Down] { __data["down"] }

        /// Subway.Timetable.Down
        ///
        /// Parent Type: `TimetableQuery`
        public struct Down: GraphQL.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.TimetableQuery }
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
          public struct Terminal: GraphQL.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.TimetableStation }
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
