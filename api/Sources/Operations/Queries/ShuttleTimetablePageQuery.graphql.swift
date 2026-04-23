// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ShuttleTimetablePageQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleTimetablePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleTimetablePageQuery($period: [String!]!, $stopID: String!, $destination: [String!]!) { shuttle( input: { stops: [ { name: $stopID limit: { order: null, destination: null } destinations: $destination } ] periods: $period weekdays: [true, false] } ) { __typename stops { __typename timetable { __typename order { __typename time weekday route { __typename tag name } stops { __typename stop time } } } } } }"#
    ))

  public var period: [String]
  public var stopID: String
  public var destination: [String]

  public init(
    period: [String],
    stopID: String,
    destination: [String]
  ) {
    self.period = period
    self.stopID = stopID
    self.destination = destination
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "period": period,
    "stopID": stopID,
    "destination": destination
  ] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("shuttle", Shuttle.self, arguments: ["input": [
        "stops": [[
          "name": .variable("stopID"),
          "limit": [
            "order": .null,
            "destination": .null
          ],
          "destinations": .variable("destination")
        ]],
        "periods": .variable("period"),
        "weekdays": [true, false]
      ]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ShuttleTimetablePageQuery.Data.self
    ] }

    public var shuttle: Shuttle { __data["shuttle"] }

    /// Shuttle
    ///
    /// Parent Type: `Shuttle`
    nonisolated public struct Shuttle: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Shuttle }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("stops", [Stop].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ShuttleTimetablePageQuery.Data.Shuttle.self
      ] }

      public var stops: [Stop] { __data["stops"] }

      /// Shuttle.Stop
      ///
      /// Parent Type: `ShuttleStop`
      nonisolated public struct Stop: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttleStop }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("timetable", Timetable.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ShuttleTimetablePageQuery.Data.Shuttle.Stop.self
        ] }

        public var timetable: Timetable { __data["timetable"] }

        /// Shuttle.Stop.Timetable
        ///
        /// Parent Type: `ShuttleTimetable`
        nonisolated public struct Timetable: Api.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttleTimetable }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("order", [Order].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.self
          ] }

          public var order: [Order] { __data["order"] }

          /// Shuttle.Stop.Timetable.Order
          ///
          /// Parent Type: `ShuttleTimetableEntry`
          nonisolated public struct Order: Api.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttleTimetableEntry }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("time", Api.LocalTime.self),
              .field("weekday", Bool.self),
              .field("route", Route.self),
              .field("stops", [Stop].self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order.self
            ] }

            public var time: Api.LocalTime { __data["time"] }
            public var weekday: Bool { __data["weekday"] }
            public var route: Route { __data["route"] }
            public var stops: [Stop] { __data["stops"] }

            /// Shuttle.Stop.Timetable.Order.Route
            ///
            /// Parent Type: `ShuttleRoute`
            nonisolated public struct Route: Api.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttleRoute }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("tag", String.self),
                .field("name", String.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order.Route.self
              ] }

              public var tag: String { __data["tag"] }
              public var name: String { __data["name"] }
            }

            /// Shuttle.Stop.Timetable.Order.Stop
            ///
            /// Parent Type: `ShuttleArrival`
            nonisolated public struct Stop: Api.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttleArrival }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("stop", String.self),
                .field("time", Api.LocalTime.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order.Stop.self
              ] }

              public var stop: String { __data["stop"] }
              public var time: Api.LocalTime { __data["time"] }
            }
          }
        }
      }
    }
  }
}
