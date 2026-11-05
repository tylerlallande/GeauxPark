# Parking coordinates

The app's map and demo details share `lib/data/parking_locations.dart`.
The API fixture in `server/data/lots.json` uses the same coordinates; a
regression test checks that these stay in sync.

Verified against [LSU's interactive campus map](https://map.concept3d.com/?id=743)
on November 3, 2026:

| App lot | LSU map location | Latitude | Longitude |
| --- | --- | --- | --- |
| Union Square Garage | [Union Square Bookstore & Parking Garage](https://map.concept3d.com/?id=743#!m/360623) | 30.413082 | -91.174782 |
| West Stadium Lot | [West Stadium Lot (101)](https://map.concept3d.com/?id=743#!m/359719) | 30.411709 | -91.185799 |
| Nicholson Gateway | [Nicholson Gateway Garage](https://map.concept3d.com/?id=743#!m/759345) | 30.413839 | -91.188286 |

Nicholson Gateway represents the parking garage, rather than the apartment
complex's center. These are map locations, not surveyed entrance coordinates.

## Additional campus lots

`lib/data/campus_parking_locations.dart` adds 15 parking entries from LSU's
Parking & Transportation map categories. It is shared by the app's lot list,
marker locations, and demo details. Each entry retains its official map location
ID; open `https://map.concept3d.com/?id=743#!m/LOCATION_ID` to view the source.

| Lot | Location ID | Map category |
| --- | --- | --- |
| Visitor Parking (Welcome Center) | 344811 | Visitor, pay to park |
| South Stadium Visitor Parking | 344813 | Visitor, pay to park |
| Thomas Boyd Visitor Parking Lot | 344814 | Visitor, pay to park |
| Touchdown Village Visitor Parking | 355166 | Visitor, pay to park |
| Parker Coliseum Visitor Parking | 355167 | Visitor, pay to park |
| South Quad West Lot (403) | 359712 | Commuter, Zone 1 |
| Skip Bertman Drive East Lot (404) | 359713 | Commuter, Zone 1 |
| Bernie Moore Lot (104) | 359721 | Commuter, Zone 1 |
| Natatorium Lot (105) | 359723 | Commuter, Zone 1 |
| South Law Lot | 352663 | Law, Zone 4 |
| Fraternity Lane East (Lot 500b) | 352538 | Greek Residential, Zone 2 |
| Greek Row North Lot | 352642 | Greek Residential, Zone 2 |
| Park & Geaux Lot (Tiger Park East) | 1077259 | Park & Geaux |
| Skip Bertman West (Lot 412) | 1077260 | Park & Geaux |
| UREC North Lot | 1077355 | Park & Geaux |

The source does not report live space counts, exact rates, operating hours, or
lot-specific accessible-space availability for these imports. Availability and
accessibility use null, prices describe only pay-to-park or permit access, and
hours remain unspecified. Unknown availability is excluded from Available now;
unknown accessibility is excluded from Accessible. Distances are approximate
straight-line miles to the Student Union (source location 500347), labeled
"to Union"; they are not walking-route distances. Permit tags reflect the
source's primary category, not a complete authorization policy for every permit.

The original three demo lots retain their existing sample availability and rates.
