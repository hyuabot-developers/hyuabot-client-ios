// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class BusTimetablePageQuery: GraphQLQuery {
  public static let operationName: String = "BusTimetablePageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query BusTimetablePageQuery($routeID: Int!, $stopID: Int!) { bus( id_: [$stopID] routeId: $routeID weekdays: ["weekdays", "saturday", "sunday"] ) { __typename routes { __typename timetable { __typename weekdays time } } } }"#
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
          .field("timetable", [Timetable].self),
        ] }

        /// Timetable
        public var timetable: [Timetable] { __data["timetable"] }

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
