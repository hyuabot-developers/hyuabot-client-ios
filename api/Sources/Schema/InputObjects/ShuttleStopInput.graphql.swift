// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ShuttleStopInput: InputObject {
  @_spi(Unsafe) public private(set) var __data: InputDict

  @_spi(Unsafe) public init(_ data: InputDict) {
    __data = data
  }

  public init(
    name: String,
    limit: ShuttleLimitInput,
    destinations: GraphQLNullable<[String]> = nil,
    routes: GraphQLNullable<[String]> = nil,
    tags: GraphQLNullable<[String]> = nil
  ) {
    __data = InputDict([
      "name": name,
      "limit": limit,
      "destinations": destinations,
      "routes": routes,
      "tags": tags
    ])
  }

  public var name: String {
    get { __data["name"] }
    set { __data["name"] = newValue }
  }

  public var limit: ShuttleLimitInput {
    get { __data["limit"] }
    set { __data["limit"] = newValue }
  }

  public var destinations: GraphQLNullable<[String]> {
    get { __data["destinations"] }
    set { __data["destinations"] = newValue }
  }

  public var routes: GraphQLNullable<[String]> {
    get { __data["routes"] }
    set { __data["routes"] = newValue }
  }

  public var tags: GraphQLNullable<[String]> {
    get { __data["tags"] }
    set { __data["tags"] = newValue }
  }
}
