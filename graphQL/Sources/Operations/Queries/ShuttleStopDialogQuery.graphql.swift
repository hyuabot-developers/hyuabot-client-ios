// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ShuttleStopDialogQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleStopDialogQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleStopDialogQuery($shuttleStopID: String!, $shuttleDateTime: DateTime!) { shuttle( stopName: [$shuttleStopID] weekdays: [true, false] timestamp: $shuttleDateTime ) { __typename stop { __typename latitude longitude } timetable { __typename time tag weekdays } } }"#
    ))

  public var shuttleStopID: String
  public var shuttleDateTime: DateTime

  public init(
    shuttleStopID: String,
    shuttleDateTime: DateTime
  ) {
    self.shuttleStopID = shuttleStopID
    self.shuttleDateTime = shuttleDateTime
  }

  public var __variables: Variables? { [
    "shuttleStopID": shuttleStopID,
    "shuttleDateTime": shuttleDateTime
  ] }

  public struct Data: GraphQL.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("shuttle", Shuttle.self, arguments: [
        "stopName": [.variable("shuttleStopID")],
        "weekdays": [true, false],
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
        .field("stop", [Stop].self),
        .field("timetable", [Timetable].self),
      ] }

      public var stop: [Stop] { __data["stop"] }
      public var timetable: [Timetable] { __data["timetable"] }

      /// Shuttle.Stop
      ///
      /// Parent Type: `ShuttleStopQuery`
      public struct Stop: GraphQL.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.ShuttleStopQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("latitude", Double.self),
          .field("longitude", Double.self),
        ] }

        public var latitude: Double { __data["latitude"] }
        public var longitude: Double { __data["longitude"] }
      }

      /// Shuttle.Timetable
      ///
      /// Parent Type: `ShuttleTimetableQuery`
      public struct Timetable: GraphQL.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.ShuttleTimetableQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("time", String.self),
          .field("tag", String.self),
          .field("weekdays", Bool.self),
        ] }

        public var time: String { __data["time"] }
        public var tag: String { __data["tag"] }
        public var weekdays: Bool { __data["weekdays"] }
      }
    }
  }
}
