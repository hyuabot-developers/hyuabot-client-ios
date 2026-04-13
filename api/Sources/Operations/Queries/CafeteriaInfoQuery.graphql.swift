// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct CafeteriaInfoQuery: GraphQLQuery {
  public static let operationName: String = "CafeteriaInfoQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query CafeteriaInfoQuery($campusID: Int!, $date: Date!) { cafeteria(input: { campus: $campusID, date: $date }) { __typename name latitude longitude runningTime { __typename breakfast lunch dinner } } }"#
    ))

  public var campusID: Int32
  public var date: Date

  public init(
    campusID: Int32,
    date: Date
  ) {
    self.campusID = campusID
    self.date = date
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "campusID": campusID,
    "date": date
  ] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("cafeteria", [Cafeterium].self, arguments: ["input": [
        "campus": .variable("campusID"),
        "date": .variable("date")
      ]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      CafeteriaInfoQuery.Data.self
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
        .field("name", String.self),
        .field("latitude", Double.self),
        .field("longitude", Double.self),
        .field("runningTime", RunningTime.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CafeteriaInfoQuery.Data.Cafeterium.self
      ] }

      public var name: String { __data["name"] }
      public var latitude: Double { __data["latitude"] }
      public var longitude: Double { __data["longitude"] }
      public var runningTime: RunningTime { __data["runningTime"] }

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
          CafeteriaInfoQuery.Data.Cafeterium.RunningTime.self
        ] }

        public var breakfast: String? { __data["breakfast"] }
        public var lunch: String? { __data["lunch"] }
        public var dinner: String? { __data["dinner"] }
      }
    }
  }
}
