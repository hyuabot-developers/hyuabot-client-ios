// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ReadingRoomPageQuery: GraphQLQuery {
  public static let operationName: String = "ReadingRoomPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ReadingRoomPageQuery { readingRoom { __typename seq name campus seats { __typename available active occupied } updatedAt } }"#
    ))

  public init() {}

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("readingRoom", [ReadingRoom].self),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ReadingRoomPageQuery.Data.self
    ] }

    public var readingRoom: [ReadingRoom] { __data["readingRoom"] }

    /// ReadingRoom
    ///
    /// Parent Type: `ReadingRoom`
    nonisolated public struct ReadingRoom: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ReadingRoom }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("seq", Int.self),
        .field("name", String.self),
        .field("campus", Int.self),
        .field("seats", Seats.self),
        .field("updatedAt", Api.DateTime.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReadingRoomPageQuery.Data.ReadingRoom.self
      ] }

      public var seq: Int { __data["seq"] }
      public var name: String { __data["name"] }
      public var campus: Int { __data["campus"] }
      public var seats: Seats { __data["seats"] }
      public var updatedAt: Api.DateTime { __data["updatedAt"] }

      /// ReadingRoom.Seats
      ///
      /// Parent Type: `ReadingRoomSeat`
      nonisolated public struct Seats: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ReadingRoomSeat }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("available", Int.self),
          .field("active", Int.self),
          .field("occupied", Int.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReadingRoomPageQuery.Data.ReadingRoom.Seats.self
        ] }

        public var available: Int { __data["available"] }
        public var active: Int { __data["active"] }
        public var occupied: Int { __data["occupied"] }
      }
    }
  }
}
