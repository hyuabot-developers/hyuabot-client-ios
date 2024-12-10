//
//  ShuttleRealtimeTabView.swift
//  hyuabot
//
//  Created by 이정인 on 12/10/24.
//


import SwiftUI

struct ShuttleRealtimeTabView: View {
    let stopID: String.LocalizationValue
    var body: some View {
        ZStack {
            Color(.systemBackground)
            Text(String(localized: self.stopID))
        }
    }
}

#Preview {
    ShuttleRealtimeTabView(stopID: "shuttle.dormitory_o")
}
