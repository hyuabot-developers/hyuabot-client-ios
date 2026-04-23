// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ShuttleRealtimePageWatchQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleRealtimePageWatchQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleRealtimePageWatchQuery($stops: [ShuttleStopInput!]!, $after: LocalTime) { shuttle(input: { stops: $stops, after: $after }) { __typename stops { __typename latitude longitude name timetable { __typename destination { __typename destination entries { __typename route { __typename tag name } time stops { __typename stop time } } } } } } }"#
    ))

  public var stops: [ShuttleStopInput]
  public var after: GraphQLNullable<LocalTime>

  public init(
    stops: [ShuttleStopInput],
    after: GraphQLNullable<LocalTime>
  ) {
    self.stops = stops
    self.after = after
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "stops": stops,
    "after": after
  ] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("shuttle", Shuttle.self, arguments: ["input": [
        "stops": .variable("stops"),
        "after": .variable("after")
      ]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ShuttleRealtimePageWatchQuery.Data.self
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
        ShuttleRealtimePageWatchQuery.Data.Shuttle.self
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
          .field("latitude", Double.self),
          .field("longitude", Double.self),
          .field("name", String.self),
          .field("timetable", Timetable.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.self
        ] }

        public var latitude: Double { __data["latitude"] }
        public var longitude: Double { __data["longitude"] }
        public var name: String { __data["name"] }
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
            .field("destination", [Destination].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.self
          ] }

          public var destination: [Destination] { __data["destination"] }

          /// Shuttle.Stop.Timetable.Destination
          ///
          /// Parent Type: `ShuttleTimetableGroup`
          nonisolated public struct Destination: Api.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttleTimetableGroup }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("destination", String.self),
              .field("entries", [Entry].self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.self
            ] }

            public var destination: String { __data["destination"] }
            public var entries: [Entry] { __data["entries"] }

            /// Shuttle.Stop.Timetable.Destination.Entry
            ///
            /// Parent Type: `ShuttleTimetableEntry`
            nonisolated public struct Entry: Api.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttleTimetableEntry }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("route", Route.self),
                .field("time", Api.LocalTime.self),
                .field("stops", [Stop].self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry.self
              ] }

              public var route: Route { __data["route"] }
              public var time: Api.LocalTime { __data["time"] }
              public var stops: [Stop] { __data["stops"] }

              /// Shuttle.Stop.Timetable.Destination.Entry.Route
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
                  ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry.Route.self
                ] }

                public var tag: String { __data["tag"] }
                public var name: String { __data["name"] }
              }

              /// Shuttle.Stop.Timetable.Destination.Entry.Stop
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
                  ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry.Stop.self
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
}
