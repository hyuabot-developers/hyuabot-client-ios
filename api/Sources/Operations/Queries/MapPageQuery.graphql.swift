// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct MapPageQuery: GraphQLQuery {
  public static let operationName: String = "MapPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query MapPageQuery($north: Float!, $south: Float!, $west: Float!, $east: Float!) { building( buildingInput: { north: $north, south: $south, west: $west, east: $east } ) { __typename name latitude longitude url } }"#
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

  @_spi(Unsafe) public var __variables: Variables? { [
    "north": north,
    "south": south,
    "west": west,
    "east": east
  ] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("building", [Building].self, arguments: ["buildingInput": [
        "north": .variable("north"),
        "south": .variable("south"),
        "west": .variable("west"),
        "east": .variable("east")
      ]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      MapPageQuery.Data.self
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
        .field("url", String?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MapPageQuery.Data.Building.self
      ] }

      public var name: String { __data["name"] }
      public var latitude: Double { __data["latitude"] }
      public var longitude: Double { __data["longitude"] }
      public var url: String? { __data["url"] }
    }
  }
}
