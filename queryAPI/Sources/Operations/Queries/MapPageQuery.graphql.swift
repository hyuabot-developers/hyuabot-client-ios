// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class MapPageQuery: GraphQLQuery {
  public static let operationName: String = "MapPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query MapPageQuery($north: Float!, $south: Float!, $west: Float!, $east: Float!) { building(north: $north, south: $south, west: $west, east: $east) { __typename name latitude longitude url } }"#
    ))

  public var north: Double
  public var south: Double
  public var west: Double
  public var east: Double

  public init(
    north: Double,
    south: Double,
    west: Double,
    east: Double
  ) {
    self.north = north
    self.south = south
    self.west = west
    self.east = east
  }

  public var __variables: Variables? { [
    "north": north,
    "south": south,
    "west": west,
    "east": east
  ] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("building", [Building].self, arguments: [
        "north": .variable("north"),
        "south": .variable("south"),
        "west": .variable("west"),
        "east": .variable("east")
      ]),
    ] }

    /// Building query
    public var building: [Building] { __data["building"] }

    /// Building
    ///
    /// Parent Type: `BuildingQuery`
    public struct Building: QueryAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.BuildingQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("name", String.self),
        .field("latitude", Double.self),
        .field("longitude", Double.self),
        .field("url", String?.self),
      ] }

      /// Building name
      public var name: String { __data["name"] }
      /// Building latitude
      public var latitude: Double { __data["latitude"] }
      /// Building longitude
      public var longitude: Double { __data["longitude"] }
      /// Blog URL
      public var url: String? { __data["url"] }
    }
  }
}
