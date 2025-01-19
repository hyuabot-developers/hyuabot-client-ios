// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class CafeteriaInfoQuery: GraphQLQuery {
  public static let operationName: String = "CafeteriaInfoQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query CafeteriaInfoQuery($id: Int!) { menu(id_: $id) { __typename name latitude longitude runningTime { __typename breakfast lunch dinner } } }"#
    ))

  public var id: Int

  public init(id: Int) {
    self.id = id
  }

  public var __variables: Variables? { ["id": id] }

  public struct Data: QueryAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("menu", [Menu].self, arguments: ["id_": .variable("id")]),
    ] }

    /// Cafeteria query
    public var menu: [Menu] { __data["menu"] }

    /// Menu
    ///
    /// Parent Type: `CafeteriaQuery`
    public struct Menu: QueryAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.CafeteriaQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("name", String.self),
        .field("latitude", Double.self),
        .field("longitude", Double.self),
        .field("runningTime", RunningTime.self),
      ] }

      /// Cafeteria name
      public var name: String { __data["name"] }
      /// Cafeteria latitude
      public var latitude: Double { __data["latitude"] }
      /// Cafeteria longitude
      public var longitude: Double { __data["longitude"] }
      /// Cafeteria running time
      public var runningTime: RunningTime { __data["runningTime"] }

      /// Menu.RunningTime
      ///
      /// Parent Type: `CafeteriaRunningTimeQuery`
      public struct RunningTime: QueryAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { QueryAPI.Objects.CafeteriaRunningTimeQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("breakfast", String?.self),
          .field("lunch", String?.self),
          .field("dinner", String?.self),
        ] }

        /// Breakfast running time
        public var breakfast: String? { __data["breakfast"] }
        /// Lunch running time
        public var lunch: String? { __data["lunch"] }
        /// Dinner running time
        public var dinner: String? { __data["dinner"] }
      }
    }
  }
}
