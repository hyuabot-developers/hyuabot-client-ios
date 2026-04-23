// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct SubwayRealtimePageQuery: GraphQLQuery {
  public static let operationName: String = "SubwayRealtimePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query SubwayRealtimePageQuery($weekday: String!) { subway( input: { keys: [ { stationID: "K449", direction: ["up", "down"], weekdays: [$weekday], limit: 4 } { stationID: "K456" direction: ["up", "down"] weekdays: [$weekday] limit: null } { stationID: "K251", direction: ["up", "down"], weekdays: [$weekday], limit: 4 } { stationID: "K258" direction: ["up", "down"] weekdays: [$weekday] limit: null } ] } ) { __typename stationID arrival { __typename direction entries { __typename minutes origin { __typename stationID name } terminal { __typename stationID name } isRealtime location stops trainNumber isExpress isLast status } } } }"#
    ))

  public var weekday: String

  public init(weekday: String) {
    self.weekday = weekday
  }

  @_spi(Unsafe) public var __variables: Variables? { ["weekday": weekday] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("subway", [Subway].self, arguments: ["input": ["keys": [[
        "stationID": "K449",
        "direction": ["up", "down"],
        "weekdays": [.variable("weekday")],
        "limit": 4
      ], [
        "stationID": "K456",
        "direction": ["up", "down"],
        "weekdays": [.variable("weekday")],
        "limit": .null
      ], [
        "stationID": "K251",
        "direction": ["up", "down"],
        "weekdays": [.variable("weekday")],
        "limit": 4
      ], [
        "stationID": "K258",
        "direction": ["up", "down"],
        "weekdays": [.variable("weekday")],
        "limit": .null
      ]]]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      SubwayRealtimePageQuery.Data.self
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
        .field("stationID", String.self),
        .field("arrival", [Arrival].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SubwayRealtimePageQuery.Data.Subway.self
      ] }

      public var stationID: String { __data["stationID"] }
      public var arrival: [Arrival] { __data["arrival"] }

      /// Subway.Arrival
      ///
      /// Parent Type: `SubwayArrivalGroup`
      nonisolated public struct Arrival: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.SubwayArrivalGroup }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("direction", String.self),
          .field("entries", [Entry].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SubwayRealtimePageQuery.Data.Subway.Arrival.self
        ] }

        public var direction: String { __data["direction"] }
        public var entries: [Entry] { __data["entries"] }

        /// Subway.Arrival.Entry
        ///
        /// Parent Type: `SubwayArrival`
        nonisolated public struct Entry: Api.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.SubwayArrival }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("minutes", Int.self),
            .field("origin", Origin?.self),
            .field("terminal", Terminal.self),
            .field("isRealtime", Bool.self),
            .field("location", String?.self),
            .field("stops", Int?.self),
            .field("trainNumber", String?.self),
            .field("isExpress", Bool?.self),
            .field("isLast", Bool?.self),
            .field("status", Int?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SubwayRealtimePageQuery.Data.Subway.Arrival.Entry.self
          ] }

          public var minutes: Int { __data["minutes"] }
          public var origin: Origin? { __data["origin"] }
          public var terminal: Terminal { __data["terminal"] }
          public var isRealtime: Bool { __data["isRealtime"] }
          public var location: String? { __data["location"] }
          public var stops: Int? { __data["stops"] }
          public var trainNumber: String? { __data["trainNumber"] }
          public var isExpress: Bool? { __data["isExpress"] }
          public var isLast: Bool? { __data["isLast"] }
          public var status: Int? { __data["status"] }

          /// Subway.Arrival.Entry.Origin
          ///
          /// Parent Type: `SubwayOriginTerminal`
          nonisolated public struct Origin: Api.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.SubwayOriginTerminal }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("stationID", String.self),
              .field("name", String.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              SubwayRealtimePageQuery.Data.Subway.Arrival.Entry.Origin.self
            ] }

            public var stationID: String { __data["stationID"] }
            public var name: String { __data["name"] }
          }

          /// Subway.Arrival.Entry.Terminal
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
              SubwayRealtimePageQuery.Data.Subway.Arrival.Entry.Terminal.self
            ] }

            public var stationID: String { __data["stationID"] }
            public var name: String { __data["name"] }
          }
        }
      }
    }
  }
}
