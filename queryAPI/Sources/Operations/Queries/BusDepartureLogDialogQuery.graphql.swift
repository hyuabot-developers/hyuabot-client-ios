// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class BusDepartureLogDialogQuery: GraphQLQuery {
  public static let operationName: String = "BusDepartureLogDialogQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusDepartureLogDialogQuery($stopID: Int!, $routes: [Int!]!, $dates: [Date!]!) { bus(id_: [$stopID], routes: $routes, logDate: $dates) { __typename routes { __typename log { __typename departureDate departureTime } info { __typename name } } } }"#
    ))

  public var stopID: Int
  public var routes: [Int]
  public var dates: [Date]

  public init(
    stopID: Int,
    routes: [Int],
    dates: [Date]
  ) {
    self.stopID = stopID
    self.routes = routes
    self.dates = dates
  }

  public var __variables: Variables? { [
    "stopID": stopID,
    "routes": routes,
    "dates": dates
  ] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("bus", [Bus].self, arguments: [
        "id_": [.variable("stopID")],
        "routes": .variable("routes"),
        "logDate": .variable("dates")
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
          .field("log", [Log].self),
          .field("info", Info.self),
        ] }

        /// Log
        public var log: [Log] { __data["log"] }
        /// Info
        public var info: Info { __data["info"] }

        /// Bus.Route.Log
        ///
        /// Parent Type: `BusDepartureLogQuery`
        public struct Log: QueryAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BusDepartureLogQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("departureDate", QueryAPI.Date.self),
            .field("departureTime", QueryAPI.Time.self),
          ] }

          /// Departure date
          public var departureDate: QueryAPI.Date { __data["departureDate"] }
          /// Departure time
          public var departureTime: QueryAPI.Time { __data["departureTime"] }
        }

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
      }
    }
  }
}
