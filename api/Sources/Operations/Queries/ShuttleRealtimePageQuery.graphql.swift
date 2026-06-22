// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ShuttleRealtimePageQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleRealtimePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleRealtimePageQuery($language: String!, $after: LocalTime, $weekday: String!) { notices(input: { language: $language, category: "셔틀,날씨" }) { __typename notices { __typename title url expiredAt } } shuttle( input: { stops: [ { name: "dormitory_o", limit: { order: 8, destination: 3 } } { name: "shuttlecock_o", limit: { order: 8, destination: 3 } } { name: "station", limit: { order: 8, destination: 3 } } { name: "terminal", limit: { order: 8, destination: 8 } } { name: "jungang_stn", limit: { order: 8, destination: 8 } } { name: "shuttlecock_i", limit: { order: 8, destination: 8 } } ] after: $after } ) { __typename stops { __typename latitude longitude name timetable { __typename order { __typename route { __typename tag name } time stops { __typename stop time } } destination { __typename destination entries { __typename route { __typename tag name } time stops { __typename stop time } } } } } } subway( input: { keys: [ { stationID: "K449", direction: ["up", "down"], weekdays: [$weekday], limit: 2 } { stationID: "K251", direction: ["up", "down"], weekdays: [$weekday], limit: 2 } ] } ) { __typename stationID arrival { __typename direction entries { __typename minutes isRealtime location stops terminal { __typename stationID name } } } } transferBus: bus( input: [ { route: 216000075, stop: 216000759, limit: 2 } { route: 216000075, stop: 216000117, limit: 2 } ] ) { __typename route { __typename seq name } stop { __typename seq } arrival { __typename minutes stops isRealtime } } }"#
    ))

  public var language: String
  public var after: GraphQLNullable<LocalTime>
  public var weekday: String

  public init(
    language: String,
    after: GraphQLNullable<LocalTime>,
    weekday: String
  ) {
    self.language = language
    self.after = after
    self.weekday = weekday
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "language": language,
    "after": after,
    "weekday": weekday
  ] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("notices", [Notice].self, arguments: ["input": [
        "language": .variable("language"),
        "category": "셔틀,날씨"
      ]]),
      .field("shuttle", Shuttle.self, arguments: ["input": [
        "stops": [[
          "name": "dormitory_o",
          "limit": [
            "order": 8,
            "destination": 3
          ]
        ], [
          "name": "shuttlecock_o",
          "limit": [
            "order": 8,
            "destination": 3
          ]
        ], [
          "name": "station",
          "limit": [
            "order": 8,
            "destination": 3
          ]
        ], [
          "name": "terminal",
          "limit": [
            "order": 8,
            "destination": 8
          ]
        ], [
          "name": "jungang_stn",
          "limit": [
            "order": 8,
            "destination": 8
          ]
        ], [
          "name": "shuttlecock_i",
          "limit": [
            "order": 8,
            "destination": 8
          ]
        ]],
        "after": .variable("after")
      ]]),
      .field("subway", [Subway].self, arguments: ["input": ["keys": [[
        "stationID": "K449",
        "direction": ["up", "down"],
        "weekdays": [.variable("weekday")],
        "limit": 2
      ], [
        "stationID": "K251",
        "direction": ["up", "down"],
        "weekdays": [.variable("weekday")],
        "limit": 2
      ]]]]),
      .field("bus", alias: "transferBus", [TransferBus].self, arguments: ["input": [[
        "route": 216000075,
        "stop": 216000759,
        "limit": 2
      ], [
        "route": 216000075,
        "stop": 216000117,
        "limit": 2
      ]]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ShuttleRealtimePageQuery.Data.self
    ] }

    public var notices: [Notice] { __data["notices"] }
    public var shuttle: Shuttle { __data["shuttle"] }
    public var subway: [Subway] { __data["subway"] }
    public var transferBus: [TransferBus] { __data["transferBus"] }

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
        ShuttleRealtimePageQuery.Data.Notice.self
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
          ShuttleRealtimePageQuery.Data.Notice.Notice.self
        ] }

        public var title: String { __data["title"] }
        public var url: String { __data["url"] }
        public var expiredAt: Api.DateTime { __data["expiredAt"] }
      }
    }

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
        ShuttleRealtimePageQuery.Data.Shuttle.self
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
          ShuttleRealtimePageQuery.Data.Shuttle.Stop.self
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
            .field("order", [Order].self),
            .field("destination", [Destination].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.self
          ] }

          public var order: [Order] { __data["order"] }
          public var destination: [Destination] { __data["destination"] }

          /// Shuttle.Stop.Timetable.Order
          ///
          /// Parent Type: `ShuttleTimetableEntry`
          nonisolated public struct Order: Api.SelectionSet {
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
              ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order.self
            ] }

            public var route: Route { __data["route"] }
            public var time: Api.LocalTime { __data["time"] }
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
                ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order.Route.self
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
                ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order.Stop.self
              ] }

              public var stop: String { __data["stop"] }
              public var time: Api.LocalTime { __data["time"] }
            }
          }

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
              ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.self
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
                ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry.self
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
                  ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry.Route.self
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
                  ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry.Stop.self
                ] }

                public var stop: String { __data["stop"] }
                public var time: Api.LocalTime { __data["time"] }
              }
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
        ShuttleRealtimePageQuery.Data.Subway.self
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
          ShuttleRealtimePageQuery.Data.Subway.Arrival.self
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
            .field("isRealtime", Bool.self),
            .field("location", String?.self),
            .field("stops", Int?.self),
            .field("terminal", Terminal.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ShuttleRealtimePageQuery.Data.Subway.Arrival.Entry.self
          ] }

          public var minutes: Int { __data["minutes"] }
          public var isRealtime: Bool { __data["isRealtime"] }
          public var location: String? { __data["location"] }
          public var stops: Int? { __data["stops"] }
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
              ShuttleRealtimePageQuery.Data.Subway.Arrival.Entry.Terminal.self
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
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ShuttleRealtimePageQuery.Data.TransferBus.self
      ] }

      public var route: Route { __data["route"] }
      public var stop: Stop { __data["stop"] }
      public var arrival: [Arrival] { __data["arrival"] }

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
          ShuttleRealtimePageQuery.Data.TransferBus.Route.self
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
          ShuttleRealtimePageQuery.Data.TransferBus.Stop.self
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
          .field("isRealtime", Bool.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ShuttleRealtimePageQuery.Data.TransferBus.Arrival.self
        ] }

        public var minutes: Int? { __data["minutes"] }
        public var stops: Int? { __data["stops"] }
        public var isRealtime: Bool { __data["isRealtime"] }
      }
    }
  }
}
