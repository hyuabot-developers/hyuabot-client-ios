// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class BusRouteInfoDialogQuery: GraphQLQuery {
  public static let operationName: String = "BusRouteInfoDialogQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusRouteInfoDialogQuery($routeID: Int!, $stopID: Int!) { bus( id_: [$stopID] routeId: $routeID weekdays: ["weekdays", "saturday", "sunday"] ) { __typename routes { __typename info { __typename name start { __typename name } } minuteFromStart } } }"#
    ))

  public var routeID: Int
  public var stopID: Int

  public init(
    routeID: Int,
    stopID: Int
  ) {
    self.routeID = routeID
    self.stopID = stopID
  }

  public var __variables: Variables? { [
    "routeID": routeID,
    "stopID": stopID
  ] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("bus", [Bus].self, arguments: [
        "id_": [.variable("stopID")],
        "routeId": .variable("routeID"),
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
          .field("minuteFromStart", Int.self),
        ] }

        /// Info
        public var info: Info { __data["info"] }
        /// Minute from start stop
        public var minuteFromStart: Int { __data["minuteFromStart"] }

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
            .field("start", Start.self),
          ] }

          /// Route name
          public var name: String { __data["name"] }
          /// Start stop
          public var start: Start { __data["start"] }

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
        }
      }
    }
  }
}
