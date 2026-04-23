// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct BusTimetablePageQuery: GraphQLQuery {
  public static let operationName: String = "BusTimetablePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusTimetablePageQuery($routeStops: [BusRouteStopInput!]!) { bus(input: $routeStops) { __typename route { __typename name } timetable { __typename weekday time } } }"#
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
      BusTimetablePageQuery.Data.self
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
        .field("timetable", [Timetable].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        BusTimetablePageQuery.Data.Bus.self
      ] }

      public var route: Route { __data["route"] }
      public var timetable: [Timetable] { __data["timetable"] }

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
          BusTimetablePageQuery.Data.Bus.Route.self
        ] }

        public var name: String { __data["name"] }
      }

      /// Bus.Timetable
      ///
      /// Parent Type: `BusTimetable`
      nonisolated public struct Timetable: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusTimetable }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("weekday", String.self),
          .field("time", Api.LocalTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusTimetablePageQuery.Data.Bus.Timetable.self
        ] }

        public var weekday: String { __data["weekday"] }
        public var time: Api.LocalTime { __data["time"] }
      }
    }
  }
}
