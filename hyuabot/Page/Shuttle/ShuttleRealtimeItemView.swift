//
//  Untitled.swift
//  hyuabot
//
//  Created by 이정인 on 12/23/24.
//

import SwiftUI
import GraphQL

struct ShuttleRealtimeItemView: View {
    @Binding var showRemainingMinutes: Bool
    var arrival: ShuttleRealtimePageQuery.Data.Shuttle.Timetable
    let stopID: String.LocalizationValue
    let destination: String.LocalizationValue
    let toggleRemainingTime: (Bool) -> Void

    
    var body: some View {
        VStack {
            HStack (alignment: .center) {
                Text(tagToLocalizedString(arrival.tag, routeID: arrival.route))
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxHeight: .infinity, alignment: .center)
                    .foregroundColor(tagToColor(arrival.tag, routeID: arrival.route))
                Spacer()
                Text(showRemainingMinutes ? remainingTimeToLocalizedString(arrival.time) : timeToLocalizedString(arrival.time))
                    .font(.system(size: 18))
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .onTapGesture(perform: {
                
            })
            .onLongPressGesture(minimumDuration: 0.75, perform: {
                toggleRemainingTime(false)
            }, onPressingChanged: { inProgress in
                if (!inProgress && !showRemainingMinutes) {
                    toggleRemainingTime(true)
                }
            })
            Divider()
        }
        .padding(.horizontal, 20)
    }
    
    private func timeToLocalizedString(_ time: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let date = dateFormatter.date(from: time)
        if let date = date {
            let hour = Calendar.current.component(.hour, from: date)
            let minute = Calendar.current.component(.minute, from: date)
            return String(localized: "shuttle.arrival.time.\(hour).\(minute)")
        }
        return ""
    }
    
    private func remainingTimeToLocalizedString(_ time: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        let now = Date.now
        let currentHour = Calendar.current.component(.hour, from: now)
        let currentMinute = Calendar.current.component(.minute, from: now)
        
        let date = dateFormatter.date(from: time)
        if let date = date {
            let hour = Calendar.current.component(.hour, from: date)
            let minute = Calendar.current.component(.minute, from: date)
            let remaingMinute = (hour - currentHour) * 60 + (minute - currentMinute)
            return String(localized: "shuttle.arrival.remaining.time.\(remaingMinute)")
        }
        return ""
    }
    
    private func tagToLocalizedString(_ tag: String, routeID: String) -> String {
        if (stopID == "shuttle.dormitory_o" || stopID == "shuttle.shuttlecock_o") {
            if (tag == "DH") {
                return String(localized: "shuttle.type.station")
            } else if (tag == "DY") {
                return String(localized: "shuttle.type.terminal")
            } else if (tag == "DJ") {
                return String(localized: "shuttle.type.jungang")
            } else if (tag == "C") {
                return String(localized: "shuttle.type.circular")
            }
        }
        else if (stopID == "shuttle.station") {
            if (tag == "DH") {
                return String(localized: "shuttle.type.direct")
            } else if (tag == "C") {
                return String(localized: "shuttle.type.circular")
            } else if (tag == "DJ") {
                return String(localized: "shuttle.type.jungang")
            }
            
        }
        else if (stopID == "shuttle.terminal" || stopID == "shuttle.jungang_station" || stopID == "shuttle.shuttlecock_i") {
            if (routeID.hasSuffix("D")) {
                return String(localized: "shuttle.type.dormitory")
            } else if (routeID.hasSuffix("S")) {
                return String(localized: "shuttle.type.shuttlecock")
            } else {
                return ""
            }
        }
        return ""
    }
    
    private func tagToColor(_ tag: String, routeID: String) -> Color? {
        if (stopID == "shuttle.dormitory_o" || stopID == "shuttle.shuttlecock_o") {
            if (tag == "DH" || tag == "DY") {
                return .busRed
            } else if (tag == "DJ") {
                return .busGreen
            } else if (tag == "C") {
                return .busBlue
            }
        }
        else if (stopID == "shuttle.station") {
            if (tag == "DH") {
                return .busRed
            } else if (tag == "C") {
                return .busBlue
            } else if (tag == "DJ") {
                return .busGreen
            }
            
        }
        return nil
    }
}
