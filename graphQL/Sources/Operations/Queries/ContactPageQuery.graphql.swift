// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ContactPageQuery: GraphQLQuery {
  public static let operationName: String = "ContactPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ContactPageQuery { contact { __typename version data { __typename id name phone campusID } } }"#
    ))

  public init() {}

  public struct Data: GraphQL.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("contact", Contact.self),
    ] }

    /// Contact query
    public var contact: Contact { __data["contact"] }

    /// Contact
    ///
    /// Parent Type: `ContactQuery`
    public struct Contact: GraphQL.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.ContactQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("version", String.self),
        .field("data", [Datum].self),
      ] }

      /// Version of event
      public var version: String { __data["version"] }
      /// List of events
      public var data: [Datum] { __data["data"] }

      /// Contact.Datum
      ///
      /// Parent Type: `ContactItemQuery`
      public struct Datum: GraphQL.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.ContactItemQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("name", String.self),
          .field("phone", String.self),
          .field("campusID", Int.self),
        ] }

        /// Contact ID
        public var id: Int { __data["id"] }
        /// Contact name
        public var name: String { __data["name"] }
        /// Contact phone number
        public var phone: String { __data["phone"] }
        /// Campus ID
        public var campusID: Int { __data["campusID"] }
      }
    }
  }
}
