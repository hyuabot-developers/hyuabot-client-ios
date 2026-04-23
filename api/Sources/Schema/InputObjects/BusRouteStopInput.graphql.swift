// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

///  노선 버스 정보를 반환하는 쿼리입니다.
nonisolated public struct BusRouteStopInput: InputObject {
  @_spi(Unsafe) public private(set) var __data: InputDict

  @_spi(Unsafe) public init(_ data: InputDict) {
    __data = data
  }

  public init(
    route: Int32,
    stop: Int32,
    after: GraphQLNullable<LocalTime> = nil,
    limit: GraphQLNullable<Int32> = nil,
    dates: GraphQLNullable<[Date]> = nil,
    weekdays: GraphQLNullable<[String]> = nil
  ) {
    __data = InputDict([
      "route": route,
      "stop": stop,
      "after": after,
      "limit": limit,
      "dates": dates,
      "weekdays": weekdays
    ])
  }

  public var route: Int32 {
    get { __data["route"] }
    set { __data["route"] = newValue }
  }

  public var stop: Int32 {
    get { __data["stop"] }
    set { __data["stop"] = newValue }
  }

  public var after: GraphQLNullable<LocalTime> {
    get { __data["after"] }
    set { __data["after"] = newValue }
  }

  public var limit: GraphQLNullable<Int32> {
    get { __data["limit"] }
    set { __data["limit"] = newValue }
  }

  public var dates: GraphQLNullable<[Date]> {
    get { __data["dates"] }
    set { __data["dates"] = newValue }
  }

  public var weekdays: GraphQLNullable<[String]> {
    get { __data["weekdays"] }
    set { __data["weekdays"] = newValue }
  }
}
