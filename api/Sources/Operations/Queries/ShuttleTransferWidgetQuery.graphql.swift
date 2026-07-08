// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ShuttleTransferWidgetQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleTransferWidgetQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleTransferWidgetQuery($after: LocalTime, $weekday: String!, $logDates: [Date!]) { shuttle( input: { stops: [ { name: "dormitory_o", limit: { order: 0, destination: 8 } } { name: "shuttlecock_o", limit: { order: 0, destination: 8 } } { name: "station", limit: { order: 0, destination: 8 } } { name: "terminal", limit: { order: 0, destination: 8 } } { name: "jungang_stn", limit: { order: 0, destination: 8 } } { name: "shuttlecock_i", limit: { order: 0, destination: 8 } } ] after: $after } ) { __typename stops { __typename latitude longitude name timetable { __typename destination { __typename destination entries { __typename time } } } } } subway( input: { keys: [ { stationID: "K449", direction: ["up", "down"], weekdays: [$weekday], limit: 1 } { stationID: "K251", direction: ["up", "down"], weekdays: [$weekday], limit: 1 } ] } ) { __typename stationID arrival { __typename direction entries { __typename minutes terminal { __typename stationID name } } } } transferBus: bus( input: [ { route: 216000075, stop: 216000759, limit: 2, dates: $logDates } { route: 216000075, stop: 216000117, limit: 2, dates: $logDates } ] ) { __typename route { __typename seq name } stop { __typename seq } arrival { __typename minutes stops } log { __typename date time } } }"#
    ))

  public var after: GraphQLNullable<LocalTime>
  public var weekday: String
  public var logDates: GraphQLNullable<[Date]>

  public init(
    after: GraphQLNullable<LocalTime>,
    weekday: String,
    logDates: GraphQLNullable<[Date]>
  ) {
    self.after = after
    self.weekday = weekday
    self.logDates = logDates
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "after": after,
    "weekday": weekday,
    "logDates": logDates
  ] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("shuttle", Shuttle.self, arguments: ["input": [
        "stops": [[
          "name": "dormitory_o",
          "limit": [
            "order": 0,
            "destination": 8
          ]
        ], [
          "name": "shuttlecock_o",
          "limit": [
            "order": 0,
            "destination": 8
          ]
        ], [
          "name": "station",
          "limit": [
            "order": 0,
            "destination": 8
          ]
        ], [
          "name": "terminal",
          "limit": [
            "order": 0,
            "destination": 8
          ]
        ], [
          "name": "jungang_stn",
          "limit": [
            "order": 0,
            "destination": 8
          ]
        ], [
          "name": "shuttlecock_i",
          "limit": [
            "order": 0,
            "destination": 8
          ]
        ]],
        "after": .variable("after")
      ]]),
      .field("subway", [Subway].self, arguments: ["input": ["keys": [[
        "stationID": "K449",
        "direction": ["up", "down"],
        "weekdays": [.variable("weekday")],
        "limit": 1
      ], [
        "stationID": "K251",
        "direction": ["up", "down"],
        "weekdays": [.variable("weekday")],
        "limit": 1
      ]]]]),
      .field("bus", alias: "transferBus", [TransferBus].self, arguments: ["input": [[
        "route": 216000075,
        "stop": 216000759,
        "limit": 2,
        "dates": .variable("logDates")
      ], [
        "route": 216000075,
        "stop": 216000117,
        "limit": 2,
        "dates": .variable("logDates")
      ]]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ShuttleTransferWidgetQuery.Data.self
    ] }

    public var shuttle: Shuttle { __data["shuttle"] }
    public var subway: [Subway] { __data["subway"] }
    public var transferBus: [TransferBus] { __data["transferBus"] }

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
        ShuttleTransferWidgetQuery.Data.Shuttle.self
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
          ShuttleTransferWidgetQuery.Data.Shuttle.Stop.self
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
            ShuttleTransferWidgetQuery.Data.Shuttle.Stop.Timetable.self
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
              ShuttleTransferWidgetQuery.Data.Shuttle.Stop.Timetable.Destination.self
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
                .field("time", Api.LocalTime.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                ShuttleTransferWidgetQuery.Data.Shuttle.Stop.Timetable.Destination.Entry.self
              ] }

              public var time: Api.LocalTime { __data["time"] }
            }
          }
        }
      }
    }

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
        ShuttleTransferWidgetQuery.Data.Subway.self
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
          ShuttleTransferWidgetQuery.Data.Subway.Arrival.self
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
            .field("terminal", Terminal.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ShuttleTransferWidgetQuery.Data.Subway.Arrival.Entry.self
          ] }

          public var minutes: Int { __data["minutes"] }
          public var terminal: Terminal { __data["terminal"] }

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
              ShuttleTransferWidgetQuery.Data.Subway.Arrival.Entry.Terminal.self
            ] }

            public var stationID: String { __data["stationID"] }
            public var name: String { __data["name"] }
          }
        }
      }
    }

    /// TransferBus
    ///
    /// Parent Type: `BusRouteStop`
    nonisolated public struct TransferBus: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusRouteStop }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("route", Route.self),
        .field("stop", Stop.self),
        .field("arrival", [Arrival].self),
        .field("log", [Log].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ShuttleTransferWidgetQuery.Data.TransferBus.self
      ] }

      public var route: Route { __data["route"] }
      public var stop: Stop { __data["stop"] }
      public var arrival: [Arrival] { __data["arrival"] }
      public var log: [Log] { __data["log"] }

      /// TransferBus.Route
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
          ShuttleTransferWidgetQuery.Data.TransferBus.Route.self
        ] }

        public var seq: Int { __data["seq"] }
        public var name: String { __data["name"] }
      }

      /// TransferBus.Stop
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
          ShuttleTransferWidgetQuery.Data.TransferBus.Stop.self
        ] }

        public var seq: Int { __data["seq"] }
      }

      /// TransferBus.Arrival
      ///
      /// Parent Type: `BusArrival`
      nonisolated public struct Arrival: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.BusArrival }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("minutes", Int?.self),
          .field("stops", Int?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ShuttleTransferWidgetQuery.Data.TransferBus.Arrival.self
        ] }

        public var minutes: Int? { __data["minutes"] }
        public var stops: Int? { __data["stops"] }
      }

      /// TransferBus.Log
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
          ShuttleTransferWidgetQuery.Data.TransferBus.Log.self
        ] }

        public var date: Api.Date { __data["date"] }
        public var time: Api.LocalTime { __data["time"] }
      }
    }
  }
}
