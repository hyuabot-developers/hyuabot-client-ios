# Debug deep links

Debug builds accept `hyuabot://debug/<route>?<key>=<value>`. The debug host is
handled only inside `#if DEBUG`; release builds keep the existing public
deep-link behavior and ignore this host.

Examples:

```sh
xcrun simctl openurl booted \
  'hyuabot://debug/shuttle?stop=station&to=terminal'
xcrun simctl openurl booted \
  'hyuabot://debug/bus-departure-sheet?stopID=216000383&routeID=216000068'
xcrun simctl openurl booted \
  'hyuabot://debug/map-building-sheet?name=Library&url=https%3A%2F%2Fhyuabot.app'
```

Supported page routes are `home`, `shuttle`, `bus`, `subway`, `cafeteria`,
`reading-room`, `map`, `setting`, `contact`, `calendar`, `inquiry`, and
`campus`. Existing public routes remain available as `hyuabot://<page>`.

Supported direct overlays are `home-quick-settings`, `shuttle-quick-settings`,
`bus-quick-settings`, `shuttle-stop-sheet`, `bus-departure-sheet`,
`bus-stop-sheet`, `cafeteria-info-sheet`, `map-building-sheet`, and
`web-sheet`.

Useful arguments include `stop`, `to`, `stopID`, `routeID`, `cafeteriaID`,
`name`, and `url`. Missing or invalid values use safe preview defaults.
