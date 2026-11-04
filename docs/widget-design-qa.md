# Widget design QA (simulator, Mobile MCP)

Design source: "HYUabot 홈 위젯" artifact. Screenshots: `/tmp/hyuabot-widget-qa/<mode>-<device>-<widget>-<family>-<fixture>.png`
(not committed). Debug build with the DEBUG-only widget gallery fixtures.

## Matrix

| Device | Widget | Families | Fixtures | Light | Dark |
|---|---|---|---|---|---|
| iPhone 18 Pro | Shuttle | S / M / L | A `shuttle-station`, B `shuttle-shuttlecock` | captured | captured |
| iPhone 18 Pro | Transfer | M / L | A `transfer-dormitory`, B `transfer-terminal` | captured | captured |
| iPhone 18 Pro | Cafeteria | S / M / L | A `cafeteria-lunch`, B `cafeteria-overflow` | captured | captured |
| iPad A16 | Cafeteria | XL | home-screen widget, WidgetKit placeholder data | captured | captured |
| iPad A16 | Cafeteria XL | XL | fixture B (`cafeteria-overflow`) | BLOCKED | BLOCKED |
| iPad A16 | Shuttle / Transfer | XL | not supported (`supportedFamilies` is S/M/L and M/L) | n/a | n/a |

## Findings / deviations from the spec

- XL exists only for the cafeteria widget. Shuttle declares S/M/L and Transfer declares M/L only, so there is no XL cell for them.
- XL was captured from the widget added to the iPad home screen, which shows WidgetKit placeholder
  data (3월 3일 화요일). The QA fixtures only apply to the in-app gallery, so fixture B at XL is BLOCKED.
- XL layout: four campus columns, meal tabs, status dots and prices render in both appearances; the lower
  half of the widget is empty because the content is short (no truncation or overflow observed).
- The live-activity layout was not exercised on a simulator.
- Cafeteria after 20:00 now queries the next day (intentional data change).

## Spec comparison (visual, per widget)

Compared against the "HYUabot 홈 위젯" tokens and layouts by eye on the captured screenshots. Reviewed in
detail: cafeteria L (dark, lunch), shuttle M (dark, station / light, shuttlecock), transfer L (light, terminal),
cafeteria L (light, overflow), cafeteria XL (light and dark). The remaining PNGs were captured but only
spot-checked for clipping and contrast; no pixel diff was run.

- Colors: light and dark backgrounds, ink, muted text, separators and brand blue follow the spec tokens;
  dormitory/immediate/price accents are legible in both appearances.
- Layout: hero blocks, badges and column counts match the spec for shuttle M/L (4 columns, 1 time each on
  fixture B), transfer L (bus-only plus terminal) and cafeteria L overflow (extra rows are cut, no clipping of
  the header).
- Known deviation: font is the system font where the spec uses Godo (web font, not bundled).

## BLOCKED / not captured

- Redacted placeholder (`.redacted`) captures for each family: not captured (the gallery shows static
  preview data and the simulator offers no way to force the redacted placeholder state).
- Cafeteria `cafeteria-tomorrow` (after-20:00 next-day menu), footer-only layout, Transfer station /
  no-connection layout and Shuttle exhausted (no remaining departures) layouts: BLOCKED. These fixtures are
  not in the gallery sets A/B used for the matrix and were not run as extra sets because of the time budget;
  their logic is covered only by `scripts/check-widget-logic.sh`.
- iPad XL cafeteria with fixture B and with real (non-placeholder) data: BLOCKED, fixtures only reach the
  in-app gallery.
- State views (empty / ended / suspended / error / permission) on the simulator: not captured (no gallery fixture
  drives them on the simulator); covered only by the logic check script.
