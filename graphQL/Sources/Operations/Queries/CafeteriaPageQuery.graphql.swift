// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class CafeteriaPageQuery: GraphQLQuery {
  public static let operationName: String = "CafeteriaPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query CafeteriaPageQuery($date: Date!, $campusID: Int!) { menu(date: $date, campusId: $campusID) { __typename id menu { __typename type menu price } runningTime { __typename breakfast lunch dinner } } }"#
    ))

  public var date: Date
  public var campusID: Int

  public init(
    date: Date,
    campusID: Int
  ) {
    self.date = date
    self.campusID = campusID
  }

  public var __variables: Variables? { [
    "date": date,
    "campusID": campusID
  ] }

  public struct Data: GraphQL.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("menu", [Menu].self, arguments: [
        "date": .variable("date"),
        "campusId": .variable("campusID")
      ]),
    ] }

    /// Cafeteria query
    public var menu: [Menu] { __data["menu"] }

    /// Menu
    ///
    /// Parent Type: `CafeteriaQuery`
    public struct Menu: GraphQL.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.CafeteriaQuery }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("menu", [Menu].self),
        .field("runningTime", RunningTime.self),
      ] }

      /// Cafeteria ID
      public var id: Int { __data["id"] }
      /// Menu list
      public var menu: [Menu] { __data["menu"] }
      /// Cafeteria running time
      public var runningTime: RunningTime { __data["runningTime"] }

      /// Menu.Menu
      ///
      /// Parent Type: `MenuQuery`
      public struct Menu: GraphQL.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.MenuQuery }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("type", String.self),
          .field("menu", String.self),
          .field("price", String.self),
        ] }

        /// Time type
        public var type: String { __data["type"] }
        /// Menu
        public var menu: String { __data["menu"] }
        /// Price
        public var price: String { __data["price"] }
      }

      /// Menu.RunningTime
      ///
      /// Parent Type: `CafeteriaRunningTimeQuery`
      public struct RunningTime: GraphQL.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { GraphQL.Objects.CafeteriaRunningTimeQuery }
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
