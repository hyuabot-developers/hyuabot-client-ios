// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct SubwayTimetablePageQuery: GraphQLQuery {
  public static let operationName: String = "SubwayTimetablePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query SubwayTimetablePageQuery($station: String!, $direction: [String!]!) { subway( input: { keys: [ { stationID: $station direction: $direction weekdays: ["weekdays", "weekends"] } ] } ) { __typename timetable { __typename weekday direction time terminal { __typename stationID name } } } }"#
    ))

  public var station: String
  public var direction: [String]

  public init(
    station: String,
    direction: [String]
  ) {
    self.station = station
    self.direction = direction
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "station": station,
    "direction": direction
  ] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("subway", [Subway].self, arguments: ["input": ["keys": [[
        "stationID": .variable("station"),
        "direction": .variable("direction"),
        "weekdays": ["weekdays", "weekends"]
      ]]]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      SubwayTimetablePageQuery.Data.self
    ] }

    public var subway: [Subway] { __data["subway"] }

    /// Subway
    ///
    /// Parent Type: `SubwayStation`
    nonisolated public struct Subway: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.SubwayStation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("timetable", [Timetable].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SubwayTimetablePageQuery.Data.Subway.self
      ] }

      public var timetable: [Timetable] { __data["timetable"] }

      /// Subway.Timetable
      ///
      /// Parent Type: `SubwayTimetable`
      nonisolated public struct Timetable: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.SubwayTimetable }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("weekday", String.self),
          .field("direction", String.self),
          .field("time", Api.LocalTime.self),
          .field("terminal", Terminal.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SubwayTimetablePageQuery.Data.Subway.Timetable.self
        ] }

        public var weekday: String { __data["weekday"] }
        public var direction: String { __data["direction"] }
        public var time: Api.LocalTime { __data["time"] }
        public var terminal: Terminal { __data["terminal"] }

        /// Subway.Timetable.Terminal
        ///
        /// Parent Type: `SubwayOriginTerminal`
        nonisolated public struct Terminal: Api.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.SubwayOriginTerminal }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("stationID", String.self),
            .field("name", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SubwayTimetablePageQuery.Data.Subway.Timetable.Terminal.self
          ] }

          public var stationID: String { __data["stationID"] }
          public var name: String { __data["name"] }
        }
      }
    }
  }
}
