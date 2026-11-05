# GeauxPark
[![Android CI](https://github.com/tylerlallande/GeauxPark/actions/workflows/main.yml/badge.svg)](https://github.com/tylerlallande/GeauxPark/actions/workflows/main.yml)

**Task Board:** https://github.com/users/BrandonAvila76/projects/1 (milestones: MVP Nov 6, Final Nov 20)

Help students and football fans find parking before arriving at busy locations.


#  Geaux Park

**Geaux Park** is an Android app built with Flutter that helps users discover nearby parking locations quickly and conveniently. The goal is to make parking easier by providing a simple, user-friendly interface where users can explore parking options and find locations that fit their needs.

## Features

- **Parking Search:** Find parking locations in your desired area.
- **Interactive Map:** Explore parking locations visually.
- **Directions:** Open a lot and tap Get directions to see a road route and turn-by-turn driving steps in the built-in map. GeauxPark asks for your location and confirms before sending your start and destination coordinates to the public OSRM routing server. The Map tab can also calculate a route for its selected lot.
- **Location Details:** View information about available parking options.
- **Saved Parking:** Tap a lot's bookmark to save it, then open the Saved tab to find or remove it. Saved lots stay on the current device or browser after restarting the app.
- **Campus Lots:** Browse 18 parking locations, including 15 additional lots verified against LSU's campus map. Newly imported lots show unknown availability rather than simulated space counts. See [location sources](docs/parking_locations.md).
- **Lot Tags & Filters:** Filter Home results by Visitor, Commuter, Residential, Greek housing, Law, Park & Geaux, Garage, or Event. Select any matching lot types and combine quick filters (such as Available now and Accessible). Search matches tag names, and Clear resets search and filters. Tags also appear in Saved, details, and the map's selected-lot card.
- **Permit Eligibility:** Select LSU parking permits in the Profile tab to highlight eligible lots and dim restricted lots across the app.
- **User-Friendly Interface:** Navigate the app with a clean, modern design.
- **Responsive Design:** Designed with usability across different screen sizes in mind.

##  Project Goals

The goal of Geaux Park is to simplify the parking experience by making it easier for users to locate parking options in one convenient place. This project also provides an opportunity to apply software development, web design, and database management concepts to a real-world problem.

## Technologies

- App: Flutter (Dart), Android
- Builds: GitHub Actions

### Team

- Frontend: Tyler Lallande
- Backend: Abdul Muttal 
- Database: David Zhong 
- Version Control: Brandon Avila
- UI/UX Designer: Genesis Revelation

## Download

Install the latest Android build from [Releases](https://github.com/tylerlallande/GeauxPark/releases): download the `.apk` on your phone and open it (allow "Install unknown apps" if Android asks).

### Making a release (Version Control)

Releases are automated. Tag a commit on `main` with a version and push the tag:

```bash
git switch main
git pull --ff-only origin main
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions analyzes, tests, and builds the APK (version name set from the tag), then publishes a GitHub Release named after the tag with the APK attached and release notes generated from the merged pull requests.

##  Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio or the Android SDK, plus an Android phone or emulator

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/tylerlallande/GeauxPark.git
   ```

2. Navigate to the project directory:

   ```bash
   cd GeauxPark
   ```

3. Install dependencies and run the app:

   ```bash
   flutter pub get
   flutter run
   ```

4. Before opening a pull request, run `flutter analyze` and `flutter test`. See [CONTRIBUTING.md](CONTRIBUTING.md) for the branch and review workflow.

### Run the parking API

The repository includes a dependency-free Dart API for the lot list and lot
details screens. From the repository root, run:

```bash
dart run server/bin/server.dart
```

The server listens on `http://localhost:8080` by default. Set `PORT` or
`GEAUXPARK_HOST` to change the bind settings. Available endpoints:

```text
GET /lots
GET /lots?gameDay=true&permitType=student
GET /lots/{id}
```

`/parking-lots/{id}` is also supported for compatibility with the original
details API contract. The source data is in [`server/data/lots.json`](server/data/lots.json).

### Run on macOS

```bash
flutter run -d macos -t lib/main.dart
```

### Preview on a phone over local Wi-Fi

Connect the Mac and phone to the same Wi-Fi network, then run:

```bash
./tool/run_lan_demo.sh
```

The launcher prints the exact URL to open on the phone and serves an optimized
release build on port `8081` by default. Keep the terminal open while using the
demo, and press Ctrl+C to stop it. To choose another port, pass it as the first
argument:

```bash
./tool/run_lan_demo.sh 9000
```

For development with hot reload, use debug mode. Debug builds are expected to
feel slower and should not be used to judge phone-demo performance:

```bash
./tool/run_lan_demo.sh --debug
```

If macOS asks whether to allow incoming connections, allow them for
Flutter/Dart. A VPN, guest Wi-Fi client isolation, or the macOS firewall can
prevent the phone from reaching the Mac even when both devices show the same
network name.

To launch the demo manually instead, run:

```bash
flutter run -d web-server \
  --release \
  --web-hostname 0.0.0.0 \
  --web-port 8081 \
  -t lib/main.dart
```

Find the Mac's Wi-Fi address:

```bash
ipconfig getifaddr en0
```

With the phone connected to the same Wi-Fi network, open
`http://<mac-ip-address>:8081` in its browser. The app, local sample parking
data, map, filters, permit preferences, saved lots, and details are available
in this demo. Mobile browsers can restrict precise location on plain HTTP LAN
addresses; if that happens, location-dependent directions show the app's retry
state while the remaining workflow stays available.

## Future Improvements

- Integrate live parking availability.
- Add parking filters and search preferences.
- Add walking directions and offline route support.
- Include parking prices and operating hours when available.
- Add user accounts and saved parking locations.

## Project Status

Geaux Park is currently in development. Features and technologies may change as the project evolves.

## License

A license will be added as the project develops.

---

**Geaux Park — Making parking easier, one spot at a time.** 💗
