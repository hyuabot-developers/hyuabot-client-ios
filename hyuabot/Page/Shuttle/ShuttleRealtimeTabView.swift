//
//  ShuttleRealtimeTabView.swift
//  hyuabot
//
//  Created by 이정인 on 12/10/24.
//


import SwiftUI
import GraphQL


struct ShuttleRealtimeTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var arrival: [ShuttleRealtimePageQuery.Data.Shuttle.Timetable]

    let stopID: String.LocalizationValue
    let desinations: [String.LocalizationValue]

    var body: some View {
        ZStack {
            Color(.systemBackground)
            ScrollView {
                VStack {
                    ForEach(desinations.indices, id: \.self) { index in
                        ShuttleRealtimeSectionView(arrival: $arrival, stopID: stopID, destination: desinations[index])
                    }
                    Button(action: {}) {
                        Text(String(localized: "shuttle.stop.info"))
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .foregroundColor(colorScheme == .dark ? .white : .hanyangPrimary)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity)
                    }.padding(.vertical, 10)
                }
                .background(Color(.systemBackground))
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
            }
        }
    }
}

#Preview {
    ShuttleRealtimeTabView(
        arrival: .constant([]),
        stopID: "shuttle.dormitory_o",
        desinations: [
            "shuttle.destination.station",
            "shuttle.destination.terminal",
            "shuttle.destination.jungang_station"
        ]
    )
}
