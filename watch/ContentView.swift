//
//  ContentView.swift
//  watch Watch App
//
//  Created by 이정인 on 4/12/25.
//

import SwiftUI

struct ContentView: View {
    let stopList = ["기숙사", "셔틀콕", "한대앞", "예술인", "중앙역", "셔틀콕 건너편"]
    var body: some View {
        NavigationStack {
            List {
                ForEach(stopList, id: \.self) { stop in
                    NavigationLink(destination: DepartureListView(stop: stop)) {
                        HStack {
                            Text(stop).font(.godo(size: 16, weight: .regular))
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
