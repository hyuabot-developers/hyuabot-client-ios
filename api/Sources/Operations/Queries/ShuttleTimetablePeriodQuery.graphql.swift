// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ShuttleTimetablePeriodQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleTimetablePeriodQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleTimetablePeriodQuery($date: Date!) { shuttle(input: { date: $date }) { __typename period { __typename type } } }"#
    ))

  public var date: Date

  public init(date: Date) {
    self.date = date
  }

  @_spi(Unsafe) public var __variables: Variables? { ["date": date] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("shuttle", Shuttle.self, arguments: ["input": ["date": .variable("date")]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ShuttleTimetablePeriodQuery.Data.self
    ] }

    public var shuttle: Shuttle { __data["shuttle"] }

    /// Shuttle
    ///
    /// Parent Type: `Shuttle`
    nonisolated public struct Shuttle: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Shuttle }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("period", Period?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ShuttleTimetablePeriodQuery.Data.Shuttle.self
      ] }

      public var period: Period? { __data["period"] }

      /// Shuttle.Period
      ///
      /// Parent Type: `ShuttlePeriod`
      nonisolated public struct Period: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttlePeriod }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("type", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ShuttleTimetablePeriodQuery.Data.Shuttle.Period.self
        ] }

        public var type: String { __data["type"] }
      }
    }
  }
}
