// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class BusRealtimePageQuery: GraphQLQuery {
  public static let operationName: String = "BusRealtimePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusRealtimePageQuery($busStart: Time!) { bus( id_: [216000138, 216000759, 216000117, 216000379, 216000070, 216000719, 213000487] start: $busStart ) { __typename id name latitude longitude routes { __typename info { __typename id name } realtime { __typename sequence stop time seat lowFloor updatedAt } timetable { __typename weekdays time } } } }"#
    ))

  public var busStart: Time

  public init(busStart: Time) {
    self.busStart = busStart
  }

  public var __variables: Variables? { ["busStart": busStart] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("bus", [Bus].self, arguments: [
        "id_": [216000138, 216000759, 216000117, 216000379, 216000070, 216000719, 213000487],
        "start": .variable("busStart")
      ]),
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
        .field("id", Int.self),
        .field("name", String.self),
        .field("latitude", Double.self),
        .field("longitude", Double.self),
        .field("routes", [Route].self),
      ] }

      /// Stop ID
      public var id: Int { __data["id"] }
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
          .field("realtime", [Realtime].self),
          .field("timetable", [Timetable].self),
        ] }

        /// Info
        public var info: Info { __data["info"] }
        /// Realtime
        public var realtime: [Realtime] { __data["realtime"] }
        /// Timetable
        public var timetable: [Timetable] { __data["timetable"] }

        /// Bus.Route.Info
        ///
        /// Parent Type: `BusRouteQuery`
        public struct Info: QueryAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusRouteQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Int.self),
            .field("name", String.self),
          ] }

          /// Route ID
          public var id: Int { __data["id"] }
          /// Route name
          public var name: String { __data["name"] }
        }

        /// Bus.Route.Realtime
        ///
        /// Parent Type: `BusRealtimeQuery`
        public struct Realtime: QueryAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusRealtimeQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("sequence", Int.self),
            .field("stop", Int.self),
            .field("time", Double.self),
            .field("seat", Int.self),
            .field("lowFloor", Bool.self),
            .field("updatedAt", QueryAPI.DateTime.self),
          ] }

          /// Sequence
          public var sequence: Int { __data["sequence"] }
          /// Stop
          public var stop: Int { __data["stop"] }
          /// Time
          public var time: Double { __data["time"] }
          /// Seat
          public var seat: Int { __data["seat"] }
          /// Low floor
          public var lowFloor: Bool { __data["lowFloor"] }
          /// Updated at
          public var updatedAt: QueryAPI.DateTime { __data["updatedAt"] }
        }

        /// Bus.Route.Timetable
        ///
        /// Parent Type: `BusTimetableQuery`
        public struct Timetable: QueryAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusTimetableQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("weekdays", String.self),
            .field("time", String.self),
          ] }

          /// Is weekdays
          public var weekdays: String { __data["weekdays"] }
          /// Departure time
          public var time: String { __data["time"] }
        }
      }
    }
  }
}
