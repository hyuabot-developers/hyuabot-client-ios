// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class BusDepartureLogDialogQuery: GraphQLQuery {
  public static let operationName: String = "BusDepartureLogDialogQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusDepartureLogDialogQuery($stopID: Int!, $routeID: Int!, $dates: [Date!]!) { bus(id_: [$stopID], routeId: $routeID, logDate: $dates) { __typename routes { __typename log { __typename departureDate departureTime } info { __typename name } } } }"#
    ))

  public var stopID: Int
  public var routeID: Int
  public var dates: [Date]

  public init(
    stopID: Int,
    routeID: Int,
    dates: [Date]
  ) {
    self.stopID = stopID
    self.routeID = routeID
    self.dates = dates
  }

  public var __variables: Variables? { [
    "stopID": stopID,
    "routeID": routeID,
    "dates": dates
  ] }

  public struct Data: GraphQL.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("bus", [Bus].self, arguments: [
        "id_": [.variable("stopID")],
        "routeId": .variable("routeID"),
        "logDate": .variable("dates")
      ]),
    ] }

    /// Bus stop query
    public var bus: [Bus] { __data["bus"] }

    /// Bus
    ///
    /// Parent Type: `StopQuery`
    public struct Bus: GraphQL.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.StopQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("routes", [Route].self),
      ] }

      /// Routes
      public var routes: [Route] { __data["routes"] }

      /// Bus.Route
      ///
      /// Parent Type: `BusStopRouteQuery`
      public struct Route: GraphQL.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.BusStopRouteQuery }
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
        public struct Log: GraphQL.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.BusDepartureLogQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("departureDate", GraphQL.Date.self),
            .field("departureTime", GraphQL.Time.self),
          ] }

          /// Departure date
          public var departureDate: GraphQL.Date { __data["departureDate"] }
          /// Departure time
          public var departureTime: GraphQL.Time { __data["departureTime"] }
        }

        /// Bus.Route.Info
        ///
        /// Parent Type: `BusRouteQuery`
        public struct Info: GraphQL.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.BusRouteQuery }
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
