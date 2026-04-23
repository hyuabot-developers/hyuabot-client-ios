// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ContactPageQuery: GraphQLQuery {
  public static let operationName: String = "ContactPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ContactPageQuery { phonebook { __typename version categories { __typename seq name entries { __typename seq name phone campus } } } }"#
    ))

  public init() {}

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("phonebook", Phonebook.self),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ContactPageQuery.Data.self
    ] }

    public var phonebook: Phonebook { __data["phonebook"] }

    /// Phonebook
    ///
    /// Parent Type: `Phonebook`
    nonisolated public struct Phonebook: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Phonebook }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("version", String.self),
        .field("categories", [Category].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ContactPageQuery.Data.Phonebook.self
      ] }

      public var version: String { __data["version"] }
      public var categories: [Category] { __data["categories"] }

      /// Phonebook.Category
      ///
      /// Parent Type: `PhonebookCategory`
      nonisolated public struct Category: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.PhonebookCategory }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("seq", Int.self),
          .field("name", String.self),
          .field("entries", [Entry].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ContactPageQuery.Data.Phonebook.Category.self
        ] }

        public var seq: Int { __data["seq"] }
        public var name: String { __data["name"] }
        public var entries: [Entry] { __data["entries"] }

        /// Phonebook.Category.Entry
        ///
        /// Parent Type: `PhonebookEntry`
        nonisolated public struct Entry: Api.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.PhonebookEntry }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("seq", Int.self),
            .field("name", String.self),
            .field("phone", String.self),
            .field("campus", Int.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ContactPageQuery.Data.Phonebook.Category.Entry.self
          ] }

          public var seq: Int { __data["seq"] }
          public var name: String { __data["name"] }
          public var phone: String { __data["phone"] }
          public var campus: Int { __data["campus"] }
        }
      }
    }
  }
}
