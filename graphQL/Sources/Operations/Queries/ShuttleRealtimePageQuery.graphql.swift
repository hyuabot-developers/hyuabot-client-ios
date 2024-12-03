// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ShuttleRealtimePageQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleRealtimePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleRealtimePageQuery($shuttleStart: Time!, $shuttleDateTime: DateTime!) { shuttle(start: $shuttleStart, timestamp: $shuttleDateTime) { __typename timetable { __typename tag route time stop via { __typename stop time } } stop { __typename name latitude longitude } } }"#
    ))

  public var shuttleStart: Time
  public var shuttleDateTime: DateTime

  public init(
    shuttleStart: Time,
    shuttleDateTime: DateTime
  ) {
    self.shuttleStart = shuttleStart
    self.shuttleDateTime = shuttleDateTime
  }

  public var __variables: Variables? { [
    "shuttleStart": shuttleStart,
    "shuttleDateTime": shuttleDateTime
  ] }

  public struct Data: GraphQL.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("shuttle", Shuttle.self, arguments: [
        "start": .variable("shuttleStart"),
        "timestamp": .variable("shuttleDateTime")
      ]),
    ] }

    /// Shuttle query
    public var shuttle: Shuttle { __data["shuttle"] }

    /// Shuttle
    ///
    /// Parent Type: `ShuttleQuery`
    public struct Shuttle: GraphQL.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.ShuttleQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("timetable", [Timetable].self),
        .field("stop", [Stop].self),
      ] }

      public var timetable: [Timetable] { __data["timetable"] }
      public var stop: [Stop] { __data["stop"] }

      /// Shuttle.Timetable
      ///
      /// Parent Type: `ShuttleTimetableQuery`
      public struct Timetable: GraphQL.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.ShuttleTimetableQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("tag", String.self),
          .field("route", String.self),
          .field("time", String.self),
          .field("stop", String.self),
          .field("via", [Vium].self),
        ] }

        public var tag: String { __data["tag"] }
        public var route: String { __data["route"] }
        public var time: String { __data["time"] }
        public var stop: String { __data["stop"] }
        public var via: [Vium] { __data["via"] }

        /// Shuttle.Timetable.Vium
        ///
        /// Parent Type: `ShuttleViaQuery`
        public struct Vium: GraphQL.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.ShuttleViaQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("stop", String.self),
            .field("time", String.self),
          ] }

          public var stop: String { __data["stop"] }
          public var time: String { __data["time"] }
        }
      }

      /// Shuttle.Stop
      ///
      /// Parent Type: `ShuttleStopQuery`
      public struct Stop: GraphQL.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.ShuttleStopQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("name", String.self),
          .field("latitude", Double.self),
          .field("longitude", Double.self),
        ] }

        public var name: String { __data["name"] }
        public var latitude: Double { __data["latitude"] }
        public var longitude: Double { __data["longitude"] }
      }
    }
  }
}
