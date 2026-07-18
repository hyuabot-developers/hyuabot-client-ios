# HYUabot iOS / watchOS Client

A campus companion app for **Hanyang University (ERICA campus)** students and staff, providing real-time transportation data, campus facility information, and academic resources — available on iPhone and Apple Watch.

---

## Features

### Transportation
| Tab | Feature |
|-----|---------|
| Shuttle | Real-time arrivals & full timetable by route/period/day type |
| Bus | Real-time arrivals, timetable, departure logs, route/stop info |
| Subway | Real-time train arrivals & timetable for adjacent station |

### Campus Info
| Tab | Feature |
|-----|---------|
| Cafeteria | Daily menus and operating hours by dining hall |
| Map | Interactive campus map with building and room search |
| Reading Room | Seat availability with push-notification alerts |
| Contact | Faculty/staff phone directory with search |
| Calendar | Academic calendar events |
| Settings | Theme (light/dark/system), notification preferences |
| Chat | Kakao Open Chat link |
| Donate | Kakao Pay donation link |

### Apple Watch
- Shuttle real-time departure list via a native SwiftUI watchOS app
- Auto-refreshes every 10 seconds

---

## Architecture

### iOS App (`hyuabot/`)
- **UIKit** with MVC/MVVM patterns
- **RxSwift** for reactive data streams and polling
- **GraphQL** (Apollo iOS SDK v2.2.0) for all API calls
- **RealmSwift** for local persistence (Calendar events, Contacts)
- **Firebase Cloud Messaging** for push notifications

### watchOS App (`watch/`)
- **SwiftUI** native interface
- Shares the same Apollo-based `Api` Swift Package for GraphQL queries
- **RxSwift + MVVM** for data binding

### API Layer (`api/`)
- Standalone Swift Package (`Api`) wrapping Apollo-generated code
- Type-safe query/response models auto-generated from the GraphQL schema
- Compatible with iOS 15+, watchOS 8+, macOS 12+, tvOS 15+, visionOS 1+

---

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| iOS | 15.0 |
| watchOS | 8.0 |
| Xcode | 15+ |
| Swift | 5.9+ (Swift 6 mode enabled) |

---

## Dependencies

Managed via **Swift Package Manager**:

| Library | Version | Purpose |
|---------|---------|---------|
| [apollo-ios](https://github.com/apollographql/apollo-ios) | 2.2.0 (exact) | GraphQL client & codegen |
| Firebase iOS SDK | latest | Push notifications (FCM) |
| RealmSwift | latest | Local database |
| RxSwift | latest | Reactive programming |
| SnapKit | latest | Auto Layout DSL |
| Then | latest | Swift syntactic sugar |

---

## Project Structure

```
hyuabot-client-ios/
├── hyuabot/                    # iOS app target
│   ├── AppDelegate.swift       # Firebase init, push notification handling
│   ├── SceneDelegate.swift     # Window setup, theme loading
│   ├── Controller/             # UIViewControllers by feature
│   │   ├── RootVC.swift        # Tab bar root (11 tabs)
│   │   ├── Bus/
│   │   ├── Shuttle/
│   │   ├── Subway/
│   │   ├── Cafeteria/
│   │   ├── Map/
│   │   ├── ReadingRoom/
│   │   ├── Contact/
│   │   ├── Calendar/
│   │   └── Setting/
│   ├── Component/              # Reusable UI components
│   │   ├── Notice/             # Auto-rotating notice carousel
│   │   ├── Toast/              # Toast message overlay
│   │   └── ViewPager/          # Tabbed pager container
│   ├── Model/                  # Realm object models (Calendar, Contact)
│   ├── Service/
│   │   ├── Network.swift       # Apollo GraphQL client singleton
│   │   └── Database.swift      # Realm database singleton
│   ├── Utility/                # Extensions (GraphQL types, UserDefaults, MapKit, String)
│   └── Font/                   # Godo font family (GodoB.otf, GodoM.otf)
│
├── watch/                      # watchOS app target
│   ├── watchApp.swift
│   ├── ContentView.swift
│   ├── DepartureListView.swift
│   ├── DepartureListViewModel.swift
│   └── Service/Network.swift
│
├── api/                        # Swift Package: Apollo-generated GraphQL types
│   ├── Package.swift
│   └── Sources/
│       ├── Operations/Queries/ # Generated Swift query operations
│       └── Schema/             # Generated GraphQL schema types
│
├── query/                      # GraphQL query definition files (.graphql)
│   ├── ShuttleRealtimePageQuery.graphql
│   ├── BusRealtimePageQuery.graphql
│   ├── SubwayRealtimePageQuery.graphql
│   └── ... (21 query files total)
│
├── apollo-codegen-config.json  # Apollo CLI codegen configuration
├── apollo-ios-cli              # Apollo CLI binary (bundled)
└── .github/workflows/build.yml # CI/CD pipeline
```

---

## GraphQL API

All data is fetched from the HYUabot backend:

**Endpoint:** `https://backend.hyuabot.app/graphql`

### Query Domains

| Domain | Queries |
|--------|---------|
| Shuttle | `ShuttleRealtimePageQuery`, `ShuttleTimetablePageQuery`, `ShuttleStopDialogQuery`, `ShuttleTimetablePeriodQuery` |
| Bus | `BusRealtimePageQuery`, `BusTimetablePageQuery`, `BusStopDialogQuery`, `BusRouteInfoDialogQuery`, `BusDepartureLogQuery` |
| Subway | `SubwayRealtimePageQuery`, `SubwayTimetablePageQuery` |
| Cafeteria | `CafeteriaPageQuery`, `CafeteriaInfoQuery` |
| Map | `MapPageQuery`, `MapPageSearchQuery` |
| Reading Room | `ReadingRoomPageQuery` |
| Contact | `ContactPageQuery`, `ContactPageVersionQuery` |
| Calendar | `CalendarPageQuery`, `CalendarPageVersionQuery` |

### Regenerating GraphQL Code

To update the schema and regenerate Swift types after the backend schema changes:

```bash
# Download the latest schema from the backend
./apollo-ios-cli fetch-schema --path apollo-codegen-config.json

# Regenerate Swift code from updated .graphql files
./apollo-ios-cli generate --path apollo-codegen-config.json
```

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/hyuabot-developers/hyuabot-client-ios.git
cd hyuabot-client-ios
```

### 2. Add Firebase configuration

The `GoogleService-Info.plist` file is required for Firebase (push notifications) but is not included in the repository.

- Obtain `GoogleService-Info.plist` from the Firebase Console for this project
- Place it at `hyuabot/GoogleService-Info.plist`

### 3. Open in Xcode

```bash
open hyuabot.xcodeproj
```

Swift Package Manager will automatically resolve all dependencies on first open.

### 4. Build & Run

Select the `hyuabot` scheme and a simulator/device and press **Run** (`Cmd+R`).

For the watchOS app, select the `watch` scheme with a paired Apple Watch simulator.

---

## Push Notifications

The app uses **Firebase Cloud Messaging (FCM)** for reading room seat availability alerts.

- Users subscribe to FCM topics per reading room (e.g., `reading_room_1`)
- When a seat becomes available, the backend publishes to the topic
- The app receives the notification, displays a local alert, and automatically unsubscribes from that topic
- Subscriptions are persisted in `UserDefaults` (`readingRoomNotificationArray`)

Supported reading rooms: `1`, `53`, `54`, `55`, `56`, `61`, `63`, `131`, `132`

---

## Localization

The app supports **Korean** (primary) and **English**, using the `.xcstrings` format:

- `hyuabot/Localization/Localizable.xcstrings` — UI strings
- `hyuabot/Localization/InfoPlist.xcstrings` — Info.plist strings

---

## Theming

Three theme modes selectable from the Settings tab:

| ID | Mode |
|----|------|
| 0 | System (follows device setting) |
| 1 | Light |
| 2 | Dark |

The preference is persisted in `UserDefaults` under the key `themeID`.

The app uses **Hanyang Blue** (`hanyangBlue`) as the primary brand color and the **Godo** font family (GodoB / GodoM) throughout the UI.

---

## CI/CD

GitHub Actions workflow (`.github/workflows/build.yml`) runs on every pull request:

1. Checks out the repository
2. Injects `GoogleService-Info.plist` from a base64-encoded GitHub secret (`GOOGLE_SERVICE_INFO_PLIST`)
3. Builds the `hyuabot` scheme against the latest iOS simulator (iPhone 17 Pro)

Runs on a **self-hosted macOS runner**.

```bash
xcodebuild -project hyuabot.xcodeproj \
           -scheme hyuabot \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
           -quiet clean build
```

---

## Contributing

1. Fork the repository and create a feature branch
2. Make changes — ensure the Xcode build passes locally before opening a PR
3. Open a Pull Request; the CI build will run automatically

---

## License

See [LICENSE](LICENSE) for details.
