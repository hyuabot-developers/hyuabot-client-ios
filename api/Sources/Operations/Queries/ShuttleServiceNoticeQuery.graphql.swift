// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct ShuttleServiceNoticeQuery: GraphQLQuery {
  public static let operationName: String = "ShuttleServiceNoticeQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ShuttleServiceNoticeQuery($start: Date!, $end: Date!) { shuttle(input: {  }) { __typename serviceNotices(start: $start, end: $end) { __typename id kind date period { __typename type } holiday { __typename type } } } }"#
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
      .field("shuttle", Shuttle.self, arguments: ["input": []]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ShuttleServiceNoticeQuery.Data.self
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
        .field("serviceNotices", [ServiceNotice].self, arguments: [
          "start": .variable("start"),
          "end": .variable("end")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ShuttleServiceNoticeQuery.Data.Shuttle.self
      ] }

      public var serviceNotices: [ServiceNotice] { __data["serviceNotices"] }

      /// Shuttle.ServiceNotice
      ///
      /// Parent Type: `ShuttleServiceNotice`
      nonisolated public struct ServiceNotice: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttleServiceNotice }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("kind", String.self),
          .field("date", Api.Date.self),
          .field("period", Period?.self),
          .field("holiday", Holiday?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ShuttleServiceNoticeQuery.Data.Shuttle.ServiceNotice.self
        ] }

        public var id: String { __data["id"] }
        public var kind: String { __data["kind"] }
        public var date: Api.Date { __data["date"] }
        public var period: Period? { __data["period"] }
        public var holiday: Holiday? { __data["holiday"] }

        /// Shuttle.ServiceNotice.Period
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
            ShuttleServiceNoticeQuery.Data.Shuttle.ServiceNotice.Period.self
          ] }

          public var type: String { __data["type"] }
        }

        /// Shuttle.ServiceNotice.Holiday
        ///
        /// Parent Type: `ShuttleHoliday`
        nonisolated public struct Holiday: Api.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttleHoliday }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("type", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ShuttleServiceNoticeQuery.Data.Shuttle.ServiceNotice.Holiday.self
          ] }

          public var type: String { __data["type"] }
        }
      }
    }
  }
}
