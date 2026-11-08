// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

nonisolated public struct CommuterBusPageQuery: GraphQLQuery {
  public static let operationName: String = "CommuterBusPageQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query CommuterBusPageQuery($date: Date!) { commute { __typename name description { __typename korean english } timetable { __typename name order time stop { __typename name latitude longitude description } } } shuttle(input: { date: $date }) { __typename period { __typename type start end } holiday { __typename type date } } }"#
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
      .field("commute", [Commute].self),
      .field("shuttle", Shuttle.self, arguments: ["input": ["date": .variable("date")]]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      CommuterBusPageQuery.Data.self
    ] }

    public var commute: [Commute] { __data["commute"] }
    public var shuttle: Shuttle { __data["shuttle"] }

    /// Commute
    ///
    /// Parent Type: `CommuteShuttleRoute`
    nonisolated public struct Commute: Api.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.CommuteShuttleRoute }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("name", String.self),
        .field("description", Description.self),
        .field("timetable", [Timetable].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CommuterBusPageQuery.Data.Commute.self
      ] }

      public var name: String { __data["name"] }
      public var description: Description { __data["description"] }
      public var timetable: [Timetable] { __data["timetable"] }

      /// Commute.Description
      ///
      /// Parent Type: `CommuteShuttleDescription`
      nonisolated public struct Description: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.CommuteShuttleDescription }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("korean", String.self),
          .field("english", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CommuterBusPageQuery.Data.Commute.Description.self
        ] }

        public var korean: String { __data["korean"] }
        public var english: String { __data["english"] }
      }

      /// Commute.Timetable
      ///
      /// Parent Type: `CommuteShuttleTimetable`
      nonisolated public struct Timetable: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.CommuteShuttleTimetable }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("name", String.self),
          .field("order", Int.self),
          .field("time", Api.LocalTime.self),
          .field("stop", Stop?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CommuterBusPageQuery.Data.Commute.Timetable.self
        ] }

        public var name: String { __data["name"] }
        public var order: Int { __data["order"] }
        public var time: Api.LocalTime { __data["time"] }
        public var stop: Stop? { __data["stop"] }

        /// Commute.Timetable.Stop
        ///
        /// Parent Type: `CommuteShuttleStop`
        nonisolated public struct Stop: Api.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.CommuteShuttleStop }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("name", String.self),
            .field("latitude", Double.self),
            .field("longitude", Double.self),
            .field("description", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CommuterBusPageQuery.Data.Commute.Timetable.Stop.self
          ] }

          public var name: String { __data["name"] }
          public var latitude: Double { __data["latitude"] }
          public var longitude: Double { __data["longitude"] }
          public var description: String { __data["description"] }
        }
      }
    }

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
        .field("holiday", Holiday?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CommuterBusPageQuery.Data.Shuttle.self
      ] }

      public var period: Period? { __data["period"] }
      public var holiday: Holiday? { __data["holiday"] }

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
          .field("start", Api.DateTime.self),
          .field("end", Api.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CommuterBusPageQuery.Data.Shuttle.Period.self
        ] }

        public var type: String { __data["type"] }
        public var start: Api.DateTime { __data["start"] }
        public var end: Api.DateTime { __data["end"] }
      }

      /// Shuttle.Holiday
      ///
      /// Parent Type: `ShuttleHoliday`
      nonisolated public struct Holiday: Api.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { Api.Objects.ShuttleHoliday }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("type", String.self),
          .field("date", Api.Date.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CommuterBusPageQuery.Data.Shuttle.Holiday.self
        ] }

        public var type: String { __data["type"] }
        public var date: Api.Date { __data["date"] }
      }
    }
  }
}
