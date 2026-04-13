// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct BusRouteInfoDialogQuery: GraphQLQuery {
  public static let operationName: String = "BusRouteInfoDialogQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusRouteInfoDialogQuery($routeID: Int!, $stopID: Int!) { bus( input: [ { route: $routeID, stop: $stopID, weekdays: ["weekdays", "saturday", "sunday"] } ] ) { __typename route { __typename name } startStop { __typename name } minutes } }"#
    ))

  public var routeID: Int32
  public var stopID: Int32

  public init(
    routeID: Int32,
    stopID: Int32
  ) {
    self.routeID = routeID
    self.stopID = stopID
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "routeID": routeID,
    "stopID": stopID
  ] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("bus", [Bus].self, arguments: ["input": [[
        "route": .variable("routeID"),
        "stop": .variable("stopID"),
        "weekdays": ["weekdays", "saturday", "sunday"]
      ]]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      BusRouteInfoDialogQuery.Data.self
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
        .field("startStop", StartStop.self),
        .field("minutes", Int.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        BusRouteInfoDialogQuery.Data.Bus.self
      ] }

      public var route: Route { __data["route"] }
      public var startStop: StartStop { __data["startStop"] }
      public var minutes: Int { __data["minutes"] }

      /// Bus.Route
      ///
      /// Parent Type: `BusRoute`
      nonisolated public struct Route: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusRoute }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("name", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusRouteInfoDialogQuery.Data.Bus.Route.self
        ] }

        public var name: String { __data["name"] }
      }

      /// Bus.StartStop
      ///
      /// Parent Type: `BusStop`
      nonisolated public struct StartStop: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusStop }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("name", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusRouteInfoDialogQuery.Data.Bus.StartStop.self
        ] }

        public var name: String { __data["name"] }
      }
    }
  }
}
