# Student parking readiness plan

## Intended journey

The primary workflow is intentionally short:

1. Open GeauxPark and select the LSU permits available to you.
2. Review the best eligible lot, ranked by availability and distance.
3. Confirm the lot's data source, restrictions, price, and last update.
4. Open directions and travel to the selected lot.
5. Report changed availability so the next student receives fresher guidance.

Search, the full map, filters, saved lots, and game-day information remain
available without interrupting that path.

## Delivered in the app

- Permit-aware eligibility throughout Home, Map, Saved, and details.
- A ranked Best Match card instead of requiring students to compare every lot.
- User reports override older bundled availability when recommendations rank.
- Live and offline-reference modes remain visible and update reactively.
- Search, filters, saved lots, directions, safe failures, and mobile tab swipes.
- Secure production API and map configuration with explicit LAN-demo exceptions.
- Strict static analysis, unit/widget/integration tests, and an 80% CI coverage gate.

## Required before public launch

These items require infrastructure or vendor decisions and must not be faked in
the client:

- Deploy the GeauxPark API behind HTTPS and set the GitHub secret
  `GEAUXPARK_API_URL`.
- Contract an approved production map-tile provider and set
  `GEAUXPARK_MAP_TILE_URL`.
- Obtain an authorized LSU or parking-operator availability feed. Until then,
  availability must remain labeled as unknown or user-reported.
- Connect `AppErrorReporter` to an approved privacy-conscious crash service.
- Validate the release APK on at least one low-end and one current Android phone,
  including denied location, poor network, large text, and outdoor visibility.
- Publish a privacy notice describing location use, user reports, and external
  routing services.

## Release gate

A public release is ready only when:

- `flutter analyze` and the full test suite pass;
- the production API and map secrets are configured;
- the app displays live data without falling back during the smoke test;
- permit selection, recommendation, lot details, and directions pass on-device;
- offline-reference mode is unmistakable when the live service is unavailable;
- crash reporting and the privacy notice have been approved.
