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
    @State private var campusWeekdayFirstTime: String = "--:--"
    @State private var campusWeekdayLastTime: String = "--:--"
    @State private var campusWeekendFirstTime: String = "--:--"
    @State private var campusWeekendLastTime: String = "--:--"
    @State private var stationWeekdayFirstTime: String = "--:--"
    @State private var stationWeekdayLastTime: String = "--:--"
    @State private var stationWeekendFirstTime: String = "--:--"
    @State private var stationWeekendLastTime: String = "--:--"
    @State private var terminalWeekdayFirstTime: String = "--:--"
    @State private var terminalWeekdayLastTime: String = "--:--"
    @State private var terminalWeekendFirstTime: String = "--:--"
    @State private var terminalWeekendLastTime: String = "--:--"
    @State private var jungangStationWeekdayFirstTime: String = "--:--"
    @State private var jungangStationWeekdayLastTime: String = "--:--"
    @State private var jungangStationWeekendFirstTime: String = "--:--"
    @State private var jungangStationWeekendLastTime: String = "--:--"
    

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
            .frame(maxWidth: .infinity, maxHeight: 320)
            Text(String(localized: "shuttle.first.last.time.title"))
                .font(.system(size: 16, weight: .bold, design: .default))
                .padding(.vertical, 16)
            Grid {
                GridRow {
                    Text(String(localized: "shuttle.heading"))
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .frame(maxWidth: .infinity)
                    Text(String(localized: "shuttle.first.time"))
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .frame(maxWidth: .infinity)
                    Text(String(localized: "shuttle.last.time"))
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .frame(maxWidth: .infinity)
                }.padding(.bottom, 8)
                if (self.stopID != "shuttle.dormitory_o" && self.stopID != "shuttle.shuttlecock_o") {
                    GridRow {
                        Text(String(localized: "shuttle.destination.campus"))
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .frame(maxWidth: .infinity)
                        Grid {
                            GridRow {
                                Text(String(localized: "shuttle.first.last.weekday.\(campusWeekdayFirstTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                                Text(String(localized: "shuttle.first.last.weekday.\(campusWeekdayLastTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                            }
                            GridRow {
                                Text(String(localized: "shuttle.first.last.weekend.\(campusWeekendFirstTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                                Text(String(localized: "shuttle.first.last.weekend.\(campusWeekendLastTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                            }
                        }.gridCellColumns(2)
                    }.padding(.bottom, 8)
                }
                if (self.stopID == "shuttle.dormitory_o" || self.stopID == "shuttle.shuttlecock_o") {
                    GridRow {
                        Text(String(localized: "shuttle.destination.station"))
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .frame(maxWidth: .infinity)
                        Grid {
                            GridRow {
                                Text(String(localized: "shuttle.first.last.weekday.\(stationWeekdayFirstTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                                Text(String(localized: "shuttle.first.last.weekday.\(stationWeekdayLastTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                            }
                            GridRow {
                                Text(String(localized: "shuttle.first.last.weekend.\(stationWeekendFirstTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                                Text(String(localized: "shuttle.first.last.weekend.\(stationWeekendLastTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                            }
                        }.gridCellColumns(2)
                    }.padding(.bottom, 8)
                }
                if (self.stopID == "shuttle.dormitory_o" || self.stopID == "shuttle.shuttlecock_o" || self.stopID == "shuttle.station") {
                    GridRow {
                        Text(String(localized: "shuttle.destination.terminal"))
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .frame(maxWidth: .infinity)
                        Grid {
                            GridRow {
                                Text(String(localized: "shuttle.first.last.weekday.\(terminalWeekdayFirstTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                                Text(String(localized: "shuttle.first.last.weekday.\(terminalWeekdayLastTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                            }
                            GridRow {
                                Text(String(localized: "shuttle.first.last.weekend.\(terminalWeekendFirstTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                                Text(String(localized: "shuttle.first.last.weekend.\(terminalWeekendLastTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                            }
                        }.gridCellColumns(2)
                    }.padding(.bottom, 8)
                }
                if (self.stopID == "shuttle.dormitory_o" || self.stopID == "shuttle.shuttlecock_o" || self.stopID == "shuttle.station") {
                    GridRow {
                        Text(String(localized: "shuttle.destination.jungang_station"))
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .frame(maxWidth: .infinity)
                        Grid {
                            GridRow {
                                Text(String(localized: "shuttle.first.last.weekday.\(jungangStationWeekdayFirstTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                                Text(String(localized: "shuttle.first.last.weekday.\(jungangStationWeekdayLastTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                            }
                            GridRow {
                                Text(String(localized: "shuttle.first.last.weekend.\(jungangStationWeekendFirstTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                                Text(String(localized: "shuttle.first.last.weekend.\(jungangStationWeekendLastTime)"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 4)
                            }
                        }.gridCellColumns(2)
                    }
                }
            }
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
