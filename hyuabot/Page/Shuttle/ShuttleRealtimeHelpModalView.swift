//
//  ShuttleRealtimeHelpModalView.swift
//  hyuabot
//
//  Created by 이정인 on 12/26/24.
//

import SwiftUI

struct ShuttleRealtimeHelpModalView: View {
    var body: some View {
        VStack (alignment: .leading) {
            Text(String(localized: "shuttle.help.dialog.title"))
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.hanyangPrimary)
            Text(String(localized: "shuttle.help.dialog.content.title.1"))
                .font(.system(size: 16, weight: .bold, design: .default))
                .padding(.top, 8)
                .padding(.horizontal, 16)
            Text(String(localized: "shuttle.help.dialog.content.1"))
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .lineLimit(5)
            Divider()
            Text(String(localized: "shuttle.help.dialog.content.title.2"))
                .font(.system(size: 16, weight: .bold, design: .default))
                .padding(.top, 8)
                .padding(.horizontal, 16)
            Text(String(localized: "shuttle.help.dialog.content.2"))
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .lineLimit(5)
            Divider()
            Text(String(localized: "shuttle.help.dialog.content.title.3"))
                .font(.system(size: 16, weight: .bold, design: .default))
                .padding(.top, 8)
                .padding(.horizontal, 16)
            Text(String(localized: "shuttle.help.dialog.content.3"))
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .lineLimit(5)
            Divider()
            Text(String(localized: "shuttle.help.dialog.content.title.4"))
                .font(.system(size: 16, weight: .bold, design: .default))
                .padding(.top, 8)
                .padding(.horizontal, 16)
            Text(String(localized: "shuttle.help.dialog.content.4"))
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .lineLimit(5)
            Divider()
            Text(String(localized: "shuttle.help.dialog.content.title.5"))
                .font(.system(size: 16, weight: .bold, design: .default))
                .padding(.top, 8)
                .padding(.horizontal, 16)
            Text(String(localized: "shuttle.help.dialog.content.5"))
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .lineLimit(5)
            Spacer()
        }
    }
}

#Preview { ShuttleRealtimeHelpModalView() }
