# AGOS responder app

Flutter skeleton for **Autonomous Geolocation for Open-sea Survival**. Android and
iOS are the mobile targets; web is a development preview. The Flutter project is
directly at this repository's root (locally `C:\agos_app`). Sensor firmware belongs
to the separate `thesis1` project; it is optional for running this app or its demo.

## What works

- 1-second splash screen followed by the dark maritime `MAP` landing screen with
  `MAP`, `NODES`, `ALERTS`, and `SETTINGS` navigation; no account or cloud service.
- Bundled offline zoomable map of Cebu, Philippines (`assets/map_tiles/`, zooms
  7–13 with seamless overzoom to 15.5, coordinate graticule, and live node markers
  for current GPS fixes) and bundled offline Barlow typography (`assets/fonts/`).
- Parsing of existing `AGOS,POS,v=1,...` sensor packets, GPS freshness, reception
  age, RSSI/SNR, and raw packet inspection.
- Opt-in demo mode; simulated readings never enter the live cache.
- Configurable gateway URL, connect/disconnect, polling, timeout/error states.
- Persistent settings and latest readings in a local Sembast database,
  partitioned by gateway address and available after restart.
- A Python mock gateway and unit/widget tests.

**Integration boundary:** The HTTP API is a new app-side contract documented in
[docs/gateway_protocol.md](docs/gateway_protocol.md). The ESP32 gateway does not
implement it yet. The app does not receive LoRa directly or join Wi-Fi automatically.
Distance, bearing, and responder phone GPS are not implemented yet. Priority and
battery values are unavailable in current packets. Mesh, ACKs, microSD logging,
and wearer sensing remain firmware work.

## First run

Created with Flutter **3.47.6 stable**, Dart **3.13.5**, and Java 21 from Android
Studio. Use the installed SDK; this PC's Flutter folder name contains `3.35.3`,
but `flutter --version` reports the actual version. Keep `pubspec.lock` with the app.

For a fresh checkout:

```powershell
git clone https://github.com/P-llagers/AGOS_app.git
cd AGOS_app
flutter pub get
flutter devices
flutter run -d <device-id>
```

Replace `<device-id>` with your attached Android phone or emulator ID. Without a
phone, preview in Chrome:

```powershell
flutter run -d chrome --web-port 7357
```

The app starts disconnected, with no invented survivors. **Explore demo** loads
simulated readings. Its static example fix expires after five seconds; reload
the demo to see a current example again.

`flutter doctor -v` reported pending Android SDK licenses on this PC. Review and
accept any required licenses interactively if Android tooling requests them:

```powershell
flutter doctor --android-licenses
flutter build apk --debug
```

iOS builds require macOS/Xcode and signing configuration. Windows desktop is not
generated; use Chrome for a preview on Windows.

## Try the data path without hardware

Run the Python standard-library mock from the repository root in a separate terminal:

```powershell
python tools/mock_gateway.py
```

In the web preview, open **Gateway**, enter `http://127.0.0.1:8080`, and connect.
Every mock response declares `source: demo`; the demo banner stays visible. This
checks the HTTP path, not LoRa or ESP32 hardware. Stop the mock with Ctrl+C.

To validate one HTTP response from a terminal, run
`dart run tools/check_gateway.dart http://127.0.0.1:8080` while the mock is running.

For the Android emulator use `http://10.0.2.2:8080` and bind the mock to an
interface reachable by the emulator if needed. For a physical phone, put the PC
and phone on the same network, run `python tools/mock_gateway.py --host 0.0.0.0`,
and use the PC's LAN address. The PC may ask you to allow the development connection.

For real hardware, join the gateway Wi-Fi in the phone's system settings. The
initial address `http://192.168.4.1` is a proposed default, not a discovered or
already configured ESP32 address. Implement the snapshot endpoint first.
Android allows HTTP for this local gateway prototype. iOS declares local-network
access and HTTP exceptions for `192.168.4.1` and `127.0.0.1`; update the IP
exceptions if your gateway address changes. Phone OS behavior needs device testing.

## Layout and data flow

```text
lib/
  main.dart                    Storage bootstrap and startup error handling
  app.dart                     Theme, navigation, data provenance banners
  models/                      Position packet and reception data
  data/
    gateway_client.dart        HTTP and snapshot validation
    local_store.dart           Settings and latest-reading database
    demo_data.dart             Explicit simulated fixtures
  features/
    monitor/                   Session controller and node dashboard
    gateway/                   Connection form
    map/                       Offline-map placeholder
  ui/                          Shared colors
test/                          Packet, HTTP, persistence, controller, layout tests
tools/mock_gateway.py          Simulated gateway; no Python packages needed
docs/gateway_protocol.md       ESP32 HTTP contract to implement
android/, ios/, web/           Platform projects
```

State uses built-in `ChangeNotifier` and constructor injection. Widgets display
state, the controller manages the session, the client handles transport and
validation, and the store handles persistence.

The database stores latest snapshots, not every radio packet or an incident log.
Native data lives in the application's support directory; web uses IndexedDB
tied to the browser origin/port. Demo data is session-only. No telemetry goes to
a cloud service. The app does not auto-connect on launch or poll while closed;
the gateway must receive/log independently. Background behavior needs device tests.

## Checks

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
flutter build apk --debug
```

The web build can bundle its renderer; that does not mean an offline browser app
has been installed. Native mobile is the primary offline target. Tests use mock
transport and temporary databases; passing them does not verify the ESP32 or LoRa.

Skeleton checks on 2026-11-14: analysis passed, all 15 tests passed, Android debug
and release web builds passed, the Dart client accepted three explicitly simulated
nodes from the Python HTTP mock, and rendered 390 x 844 phone screens were visually
checked. The APK is `build/app/outputs/flutter-apk/app-debug.apk`; the first Android
build downloaded Gradle/dependencies and took about 18 minutes. No physical phone
or ESP32 integration was verified. Doctor's additional pending SDK licenses did
not prevent this Android debug build.

The app ID `org.agos.agos_app`, launcher icons, and generated debug signing for
release builds are development placeholders. Configure identity, icons, and
release signing before distribution.

## Next integration work

1. Add a separate PlatformIO project in a future `gateway/` folder with matching
   LoRa settings, a node table, and the snapshot API.
2. Test the phone -> Wi-Fi -> gateway -> LoRa -> node path with actual hardware.
3. Add gateway microSD logs and history sync beyond the latest snapshot cache.
4. Specify/version priority and battery telemetry without inventing missing values.
5. Choose licensed offline map data/renderer and a reference for distance/bearing.

Read [AGENTS.md](AGENTS.md) and the
[project context](docs/project_context.md) before extending.
References: [Flutter architecture](https://docs.flutter.dev/app-architecture),
[HTTP](https://pub.dev/packages/http), [Sembast](https://pub.dev/packages/sembast),
[web database](https://pub.dev/packages/sembast_web).
