// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class CalendarPageQuery: GraphQLQuery {
  public static let operationName: String = "CalendarPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query CalendarPageQuery { calendar { __typename version data { __typename id title description start end category { __typename id name } } } }"#
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
        .field("data", [Datum].self),
      ] }

      /// Version of event
      public var version: String { __data["version"] }
      /// List of events
      public var data: [Datum] { __data["data"] }

      /// Calendar.Datum
      ///
      /// Parent Type: `EventQuery`
      public struct Datum: GraphQL.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.EventQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("title", String.self),
          .field("description", String.self),
          .field("start", GraphQL.Date.self),
          .field("end", GraphQL.Date.self),
          .field("category", Category.self),
        ] }

        /// Calendar ID
        public var id: Int { __data["id"] }
        /// Calendar title
        public var title: String { __data["title"] }
        /// Calendar description
        public var description: String { __data["description"] }
        /// Calendar start date
        public var start: GraphQL.Date { __data["start"] }
        /// Calendar end date
        public var end: GraphQL.Date { __data["end"] }
        /// Category of event
        public var category: Category { __data["category"] }

        /// Calendar.Datum.Category
        ///
        /// Parent Type: `CalendarCategoryQuery`
        public struct Category: GraphQL.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.CalendarCategoryQuery }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Int.self),
            .field("name", String.self),
          ] }

          /// Category ID
          public var id: Int { __data["id"] }
          /// Category name
          public var name: String { __data["name"] }
        }
      }
    }
  }
}
