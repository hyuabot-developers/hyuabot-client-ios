// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class BusTimetablePageQuery: GraphQLQuery {
  public static let operationName: String = "BusTimetablePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusTimetablePageQuery($routes: [Int!]!, $stopID: Int!) { bus( id_: [$stopID] routes: $routes weekdays: ["weekdays", "saturday", "sunday"] ) { __typename routes { __typename info { __typename name } timetable { __typename weekdays time } } } }"#
    ))

  public var routes: [Int]
  public var stopID: Int

  public init(
    routes: [Int],
    stopID: Int
  ) {
    self.routes = routes
    self.stopID = stopID
  }

  public var __variables: Variables? { [
    "routes": routes,
    "stopID": stopID
  ] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("bus", [Bus].self, arguments: [
        "id_": [.variable("stopID")],
        "routes": .variable("routes"),
        "weekdays": ["weekdays", "saturday", "sunday"]
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
        .field("routes", [Route].self),
      ] }

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
          .field("timetable", [Timetable].self),
        ] }

        /// Info
        public var info: Info { __data["info"] }
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
            .field("name", String.self),
          ] }

          /// Route name
          public var name: String { __data["name"] }
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
