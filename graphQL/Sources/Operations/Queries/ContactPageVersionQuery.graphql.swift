// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ContactPageVersionQuery: GraphQLQuery {
  public static let operationName: String = "ContactPageVersionQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ContactPageVersionQuery { contact { __typename version } }"#
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
      ] }

      /// Version of event
      public var version: String { __data["version"] }
    }
  }
}
