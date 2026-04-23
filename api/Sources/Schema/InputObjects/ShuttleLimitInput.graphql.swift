// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ShuttleLimitInput: InputObject {
  @_spi(Unsafe) public private(set) var __data: InputDict

  @_spi(Unsafe) public init(_ data: InputDict) {
    __data = data
  }

  public init(
    order: GraphQLNullable<Int32> = nil,
    destination: GraphQLNullable<Int32> = nil
  ) {
    __data = InputDict([
      "order": order,
      "destination": destination
    ])
  }

  public var order: GraphQLNullable<Int32> {
    get { __data["order"] }
    set { __data["order"] = newValue }
  }

  public var destination: GraphQLNullable<Int32> {
    get { __data["destination"] }
    set { __data["destination"] = newValue }
  }
}
