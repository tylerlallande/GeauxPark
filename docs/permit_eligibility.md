# Parking permit eligibility

GeauxPark stores the user's selected permit types locally and compares them
with each parking lot's `permitTypes`. The identifiers are shared by the
Flutter model and the parking API.

## LSU sources

- Student permit types: <https://www.lsu.edu/parking/permit/student.php>
- Faculty/staff permits: <https://www.lsu.edu/parking/permit/employee.php>
- Campus parking hours: <https://www.lsu.edu/parking/campus-parking-hours.php>
- Parking rules and zones: <https://www.lsu.edu/parking/rules-regulations.php>

LSU generally enforces zone parking from 7:00 a.m. to 4:30 p.m. Monday through
Friday. Permits are still required on weekdays outside those zone hours, and
event rules can override normal access. Posted signs and current LSU Parking &
Transportation rules are always authoritative.

## UI behavior

- No selected permit: all lots remain visible with no eligibility claim.
- Matching permit: the lot is labeled as eligible.
- No matching permit: the lot remains selectable but is dimmed and marked as
  restricted.
- The Home screen's **My permits** filter shows only matching lots.

## Server contract

Each parking record includes a `permitTypes` array containing stable IDs such
as `commuter`, `nicholson-gateway-resident`, `employee-b`, or `visitor`.
`GET /lots?permitType=<id>` uses the same identifiers.

The current three lot assignments are demonstration data and must be verified
against LSU's official lot-access map before production use.
