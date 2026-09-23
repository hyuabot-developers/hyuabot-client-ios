// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

nonisolated public struct SubwayStationInput: InputObject {
  @_spi(Unsafe) public private(set) var __data: InputDict

  @_spi(Unsafe) public init(_ data: InputDict) {
    __data = data
  }

  public init(
    stationID: String,
    direction: [String],
    weekdays: [String],
    limit: GraphQLNullable<Int32> = nil
  ) {
    __data = InputDict([
      "stationID": stationID,
      "direction": direction,
      "weekdays": weekdays,
      "limit": limit
    ])
  }

  public var stationID: String {
    get { __data["stationID"] }
    set { __data["stationID"] = newValue }
  }

  public var direction: [String] {
    get { __data["direction"] }
    set { __data["direction"] = newValue }
  }

  public var weekdays: [String] {
    get { __data["weekdays"] }
    set { __data["weekdays"] = newValue }
  }

  public var limit: GraphQLNullable<Int32> {
    get { __data["limit"] }
    set { __data["limit"] = newValue }
  }
}
