// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct PublicHolidayQuery: GraphQLQuery {
  public static let operationName: String = "PublicHolidayQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query PublicHolidayQuery($start: Date!, $end: Date!) { publicHolidays(start: $start, end: $end) }"#
    ))

  public var start: Date
  public var end: Date

  public init(
    start: Date,
    end: Date
  ) {
    self.start = start
    self.end = end
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "start": start,
    "end": end
  ] }

  nonisolated public struct Data: Api.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("publicHolidays", [Api.Date].self, arguments: [
        "start": .variable("start"),
        "end": .variable("end")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      PublicHolidayQuery.Data.self
    ] }

    public var publicHolidays: [Api.Date] { __data["publicHolidays"] }
  }
}
