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
