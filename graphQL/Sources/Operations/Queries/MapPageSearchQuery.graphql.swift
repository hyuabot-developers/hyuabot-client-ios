// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class MapPageSearchQuery: GraphQLQuery {
  public static let operationName: String = "MapPageSearchQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query MapPageSearchQuery($keyword: String!) { room(name: $keyword) { __typename name latitude longitude buildingName number } }"#
    ))

  public var keyword: String

  public init(keyword: String) {
    self.keyword = keyword
  }

  public var __variables: Variables? { ["keyword": keyword] }

  public struct Data: GraphQL.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("room", [Room].self, arguments: ["name": .variable("keyword")]),
    ] }

    /// Room query
    public var room: [Room] { __data["room"] }

    /// Room
    ///
    /// Parent Type: `RoomQuery`
    public struct Room: GraphQL.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.RoomQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("name", String.self),
        .field("latitude", Double.self),
        .field("longitude", Double.self),
        .field("buildingName", String.self),
        .field("number", String.self),
      ] }

      /// Room name
      public var name: String { __data["name"] }
      /// Building latitude
      public var latitude: Double { __data["latitude"] }
      /// Building longitude
      public var longitude: Double { __data["longitude"] }
      /// Building name
      public var buildingName: String { __data["buildingName"] }
      /// Room number
      public var number: String { __data["number"] }
    }
  }
}
