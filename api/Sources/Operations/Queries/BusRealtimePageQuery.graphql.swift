// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct BusRealtimePageQuery: GraphQLQuery {
  public static let operationName: String = "BusRealtimePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusRealtimePageQuery($language: String!) { notices(input: { language: $language, category: "버스" }) { __typename notices { __typename title url expiredAt } } bus( input: [ { route: 216000068, stop: 216000138, limit: 3 } { route: 216000068, stop: 216000383, limit: 3 } { route: 216000068, stop: 216000381, limit: 3 } { route: 216000068, stop: 216000379, limit: 3 } { route: 216000061, stop: 216000383, limit: 3 } { route: 216000061, stop: 216000381, limit: 3 } { route: 216000061, stop: 216000379, limit: 3 } { route: 216000043, stop: 216000719, limit: 3 } { route: 216000026, stop: 216000719, limit: 3 } { route: 216000096, stop: 216000719, limit: 3 } { route: 216000104, stop: 216000070, limit: 3 } { route: 200000015, stop: 216000070, limit: 3 } { route: 216000075, stop: 216000759, limit: 3 } { route: 216000075, stop: 213000487, limit: 3 } { route: 216000016, stop: 216000152, limit: 3 } ] ) { __typename route { __typename seq name } stop { __typename seq } order arrival { __typename stops seats minutes lowFloor isRealtime time } } }"#
    ))

  public var language: String

  public init(language: String) {
    self.language = language
  }

  @_spi(Unsafe) public var __variables: Variables? { ["language": language] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("notices", [Notice].self, arguments: ["input": [
        "language": .variable("language"),
        "category": "버스"
      ]]),
      .field("bus", [Bus].self, arguments: ["input": [[
        "route": 216000068,
        "stop": 216000138,
        "limit": 3
      ], [
        "route": 216000068,
        "stop": 216000383,
        "limit": 3
      ], [
        "route": 216000068,
        "stop": 216000381,
        "limit": 3
      ], [
        "route": 216000068,
        "stop": 216000379,
        "limit": 3
      ], [
        "route": 216000061,
        "stop": 216000383,
        "limit": 3
      ], [
        "route": 216000061,
        "stop": 216000381,
        "limit": 3
      ], [
        "route": 216000061,
        "stop": 216000379,
        "limit": 3
      ], [
        "route": 216000043,
        "stop": 216000719,
        "limit": 3
      ], [
        "route": 216000026,
        "stop": 216000719,
        "limit": 3
      ], [
        "route": 216000096,
        "stop": 216000719,
        "limit": 3
      ], [
        "route": 216000104,
        "stop": 216000070,
        "limit": 3
      ], [
        "route": 200000015,
        "stop": 216000070,
        "limit": 3
      ], [
        "route": 216000075,
        "stop": 216000759,
        "limit": 3
      ], [
        "route": 216000075,
        "stop": 213000487,
        "limit": 3
      ], [
        "route": 216000016,
        "stop": 216000152,
        "limit": 3
      ]]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      BusRealtimePageQuery.Data.self
    ] }

    public var notices: [Notice] { __data["notices"] }
    public var bus: [Bus] { __data["bus"] }

    /// Notice
    ///
    /// Parent Type: `NoticeCategory`
    nonisolated public struct Notice: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.NoticeCategory }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("notices", [Notice].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        BusRealtimePageQuery.Data.Notice.self
      ] }

      public var notices: [Notice] { __data["notices"] }

      /// Notice.Notice
      ///
      /// Parent Type: `Notice`
      nonisolated public struct Notice: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Notice }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("title", String.self),
          .field("url", String.self),
          .field("expiredAt", Api.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusRealtimePageQuery.Data.Notice.Notice.self
        ] }

        public var title: String { __data["title"] }
        public var url: String { __data["url"] }
        public var expiredAt: Api.DateTime { __data["expiredAt"] }
      }
    }

    /// Bus
    ///
    /// Parent Type: `BusRouteStop`
    nonisolated public struct Bus: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusRouteStop }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("route", Route.self),
        .field("stop", Stop.self),
        .field("order", Int.self),
        .field("arrival", [Arrival].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        BusRealtimePageQuery.Data.Bus.self
      ] }

      public var route: Route { __data["route"] }
      public var stop: Stop { __data["stop"] }
      public var order: Int { __data["order"] }
      public var arrival: [Arrival] { __data["arrival"] }

      /// Bus.Route
      ///
      /// Parent Type: `BusRoute`
      nonisolated public struct Route: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusRoute }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("seq", Int.self),
          .field("name", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusRealtimePageQuery.Data.Bus.Route.self
        ] }

        public var seq: Int { __data["seq"] }
        public var name: String { __data["name"] }
      }

      /// Bus.Stop
      ///
      /// Parent Type: `BusStop`
      nonisolated public struct Stop: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusStop }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("seq", Int.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusRealtimePageQuery.Data.Bus.Stop.self
        ] }

        public var seq: Int { __data["seq"] }
      }

      /// Bus.Arrival
      ///
      /// Parent Type: `BusArrival`
      nonisolated public struct Arrival: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusArrival }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("stops", Int?.self),
          .field("seats", Int?.self),
          .field("minutes", Int?.self),
          .field("lowFloor", Bool?.self),
          .field("isRealtime", Bool.self),
          .field("time", Api.LocalTime?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusRealtimePageQuery.Data.Bus.Arrival.self
        ] }

        public var stops: Int? { __data["stops"] }
        public var seats: Int? { __data["seats"] }
        public var minutes: Int? { __data["minutes"] }
        public var lowFloor: Bool? { __data["lowFloor"] }
        public var isRealtime: Bool { __data["isRealtime"] }
        public var time: Api.LocalTime? { __data["time"] }
      }
    }
  }
}
