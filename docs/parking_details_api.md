# Parking details API contract

The app reads parking detail data through `ParkingRepository`. The current
`DemoParkingRepository` is temporary and can be replaced by an HTTP-backed
implementation without changing the screens.

## Endpoint

```text
GET /lots/{lotId}

`GET /parking-lots/{lotId}` remains available as a compatibility alias.
```

Successful response:

```json
{
  "lotId": "union-square-garage",
  "description": "Covered parking near the Student Union.",
  "hours": "Open daily, 6:00 AM–11:00 PM",
  "eventRestrictions": "Event pricing may apply on game days.",
  "amenities": ["Covered parking", "Accessible spaces", "Well lit"],
  "latitude": 30.4121,
  "longitude": -91.1773,
  "availabilityUpdatedAt": "2026-11-01T18:30:00Z"
}
```

## Field behavior

- `lotId` is required and must match the summary parking record.
- All other fields may be absent or `null`; the UI displays a safe fallback.
- `amenities` defaults to an empty list.
- `latitude` and `longitude` must both be present to enable directions.
- `availabilityUpdatedAt` should be an ISO-8601 UTC timestamp.
- A missing lot should return HTTP `404`; repository implementations translate
  that response to `null`.
- Network and server failures should throw `ParkingRepositoryException` so the
  UI presents its retry state.

## Lot list endpoint

```text
GET /lots
GET /lots?gameDay=true&permitType=student
```

The response is an object containing a `lots` array. `gameDay` accepts only
`true` or `false`; `permitType` is matched case-insensitively. A malformed
`gameDay` value returns `400`, and an unknown route returns `404`.

## Connecting a server

1. Run `dart run server/bin/server.dart` from the repository root.
2. Fetch and decode the endpoint response.
3. Construct the model with `ParkingDetails.fromJson`.
4. Inject the API repository into `AppShell(parkingRepository: repository)`.
5. Provide a directions callback after selecting a maps provider.

No parking-detail screen changes should be required.
