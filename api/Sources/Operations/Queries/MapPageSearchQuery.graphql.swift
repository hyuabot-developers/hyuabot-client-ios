// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct MapPageSearchQuery: GraphQLQuery {
  public static let operationName: String = "MapPageSearchQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query MapPageSearchQuery($keyword: String!) { building(roomInput: { name: $keyword }) { __typename name latitude longitude rooms { __typename name number } } }"#
    ))

  public var keyword: String

  public init(keyword: String) {
    self.keyword = keyword
  }

  @_spi(Unsafe) public var __variables: Variables? { ["keyword": keyword] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("building", [Building].self, arguments: ["roomInput": ["name": .variable("keyword")]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      MapPageSearchQuery.Data.self
    ] }

    public var building: [Building] { __data["building"] }

    /// Building
    ///
    /// Parent Type: `Building`
    nonisolated public struct Building: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Building }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("name", String.self),
        .field("latitude", Double.self),
        .field("longitude", Double.self),
        .field("rooms", [Room].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MapPageSearchQuery.Data.Building.self
      ] }

      public var name: String { __data["name"] }
      public var latitude: Double { __data["latitude"] }
      public var longitude: Double { __data["longitude"] }
      public var rooms: [Room] { __data["rooms"] }

      /// Building.Room
      ///
      /// Parent Type: `Room`
      nonisolated public struct Room: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Room }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("name", String.self),
          .field("number", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MapPageSearchQuery.Data.Building.Room.self
        ] }

        public var name: String { __data["name"] }
        public var number: String { __data["number"] }
      }
    }
  }
}
