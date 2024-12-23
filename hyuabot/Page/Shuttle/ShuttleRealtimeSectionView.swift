//
//  ShuttleRealtimeSectionView.swift
//  hyuabot
//
//  Created by 이정인 on 12/19/24.
//

import SwiftUI
import GraphQL


struct ShuttleRealtimeSectionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var arrival: [ShuttleRealtimePageQuery.Data.Shuttle.Timetable]


    let stopID: String.LocalizationValue
    let destination: String.LocalizationValue

    var body: some View {
        let arrivalList: [ShuttleRealtimePageQuery.Data.Shuttle.Timetable] = if (
            self.stopID == "shuttle.dormitory_o" || self.stopID == "shuttle.shuttlecock_o"
        ) {
            if (self.destination == "shuttle.destination.station") {
                Array(self.arrival.filter { $0.tag == "DH" || $0.tag == "C" }.prefix(3))
            } else if (self.destination == "shuttle.destination.terminal") {
                Array(self.arrival.filter { $0.tag == "DY" || $0.tag == "C" }.prefix(3))
            } else if (self.destination == "shuttle.destination.jungang_station") {
                Array(self.arrival.filter { $0.tag == "DJ"} .prefix(3))
            } else {
                []
            }
        } else if (self.stopID == "shuttle.station") {
            if (self.destination == "shuttle.destination.campus") {
                Array(self.arrival.prefix(3))
            } else if (self.destination == "shuttle.destination.terminal") {
                Array(self.arrival.filter { $0.tag == "C" }.prefix(3))
            } else if (self.destination == "shuttle.destination.jungang_station") {
                Array(self.arrival.filter { $0.tag == "DJ" }.prefix(3))
            } else {
                []
            }
        } else {
            Array(self.arrival.prefix(7))
        }
        VStack {
            Text(String(localized: destination))
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.hanyangPrimary)
            if (arrivalList.count > 0) {
                ForEach(arrivalList.indices, id: \.self) { index in
                    ShuttleRealtimeItemView(arrival: arrivalList[index], stopID: stopID, destination: destination)
                }
            } else {
                Text("shuttle.arrival.no.data")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
            Button(action: {}) {
                Text(String(localized: "shuttle.entire.timetable"))
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(colorScheme == .dark ? .white : .hanyangPrimary)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    ShuttleRealtimeSectionView(arrival: .constant([]), stopID: "dormitory_o", destination: "shuttle.destination.station")
}
