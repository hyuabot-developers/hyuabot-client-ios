// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ReadingRoomPageQuery: GraphQLQuery {
  public static let operationName: String = "ReadingRoomPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ReadingRoomPageQuery($campus: Int!) { readingRoom(campusId: $campus) { __typename id name active occupied available updatedAt } }"#
    ))

  public var campus: Int

  public init(campus: Int) {
    self.campus = campus
  }

  public var __variables: Variables? { ["campus": campus] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("readingRoom", [ReadingRoom].self, arguments: ["campusId": .variable("campus")]),
    ] }

    /// Reading room query
    public var readingRoom: [ReadingRoom] { __data["readingRoom"] }

    /// ReadingRoom
    ///
    /// Parent Type: `ReadingRoomQuery`
    public struct ReadingRoom: QueryAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.ReadingRoomQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("name", String.self),
        .field("active", Int.self),
        .field("occupied", Int.self),
        .field("available", Int.self),
        .field("updatedAt", String.self),
      ] }

      /// Reading room ID
      public var id: Int { __data["id"] }
      /// Reading room name
      public var name: String { __data["name"] }
      /// Active seats in reading room
      public var active: Int { __data["active"] }
      /// Occupied seats in reading room
      public var occupied: Int { __data["occupied"] }
      /// Available seats in reading room
      public var available: Int { __data["available"] }
      /// Last updated time
      public var updatedAt: String { __data["updatedAt"] }
    }
  }
}
