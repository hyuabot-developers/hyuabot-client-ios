// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct BusSecondaryEtaLogQuery: GraphQLQuery {
  public static let operationName: String = "BusSecondaryEtaLogQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusSecondaryEtaLogQuery($dates: [Date!]!) { bus( input: [ { route: 216000068, stop: 216000138, limit: 3, dates: $dates } { route: 216000068, stop: 216000383, limit: 3, dates: $dates } { route: 216000068, stop: 216000381, limit: 3, dates: $dates } { route: 216000068, stop: 216000379, limit: 3, dates: $dates } { route: 216000068, stop: 216000378, limit: 3, dates: $dates } { route: 216000061, stop: 216000383, limit: 3, dates: $dates } { route: 216000061, stop: 216000381, limit: 3, dates: $dates } { route: 216000061, stop: 216000379, limit: 3, dates: $dates } { route: 216000061, stop: 216000378, limit: 3, dates: $dates } { route: 216000061, stop: 121000060, limit: 3, dates: $dates } { route: 216000061, stop: 121000929, limit: 3, dates: $dates } { route: 216000061, stop: 121000974, limit: 3, dates: $dates } { route: 216000061, stop: 121000970, limit: 3, dates: $dates } { route: 216000061, stop: 121000220, limit: 3, dates: $dates } { route: 216000043, stop: 216000719, limit: 3, dates: $dates } { route: 216000043, stop: 216000048, limit: 3, dates: $dates } { route: 216000043, stop: 121000060, limit: 3, dates: $dates } { route: 216000043, stop: 121000929, limit: 3, dates: $dates } { route: 216000043, stop: 121000974, limit: 3, dates: $dates } { route: 216000043, stop: 121000970, limit: 3, dates: $dates } { route: 216000043, stop: 121000220, limit: 3, dates: $dates } { route: 216000026, stop: 216000719, limit: 3, dates: $dates } { route: 216000026, stop: 216000048, limit: 3, dates: $dates } { route: 216000026, stop: 121000060, limit: 3, dates: $dates } { route: 216000026, stop: 121000929, limit: 3, dates: $dates } { route: 216000026, stop: 121000974, limit: 3, dates: $dates } { route: 216000026, stop: 121000970, limit: 3, dates: $dates } { route: 216000026, stop: 121000220, limit: 3, dates: $dates } { route: 216000096, stop: 216000719, limit: 3, dates: $dates } { route: 216000096, stop: 216000048, limit: 3, dates: $dates } { route: 216000096, stop: 121000060, limit: 3, dates: $dates } { route: 216000096, stop: 121000929, limit: 3, dates: $dates } { route: 216000096, stop: 121000974, limit: 3, dates: $dates } { route: 216000096, stop: 121000970, limit: 3, dates: $dates } { route: 216000096, stop: 121000220, limit: 3, dates: $dates } { route: 216000104, stop: 216000070, limit: 3, dates: $dates } { route: 216000104, stop: 216000141, limit: 3, dates: $dates } { route: 216000104, stop: 202000208, limit: 3, dates: $dates } { route: 216000104, stop: 202000106, limit: 3, dates: $dates } { route: 200000015, stop: 216000070, limit: 3, dates: $dates } { route: 200000015, stop: 216000141, limit: 3, dates: $dates } { route: 200000015, stop: 202000208, limit: 3, dates: $dates } { route: 200000015, stop: 202000106, limit: 3, dates: $dates } { route: 216000075, stop: 216000759, limit: 3, dates: $dates } { route: 216000075, stop: 213000487, limit: 3, dates: $dates } { route: 216000075, stop: 216000117, limit: 3, dates: $dates } { route: 216000016, stop: 216000152, limit: 3, dates: $dates } ] ) { __typename route { __typename seq } stop { __typename seq } log { __typename date time vehicle } } }"#
    ))

  public var dates: [Date]

  public init(dates: [Date]) {
    self.dates = dates
  }

  @_spi(Unsafe) public var __variables: Variables? { ["dates": dates] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("bus", [Bus].self, arguments: ["input": [[
        "route": 216000068,
        "stop": 216000138,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000068,
        "stop": 216000383,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000068,
        "stop": 216000381,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000068,
        "stop": 216000379,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000068,
        "stop": 216000378,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000061,
        "stop": 216000383,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000061,
        "stop": 216000381,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000061,
        "stop": 216000379,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000061,
        "stop": 216000378,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000061,
        "stop": 121000060,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000061,
        "stop": 121000929,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000061,
        "stop": 121000974,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000061,
        "stop": 121000970,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000061,
        "stop": 121000220,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000043,
        "stop": 216000719,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000043,
        "stop": 216000048,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000043,
        "stop": 121000060,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000043,
        "stop": 121000929,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000043,
        "stop": 121000974,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000043,
        "stop": 121000970,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000043,
        "stop": 121000220,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000026,
        "stop": 216000719,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000026,
        "stop": 216000048,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000026,
        "stop": 121000060,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000026,
        "stop": 121000929,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000026,
        "stop": 121000974,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000026,
        "stop": 121000970,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000026,
        "stop": 121000220,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000096,
        "stop": 216000719,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000096,
        "stop": 216000048,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000096,
        "stop": 121000060,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000096,
        "stop": 121000929,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000096,
        "stop": 121000974,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000096,
        "stop": 121000970,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000096,
        "stop": 121000220,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000104,
        "stop": 216000070,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000104,
        "stop": 216000141,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000104,
        "stop": 202000208,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000104,
        "stop": 202000106,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 200000015,
        "stop": 216000070,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 200000015,
        "stop": 216000141,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 200000015,
        "stop": 202000208,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 200000015,
        "stop": 202000106,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000075,
        "stop": 216000759,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000075,
        "stop": 213000487,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000075,
        "stop": 216000117,
        "limit": 3,
        "dates": .variable("dates")
      ], [
        "route": 216000016,
        "stop": 216000152,
        "limit": 3,
        "dates": .variable("dates")
      ]]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      BusSecondaryEtaLogQuery.Data.self
    ] }

    public var bus: [Bus] { __data["bus"] }

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
        .field("log", [Log].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        BusSecondaryEtaLogQuery.Data.Bus.self
      ] }

      public var route: Route { __data["route"] }
      public var stop: Stop { __data["stop"] }
      public var log: [Log] { __data["log"] }

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
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusSecondaryEtaLogQuery.Data.Bus.Route.self
        ] }

        public var seq: Int { __data["seq"] }
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
          BusSecondaryEtaLogQuery.Data.Bus.Stop.self
        ] }

        public var seq: Int { __data["seq"] }
      }

      /// Bus.Log
      ///
      /// Parent Type: `BusDepartureLog`
      nonisolated public struct Log: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusDepartureLog }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("date", Api.Date.self),
          .field("time", Api.LocalTime.self),
          .field("vehicle", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusSecondaryEtaLogQuery.Data.Bus.Log.self
        ] }

        public var date: Api.Date { __data["date"] }
        public var time: Api.LocalTime { __data["time"] }
        public var vehicle: String { __data["vehicle"] }
      }
    }
  }
}
