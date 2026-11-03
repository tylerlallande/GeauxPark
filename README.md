# GeauxPark
[![Build](https://github.com/tylerlallande/GeauxPark/actions/workflows/build.yml/badge.svg)](https://github.com/tylerlallande/GeauxPark/actions/workflows/build.yml)

**Task Board:** https://github.com/users/BrandonAvila76/projects/1 (milestones: MVP Nov 6, Final Nov 20)

Help students and football fans find parking before arriving at busy locations.


#  Geaux Park

**Geaux Park** is an Android app built with Flutter that helps users discover nearby parking locations quickly and conveniently. The goal is to make parking easier by providing a simple, user-friendly interface where users can explore parking options and find locations that fit their needs.

## Features

- **Parking Search:** Find parking locations in your desired area.
- **Interactive Map:** Explore parking locations visually.
- **Location Details:** View information about available parking options.
- **Saved Parking:** Tap a lot's bookmark to save it, then open the Saved tab to find or remove it. Saved lots stay on the current device or browser after restarting the app.
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

Start the Flutter web server on the Mac:

```bash
flutter run -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 8080 \
  -t lib/main.dart
```

Find the Mac's Wi-Fi address:

```bash
ipconfig getifaddr en0
```

With the phone connected to the same Wi-Fi network, open
`http://<mac-ip-address>:8080` in its browser. Keep the terminal running while
using the preview. If macOS asks whether to allow incoming connections, allow
them for Flutter/Dart.

## Future Improvements

- Integrate live parking availability.
- Add parking filters and search preferences.
- Provide directions to selected parking locations.
- Include parking prices and operating hours when available.
- Add user accounts and saved parking locations.

## Project Status

Geaux Park is currently in development. Features and technologies may change as the project evolves.

## License

A license will be added as the project develops.

---

**Geaux Park — Making parking easier, one spot at a time.** 💗
