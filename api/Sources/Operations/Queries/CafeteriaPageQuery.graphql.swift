// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct CafeteriaPageQuery: GraphQLQuery {
  public static let operationName: String = "CafeteriaPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query CafeteriaPageQuery($date: Date!, $campusID: Int!) { cafeteria(input: { date: $date, campus: $campusID }) { __typename seq runningTime { __typename breakfast lunch dinner } menus { __typename type food price } } }"#
    ))

  public var date: Date
  public var campusID: Int32

  public init(
    date: Date,
    campusID: Int32
  ) {
    self.date = date
    self.campusID = campusID
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "date": date,
    "campusID": campusID
  ] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("cafeteria", [Cafeterium].self, arguments: ["input": [
        "date": .variable("date"),
        "campus": .variable("campusID")
      ]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      CafeteriaPageQuery.Data.self
    ] }

    public var cafeteria: [Cafeterium] { __data["cafeteria"] }

    /// Cafeterium
    ///
    /// Parent Type: `Cafeteria`
    nonisolated public struct Cafeterium: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Cafeteria }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("seq", Int.self),
        .field("runningTime", RunningTime.self),
        .field("menus", [Menu].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CafeteriaPageQuery.Data.Cafeterium.self
      ] }

      public var seq: Int { __data["seq"] }
      public var runningTime: RunningTime { __data["runningTime"] }
      public var menus: [Menu] { __data["menus"] }

      /// Cafeterium.RunningTime
      ///
      /// Parent Type: `CafeteriaRunningTime`
      nonisolated public struct RunningTime: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.CafeteriaRunningTime }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("breakfast", String?.self),
          .field("lunch", String?.self),
          .field("dinner", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CafeteriaPageQuery.Data.Cafeterium.RunningTime.self
        ] }

        public var breakfast: String? { __data["breakfast"] }
        public var lunch: String? { __data["lunch"] }
        public var dinner: String? { __data["dinner"] }
      }

      /// Cafeterium.Menu
      ///
      /// Parent Type: `Menu`
      nonisolated public struct Menu: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Menu }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("type", String.self),
          .field("food", String.self),
          .field("price", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CafeteriaPageQuery.Data.Cafeterium.Menu.self
        ] }

        public var type: String { __data["type"] }
        public var food: String { __data["food"] }
        public var price: String { __data["price"] }
      }
    }
  }
}
