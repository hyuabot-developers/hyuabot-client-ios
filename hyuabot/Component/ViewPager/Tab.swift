//
//  Tab.swift
//  hyuabot
//
//  Created by 이정인 on 12/10/24.
//
import SwiftUI

struct Tab {
    var icon: Image?
    var title: String
}


struct Tabs: View {
    var fixedSize = true
    var tabs: [Tab]
    var geoWidth: CGFloat
    @Binding var selectedTab: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(0 ..< tabs.count, id: \.self) { index in
                            Button(
                                action: { withAnimation { selectedTab = index }},
                                label: {
                                    VStack(spacing: 0) {
                                        HStack {
                                            if (tabs[index].icon != nil) {
                                                // Tab Icon
                                                AnyView(tabs[index].icon)
                                                    .foregroundColor(.white)
                                                    .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))
                                                // Tab Title
                                                Text(tabs[index].title)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(EdgeInsets(top: 10, leading: 3, bottom: 10, trailing: 15))
                                            } else {
                                                // Tab Title
                                                Text(tabs[index].title)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
                                            }
                                        }
                                        .frame(width: fixedSize ? geoWidth / CGFloat(tabs.count) : .none, height: 48)
                                        // Tab Indicator
                                        Rectangle()
                                            .fill(selectedTab == index ? Color.white : Color.clear)
                                            .frame(height: 3)
                                    }
                                    .fixedSize()
                                    .background(Color(.hanyangPrimary))
                                }
                            )
                            .accentColor(.white)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .onChange(of: selectedTab) {
                        withAnimation { proxy.scrollTo(selectedTab) }
                    }
                }
            }
        }
        .frame(height: 50)
        .onAppear(perform: {
            UIScrollView.appearance().backgroundColor = .systemBackground
            UIScrollView.appearance().bounces = !fixedSize
        })
        .onDisappear(perform: {
            UIScrollView.appearance().bounces = true
        })
    }
}

struct Tabs_Previews: PreviewProvider {
    static var previews: some View {
        Tabs(
            fixedSize: false,
            tabs: [
                .init(title: String(localized: "shuttle.dormitory_o")),
                .init(title: String(localized: "shuttle.shuttlecock_o")),
                .init(title: String(localized: "shuttle.station")),
                .init(title: String(localized: "shuttle.terminal")),
                .init(title: String(localized: "shuttle.jungang_station")),
                .init(title: String(localized: "shuttle.shuttlecock_i"))
            ],
            geoWidth: 500,
            selectedTab: .constant(1)
        )
    }
}


