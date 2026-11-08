# Cafeteria design geometry audit

Design source: [Cafeteria artifact](https://claude.ai/artifact/NjFCFkDhaqLQYA594K7cZw), using `Cafeteria.dc.html`, `CafeteriaSheet.dc.html`, `CafeteriaEmpty.dc.html`, and `CafeteriaLoading.dc.html` (CSS px treated as points).

## Page safe-area and content insets

| Property | Design value (artboard + CSS selector/inline style) | Planned value | Implemented value (file:line) | Match (yes/no) |
|---|---|---|---|---|
| Content insets | Cafeteria `.cp-scroll`, line 31: 92px top, 16px sides, 112px bottom; native safe area expected | Safe area + 45 top, 16 sides, safe area + 24 bottom | `CafeteriaVC.swift:82-113`: automatic inset adjustment, 45 top, 16 sides, 24 bottom | yes |
| Bottom fade | Cafeteria inline style line 146: 120px | 120pt | `CafeteriaVC.swift:114-117` | yes |
| Light/dark colors | Cafeteria theme tokens `t.bg`, `t.fadeFrom` | SettingsStyle background/fade tokens | `CafeteriaVC.swift:78,91-94`; `CafeteriaBottomFadeView` tokenized | yes |

## Header controls

| Property | Design value (artboard + CSS selector/inline style) | Planned value | Implemented value (file:line) | Match (yes/no) |
|---|---|---|---|---|
| Title | Cafeteria inline style line 35: 32px/40px | 32pt title | `CafeteriaHeaderBarView.swift:34-40` (Godo title, 32pt) | yes |
| Month control | Cafeteria inline style line 38: 44px hit area, 14px label | 44pt hit area, 14pt label | `CafeteriaHeaderBarView.swift:95-97,118-123` month control | yes |
| Today pill | Cafeteria inline style line 46: 32px high, 12px horizontal padding, radius 16 | 32pt, radius 16 | `CafeteriaHeaderBarView.swift:23,69-73,108-116` (44pt button, 32pt capsule) | yes |
| Share control | Cafeteria inline style line 388: 44px, radius 22 | 44pt, radius 22 | `CafeteriaHeaderBarView.swift:58-69,99-105` | yes |
| Light/dark colors | Theme tokens `t.text`, `t.link`, `t.accentFill`, `t.seg` | SettingsStyle text/link/accent tokens | `CafeteriaHeaderBarView.swift` uses SettingsStyle tokens | yes |

## Week strip

| Property | Design value (artboard + CSS selector/inline style) | Planned value | Implemented value (file:line) | Match (yes/no) |
|---|---|---|---|---|
| Cell size and spacing | Cafeteria inline styles lines 54, 295-309: 56px cells, 2px gaps, 34px date circle, 6px vertical padding | 56pt cells, 2pt gaps, 34pt circle | `CafeteriaWeekStripView.swift:46,94-121` | yes |
| Selected/today styling | Cafeteria inline styles lines 297-298: accent selected, accent fill today | Same semantic tokens | `CafeteriaWeekStripView.swift:46,94-121` | yes |
| Week swipe | Cafeteria inline style line 54 and script lines 307-309: horizontal pointer swipe | Horizontal week swipe | `CafeteriaWeekStripView.swift:46,94-121` | yes |
| Light/dark colors | `t.card`, `t.accent`, `t.accentFill`, `t.text` | SettingsStyle semantic tokens | `CafeteriaWeekStripView.swift:46,94-121` | yes |

## Meal segment

| Property | Design value (artboard + CSS selector/inline style) | Planned value | Implemented value (file:line) | Match (yes/no) |
|---|---|---|---|---|
| Container and buttons | Cafeteria inline style line 65, script line 278: 4px padding/gaps, radius 12, 36px buttons radius 9 | 4pt, radius 12, 36pt/radius 9, 4pt gaps | `CafeteriaMealSegmentView.swift:21-49` | yes |
| Count gap | Cafeteria script line 278: 6px gap | 6pt | `CafeteriaMealSegmentView.swift:21-49` | yes |
| Light/dark colors | `t.seg`, `t.segOn`, `t.text`, `t.sub` | SettingsStyle segment tokens | `CafeteriaMealSegmentView.swift:21-49` | yes |

## Card headers and rows

| Property | Design value (artboard + CSS selector/inline style) | Planned value | Implemented value (file:line) | Match (yes/no) |
|---|---|---|---|---|
| Header insets/separator | Cafeteria inline style lines 92-103: 14/16/8px, 1px separator, 44px info button with -12px trailing overlap | Same | `CafeteriaMenuCardView.swift:15-78` | yes |
| Status chip | Cafeteria script line 349: 20px height, radius 10 | 20pt, radius 10 | `CafeteriaMenuCardView.swift` (header, rows, PaddingLabel) (status chip) | yes |
| Row layout and price | Cafeteria inline styles lines 107-116, script lines 360-361: 16px inset, 8/10/12px vertical padding, 12px price gap, price min-width 64px and 24px tag offset | Same | `CafeteriaMenuCardView.swift` (header, rows, PaddingLabel) | yes |
| Menu tag radius | Cafeteria inline style line 112: radius 10px | Radius 10 | `CafeteriaMenuCardView.swift (tag chip, radius 10)`: radius 10 (fixed by coordinator) | yes |
| Card spacing | Cafeteria inline style line 90: 12px | 12pt | `CafeteriaVC.swift:87,103` | yes |
| Light/dark colors | `t.card`, `t.sep`, `t.tagFill`, `t.tagText`, `t.link`, `t.sub` | SettingsStyle semantic tokens | `CafeteriaMenuCardView.swift:26,72,138-148,167-201` | yes |

## Skeleton bars

| Property | Design value (artboard + CSS selector/inline style) | Planned value | Implemented value (file:line) | Match (yes/no) |
|---|---|---|---|---|
| Header bars | CafeteriaLoading inline style lines 75-80: 112x16 and 140x12, 6px spacing | Same | `CafeteriaStateViews.swift:73-74` | yes |
| Row bars and price | CafeteriaLoading script lines 412, 416: 14/12px heights, 58/46/64% and 82/70/76% widths, 52x14 price | Same | `CafeteriaStateViews.swift:126-136` | yes |
| Vertical rhythm and colors | CafeteriaLoading inline style line 72: 12px cards gap; lines 75-80: 6px; theme `t.seg` | Same | `CafeteriaVC.swift:87`; `CafeteriaStateViews.swift:146-150` | yes |

## Empty card

| Property | Design value (artboard + CSS selector/inline style) | Planned value | Implemented value (file:line) | Match (yes/no) |
|---|---|---|---|---|
| Padding and icon | CafeteriaEmpty inline style lines 129-130: 32/24px padding, 56px icon circle | Same | `CafeteriaStateViews.swift:168-222` | yes |
| Text/action spacing | CafeteriaEmpty inline styles lines 133-136: 16/6/20px; 44px CTA radius 12 | Same | `CafeteriaStateViews.swift:168-222` | yes |
| Light/dark colors | `t.card`, `t.seg`, `t.faint`, `t.accentFill`, `t.link` | SettingsStyle semantic tokens | `CafeteriaStateViews.swift:168-222` | yes |

## Footnote and fade

| Property | Design value (artboard + CSS selector/inline style) | Planned value | Implemented value (file:line) | Match (yes/no) |
|---|---|---|---|---|
| Footnote spacing/inset/type | Cafeteria inline style line 142: 12px top, 4px horizontal, 12px/16px type | Same | `CafeteriaVC.swift:91-103` | yes |
| Fade | Cafeteria inline style line 146: 120px | 120pt | `CafeteriaVC.swift:114-117` | yes |
| Light/dark colors | `t.faint`, `t.fadeFrom`, `t.bg` | SettingsStyle semantic tokens | `CafeteriaVC.swift:78,91-94`; fade view | yes |

## Info sheet

| Property | Design value (artboard + CSS selector/inline style) | Planned value | Implemented value (file:line) | Match (yes/no) |
|---|---|---|---|---|
| Grabber/header | CafeteriaSheet inline styles lines 174-176: top 6px, grabber 36x5, header 10px below | Same | `CafeterianfoVC.swift:207-216` | yes |
| Map card | CafeteriaSheet inline styles lines 188-189: 148px map height, radius 16 | Same | `CafeterianfoVC.swift:44-52,228-240`; uses live MKMapView | yes |
| Section title margins | CafeteriaSheet inline style line 210: 20px top, 4px sides, 8px bottom | Same | `CafeterianfoVC.swift:257-263`: 20pt top; sides 20pt = 16pt sheet inset + 4pt (fixed by coordinator) | yes |
| Hours rows/separators | CafeteriaSheet inline style line 214 onward, script line 405: at least 44px, 1px separators | Same | `CafeterianfoVC.swift:288-318` | yes |
| Buttons | CafeteriaSheet inline styles lines 181, 203: 44px close target, 48px map action | Same | `CafeterianfoVC.swift:223-255,278-285` | yes |
| Light/dark colors | `t.sheet`, `t.card`, `t.mapBg`, `t.sep`, `t.text`, `t.sub`, `t.link` | SettingsStyle semantic tokens | `CafeterianfoVC.swift:44-52,72-133,174` | yes |

## Mismatches requiring owner fixes

None. Two mismatches found by the audit (T5 tag radius, T7 section title top margin) were fixed by the coordinator on the integration branch.

## Deviations

- Page content uses native safe-area inset adjustment around the specified content offsets, following the plan assumption for safe-area anchoring.
- The sheet uses the system page-sheet presentation and scrim behavior, following the plan assumption for system sheet scrim.
- The map preview is a live `MKMapView`, following the plan assumption for a real map view.

## Simulator verification

Pending (coordinator, Mobile-MCP): check `-cafeteriaFixture` modes in light and dark appearances.
