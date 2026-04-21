// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct BusStopDialogQuery: GraphQLQuery {
  public static let operationName: String = "BusStopDialogQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusStopDialogQuery($routeStops: [BusRouteStopInput!]!) { bus(input: $routeStops) { __typename stop { __typename name latitude longitude } route { __typename name runningTime { __typename up { __typename first last terminal { __typename seq name } } down { __typename first last terminal { __typename seq name } } } } } }"#
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
      BusStopDialogQuery.Data.self
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
        .field("route", Route.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        BusStopDialogQuery.Data.Bus.self
      ] }

      public var stop: Stop { __data["stop"] }
      public var route: Route { __data["route"] }

      /// Bus.Stop
      ///
      /// Parent Type: `BusStop`
      nonisolated public struct Stop: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusStop }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("name", String.self),
          .field("latitude", Double.self),
          .field("longitude", Double.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusStopDialogQuery.Data.Bus.Stop.self
        ] }

        public var name: String { __data["name"] }
        public var latitude: Double { __data["latitude"] }
        public var longitude: Double { __data["longitude"] }
      }

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
          .field("runningTime", RunningTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BusStopDialogQuery.Data.Bus.Route.self
        ] }

        public var name: String { __data["name"] }
        public var runningTime: RunningTime { __data["runningTime"] }

        /// Bus.Route.RunningTime
        ///
        /// Parent Type: `BusRunningTime`
        nonisolated public struct RunningTime: Api.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusRunningTime }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("up", Up.self),
            .field("down", Down.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            BusStopDialogQuery.Data.Bus.Route.RunningTime.self
          ] }

          public var up: Up { __data["up"] }
          public var down: Down { __data["down"] }

          /// Bus.Route.RunningTime.Up
          ///
          /// Parent Type: `BusRunningTimeEntry`
          nonisolated public struct Up: Api.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusRunningTimeEntry }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("first", Api.LocalTime.self),
              .field("last", Api.LocalTime.self),
              .field("terminal", Terminal.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              BusStopDialogQuery.Data.Bus.Route.RunningTime.Up.self
            ] }

            public var first: Api.LocalTime { __data["first"] }
            public var last: Api.LocalTime { __data["last"] }
            public var terminal: Terminal { __data["terminal"] }

            /// Bus.Route.RunningTime.Up.Terminal
            ///
            /// Parent Type: `BusStop`
            nonisolated public struct Terminal: Api.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusStop }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("seq", Int.self),
                .field("name", String.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                BusStopDialogQuery.Data.Bus.Route.RunningTime.Up.Terminal.self
              ] }

              public var seq: Int { __data["seq"] }
              public var name: String { __data["name"] }
            }
          }

          /// Bus.Route.RunningTime.Down
          ///
          /// Parent Type: `BusRunningTimeEntry`
          nonisolated public struct Down: Api.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusRunningTimeEntry }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("first", Api.LocalTime.self),
              .field("last", Api.LocalTime.self),
              .field("terminal", Terminal.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              BusStopDialogQuery.Data.Bus.Route.RunningTime.Down.self
            ] }

            public var first: Api.LocalTime { __data["first"] }
            public var last: Api.LocalTime { __data["last"] }
            public var terminal: Terminal { __data["terminal"] }

            /// Bus.Route.RunningTime.Down.Terminal
            ///
            /// Parent Type: `BusStop`
            nonisolated public struct Terminal: Api.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusStop }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("seq", Int.self),
                .field("name", String.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                BusStopDialogQuery.Data.Bus.Route.RunningTime.Down.Terminal.self
              ] }

              public var seq: Int { __data["seq"] }
              public var name: String { __data["name"] }
            }
          }
        }
      }
    }
  }
}
