// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class CalendarPageVersionQuery: GraphQLQuery {
  public static let operationName: String = "CalendarPageVersionQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query CalendarPageVersionQuery { calendar { __typename version } }"#
    ))

  public init() {}

  public struct Data: GraphQL.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("calendar", Calendar.self),
    ] }

    /// Calendar query
    public var calendar: Calendar { __data["calendar"] }

    /// Calendar
    ///
    /// Parent Type: `CalendarQuery`
    public struct Calendar: GraphQL.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.CalendarQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("version", String.self),
      ] }

      /// Version of event
      public var version: String { __data["version"] }
    }
  }
}
