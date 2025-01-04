// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ShuttlePeriodQuery: GraphQLQuery {
  public static let operationName: String = "ShuttlePeriodQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttlePeriodQuery { shuttle(periodCurrent: true) { __typename period { __typename type } } }"#
    ))

  public init() {}

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("shuttle", Shuttle.self, arguments: ["periodCurrent": true]),
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
