// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct BusDepartureLogDialogQuery: GraphQLQuery {
  public static let operationName: String = "BusDepartureLogDialogQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusDepartureLogDialogQuery($routeStops: [BusRouteStopInput!]!) { bus(input: $routeStops) { __typename log { __typename date time } } }"#
    ))

  public var routeStops: [BusRouteStopInput]

  public init(routeStops: [BusRouteStopInput]) {
    self.routeStops = routeStops
  }

  @_spi(Unsafe) public var __variables: Variables? { ["routeStops": routeStops] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("bus", [Bus].self, arguments: ["input": .variable("routeStops")]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      BusDepartureLogDialogQuery.Data.self
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
        .field("log", [Log].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        BusDepartureLogDialogQuery.Data.Bus.self
      ] }

      public var log: [Log] { __data["log"] }

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
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusDepartureLogDialogQuery.Data.Bus.Log.self
        ] }

        public var date: Api.Date { __data["date"] }
        public var time: Api.LocalTime { __data["time"] }
      }
    }
  }
}
