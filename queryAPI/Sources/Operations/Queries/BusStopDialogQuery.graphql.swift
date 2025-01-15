// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class BusStopDialogQuery: GraphQLQuery {
  public static let operationName: String = "BusStopDialogQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusStopDialogQuery($busStopID: Int!) { bus(id_: [$busStopID]) { __typename name latitude longitude routes { __typename info { __typename name runningTime { __typename up { __typename first last } down { __typename first last } } start { __typename name } end { __typename name } } } } }"#
    ))

  public var busStopID: Int

  public init(busStopID: Int) {
    self.busStopID = busStopID
  }

  public var __variables: Variables? { ["busStopID": busStopID] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("bus", [Bus].self, arguments: ["id_": [.variable("busStopID")]]),
    ] }

    /// Bus stop query
    public var bus: [Bus] { __data["bus"] }

    /// Bus
    ///
    /// Parent Type: `StopQuery`
    public struct Bus: QueryAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.StopQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("name", String.self),
        .field("latitude", Double.self),
        .field("longitude", Double.self),
        .field("routes", [Route].self),
      ] }

      /// Stop name
      public var name: String { __data["name"] }
      /// Latitude
      public var latitude: Double { __data["latitude"] }
      /// Longitude
      public var longitude: Double { __data["longitude"] }
      /// Routes
      public var routes: [Route] { __data["routes"] }

      /// Bus.Route
      ///
      /// Parent Type: `BusStopRouteQuery`
      public struct Route: QueryAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusStopRouteQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("info", Info.self),
        ] }

        /// Info
        public var info: Info { __data["info"] }

        /// Bus.Route.Info
        ///
        /// Parent Type: `BusRouteQuery`
        public struct Info: QueryAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusRouteQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("name", String.self),
            .field("runningTime", RunningTime.self),
            .field("start", Start.self),
            .field("end", End.self),
          ] }

          /// Route name
          public var name: String { __data["name"] }
          /// Running time
          public var runningTime: RunningTime { __data["runningTime"] }
          /// Start stop
          public var start: Start { __data["start"] }
          /// End stop
          public var end: End { __data["end"] }

          /// Bus.Route.Info.RunningTime
          ///
          /// Parent Type: `BusRunningListQuery`
          public struct RunningTime: QueryAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusRunningListQuery }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("up", Up.self),
              .field("down", Down.self),
            ] }

            /// Up
            public var up: Up { __data["up"] }
            /// Down
            public var down: Down { __data["down"] }

            /// Bus.Route.Info.RunningTime.Up
            ///
            /// Parent Type: `BusRunningTimeQuery`
            public struct Up: QueryAPI.SelectionSet {
              public let __data: DataDict
              public init(_dataDict: DataDict) { __data = _dataDict }

              public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusRunningTimeQuery }
              public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("first", String.self),
                .field("last", String.self),
              ] }

              /// First time
              public var first: String { __data["first"] }
              /// Last time
              public var last: String { __data["last"] }
            }

            /// Bus.Route.Info.RunningTime.Down
            ///
            /// Parent Type: `BusRunningTimeQuery`
            public struct Down: QueryAPI.SelectionSet {
              public let __data: DataDict
              public init(_dataDict: DataDict) { __data = _dataDict }

              public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusRunningTimeQuery }
              public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("first", String.self),
                .field("last", String.self),
              ] }

              /// First time
              public var first: String { __data["first"] }
              /// Last time
              public var last: String { __data["last"] }
            }
          }

          /// Bus.Route.Info.Start
          ///
          /// Parent Type: `BusStopItem`
          public struct Start: QueryAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusStopItem }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("name", String.self),
            ] }

            /// Stop name
            public var name: String { __data["name"] }
          }

          /// Bus.Route.Info.End
          ///
          /// Parent Type: `BusStopItem`
          public struct End: QueryAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusStopItem }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("name", String.self),
            ] }

            /// Stop name
            public var name: String { __data["name"] }
          }
        }
      }
    }
  }
}
