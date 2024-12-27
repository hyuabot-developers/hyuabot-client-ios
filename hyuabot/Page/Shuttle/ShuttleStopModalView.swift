//
//  ShuttleStopModal.swift
//  hyuabot
//
//  Created by 이정인 on 12/27/24.
//

import SwiftUI
import MapKit
import GraphQL


struct ShuttleStopModalView: View {
    let stopID: String.LocalizationValue
    @State private var cameraPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.30019431528426, longitude: 126.8377576083072),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    ))
    @State private var stopLocation: CLLocationCoordinate2D?

    var body: some View {
        VStack (alignment: .center, spacing: 0) {
            Text(String(localized: stopID))
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.hanyangPrimary)
            Map(
                position: $cameraPosition,
                interactionModes: [.zoom]
            ) {
                if let stopLocation = stopLocation {
                    Marker(String(localized: stopID), systemImage: "bus.fill", coordinate: stopLocation)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 400)
            Spacer()
        }.onAppear {
            fetchShuttleStopData()
        }
    }
    
    private func fetchShuttleStopData() {
        let shuttleStopID = if (stopID == "shuttle.dormitory_o") {
            "dormitory_o"
        } else if (stopID == "shuttle.shuttlecock_o") {
            "shuttlecock_o"
        } else if (stopID == "shuttle.station") {
            "station"
        } else if (stopID == "shuttle.terminal") {
            "terminal"
        } else if (stopID == "shuttle.jungang_station") {
            "jungang_stn"
        } else {
            "shuttlecock_i"
        }
        let now = Date.now.addingTimeInterval(60)
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        Network.shared.apollo.fetch(query: ShuttleStopDialogQuery(
            shuttleStopID: shuttleStopID,
            shuttleDateTime: dateTimeFormatter.string(from: now)
        )) { result in
            switch result {
                case .success(let data):
                if let stopList = data.data?.shuttle.stop {
                    guard let stop = stopList.first else { return }
                    cameraPosition = MapCameraPosition.region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    ))
                    stopLocation = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
                }
                case .failure(_):
                    print("Error fetching data")
            }
        }
    }
}

#Preview {
    ShuttleStopModalView(stopID: "shuttle.dormitory_o")
}
