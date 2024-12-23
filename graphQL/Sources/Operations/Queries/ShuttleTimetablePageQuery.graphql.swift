// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ShuttleTimetablePageQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleTimetablePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleTimetablePageQuery($period: [String!]!, $stopID: String!, $tag: [String!]!) { shuttle( stopName: [$stopID] period: $period routeTag: $tag weekdays: [true, false] ) { __typename timetable { __typename tag route period weekdays time stop via { __typename stop time } } } }"#
    ))

  public var period: [String]
  public var stopID: String
  public var tag: [String]

  public init(
    period: [String],
    stopID: String,
    tag: [String]
  ) {
    self.period = period
    self.stopID = stopID
    self.tag = tag
  }

  public var __variables: Variables? { [
    "period": period,
    "stopID": stopID,
    "tag": tag
  ] }

  public struct Data: GraphQL.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("shuttle", Shuttle.self, arguments: [
        "stopName": [.variable("stopID")],
        "period": .variable("period"),
        "routeTag": .variable("tag"),
        "weekdays": [true, false]
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
      ] }

      public var timetable: [Timetable] { __data["timetable"] }

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
          .field("period", String.self),
          .field("weekdays", Bool.self),
          .field("time", String.self),
          .field("stop", String.self),
          .field("via", [Vium].self),
        ] }

        public var tag: String { __data["tag"] }
        public var route: String { __data["route"] }
        public var period: String { __data["period"] }
        public var weekdays: Bool { __data["weekdays"] }
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
    }
  }
}