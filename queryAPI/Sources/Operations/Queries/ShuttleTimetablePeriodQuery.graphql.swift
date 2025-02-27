// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ShuttleTimetablePeriodQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleTimetablePeriodQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleTimetablePeriodQuery($shuttleDate: Date!) { shuttle(periodStart: $shuttleDate, periodEnd: $shuttleDate) { __typename period { __typename type } } }"#
    ))

  public var shuttleDate: Date

  public init(shuttleDate: Date) {
    self.shuttleDate = shuttleDate
  }

  public var __variables: Variables? { ["shuttleDate": shuttleDate] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("shuttle", Shuttle.self, arguments: [
        "periodStart": .variable("shuttleDate"),
        "periodEnd": .variable("shuttleDate")
      ]),
    ] }

    /// Shuttle query
    public var shuttle: Shuttle { __data["shuttle"] }

    /// Shuttle
    ///
    /// Parent Type: `ShuttleQuery`
    public struct Shuttle: QueryAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.ShuttleQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("period", [Period].self),
      ] }

      public var period: [Period] { __data["period"] }

      /// Shuttle.Period
      ///
      /// Parent Type: `ShuttlePeriodQuery`
      public struct Period: QueryAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.ShuttlePeriodQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("type", String.self),
        ] }

        public var type: String { __data["type"] }
      }
    }
  }
}
