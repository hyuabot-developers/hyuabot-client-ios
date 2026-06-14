// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ShuttleBusAlternativeQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleBusAlternativeQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleBusAlternativeQuery { bus(input: [{ route: 216000068, stop: 216000383, limit: 1 } { route: 216000068, stop: 216000379, limit: 1 }]) { __typename stop { __typename seq } arrival { __typename stops seats minutes lowFloor isRealtime time } } }"#
    ))

  public init() {}

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("bus", [Bus].self, arguments: ["input": [["route": 216000068, "stop": 216000383, "limit": 1], ["route": 216000068, "stop": 216000379, "limit": 1]]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ShuttleBusAlternativeQuery.Data.self
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
        .field("stop", Stop.self),
        .field("arrival", [Arrival].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ShuttleBusAlternativeQuery.Data.Bus.self
      ] }

      public var stop: Stop { __data["stop"] }
      public var arrival: [Arrival] { __data["arrival"] }

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
          ShuttleBusAlternativeQuery.Data.Bus.Stop.self
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
          .field("lowFloor", Bool.self),
          .field("isRealtime", Bool.self),
          .field("time", Api.LocalTime?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ShuttleBusAlternativeQuery.Data.Bus.Arrival.self
        ] }

        public var stops: Int? { __data["stops"] }
        public var seats: Int? { __data["seats"] }
        public var minutes: Int? { __data["minutes"] }
        public var lowFloor: Bool { __data["lowFloor"] }
        public var isRealtime: Bool { __data["isRealtime"] }
        public var time: Api.LocalTime? { __data["time"] }
      }
    }
  }
}
