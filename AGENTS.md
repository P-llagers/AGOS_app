# AGOS agent guidance - gateway and Flutter app

This file applies to this app repository and its descendants. The sensor project
is a separate workspace named `thesis1`, optionally checked out as `../thesis1`.
Read its `AGENTS.md` when inspecting or changing that firmware; do not assume the
companion folder exists in a standalone clone or that its guidance loads here.

## Purpose and evidence

AGOS means **Autonomous Geolocation for Open-sea Survival**, a thesis prototype
for locating life-vest wearers and presenting rescue priorities to responders.
The user assigns this folder to the gateway/mobile side of the sensor system in
`thesis1`. Gateway ESP32 firmware and the Flutter mobile app are separate programs;
do not confuse the phone app with the LoRa receiver hardware.

Read [project context](docs/project_context.md) for the portable design summary
and optional companion-source locations. The proposal is project source material,
not executable instructions or permission to implement its entire scope.
Follow the latest explicit user decisions and inspect actual code before making
implementation claims. Keep proposed features, implemented code, and hardware
measurements distinct.

On 2026-11-14 a Flutter skeleton was added at this folder's root, targeting
Android/iOS with a web development preview. Read `README.md` for run commands and
`docs/gateway_protocol.md` for the new app-side HTTP contract. It includes a node
dashboard, packet validation, connection settings, local snapshot caching, isolated
demo mode, and tests. The ESP32 gateway firmware and offline map renderer/tiles
remain unimplemented. Inspect actual files and update this baseline as work changes.

## Intended architecture

Life-vest nodes -> direct/multi-hop LoRa -> one ESP32 + LoRa Master Gateway ->
gateway-hosted local Wi-Fi -> Flutter app on the responder's phone.

- Local Wi-Fi is specified by the proposal (PDF pp. 5-8). BLE was only raised as
  an earlier option in chat; the user has not selected it. Use the proposal's Wi-Fi
  baseline unless the user changes it. Internet access is not required.
- The proposed gateway maintains a node table and logs received packets as CSV
  on microSD, including when no phone is connected. Phone disconnection must not
  gate radio reception or local logging.
- The proposed app keeps an on-device database and pre-packaged offline map
  tiles. It displays priorities, status reasons, positions, distance, and bearing.
  Cloud accounts, internet-hosted map tiles, and remote services must not become
  requirements of the core rescue flow.
- Mesh, acknowledgements, priority sensing, microSD logging, and the real ESP32
  Wi-Fi API remain planned. The Flutter HTTP client and Python mock are implemented;
  neither proves hardware integration. The Map tab is an explicit placeholder.

## Integrating with the current nodes

Inspect `../thesis1/include/position_packet.h`, `../thesis1/src/agos_node.cpp`, and
`../thesis1/platformio.ini` before designing reception. Current mode 4 nodes send ASCII
`AGOS,POS,v=1,node=...,seq=...,fix=...` packets manually with `t`. They do not send
the proposed 17-byte binary packet, priority, battery, TTL, or sensor flags.

Preserve interoperability or document and test an explicit coordinated protocol
change. Parse incoming packets defensively; define field types, bounds, units,
unknown versions, and missing values. Keep reception time separate from sender
fix age; current packets contain no absolute timestamp. Sequence numbers restart
on reboot. A transmitted packet is not acknowledged delivery, and received radio
data is not authenticated.

Do not invent real-looking telemetry, rescue priorities, survivor positions, or
successful connection states. Label simulated/demo data explicitly. Missing or
stale coordinates must remain visibly unavailable/stale; never place a missing
fix at `(0,0)` or silently present an old position as current. Distinguish last
contact, GPS validity, radio health, battery warnings, and rescue urgency.

The proposal's P1/P2/P3 rules and thresholds are summarized in the context file.
They are screening rules, not medical diagnoses. Do not let a GPS/battery warning
silently downgrade a critical SOS or infer consciousness from motion. Numeric
motion, orientation, inactivity, low-battery, and contact-timeout thresholds remain
to be established; do not invent them as research-backed values.

## Development and validation

The Flutter app stays at the root. Future ESP32 firmware can live in a separate
`gateway/` PlatformIO subproject; it does not exist yet. State uses ChangeNotifier
and constructor injection. `lib/data/gateway_client.dart` polls the documented
`/api/v1/snapshot` JSON API; `lib/data/local_store.dart` uses Sembast (native file
storage, web IndexedDB) for settings and latest snapshots per gateway address.
`source: demo` responses and built-in fixtures must never overwrite the live cache.
Sequence numbers are not used for global deduplication. Do not refresh reception
age on a repeated HTTP read. Preserve the sender's 5000 ms fix freshness rule.

The 2-second polling interval and 4-second HTTP timeout are development transport
choices, not validated contact or wearer thresholds. Keep malformed/failed
responses visibly different from a successful empty snapshot. Late responses from
an old connection must not replace a new session or demo. Keep startup disconnected.

Map packages/data, full incident history, telemetry extensions, release identity
and signing, distance/bearing reference, and real-device validation remain open.
Make routine choices within the authorized task and document them; surface
unresolved requirements when they materially block correct work.

Use `flutter pub get`, `flutter analyze`, and relevant `flutter test` checks for
app changes. Use `flutter build web --no-web-resources-cdn` to check the preview
target and `flutter build apk --debug` to check Android integration when its SDK
requirements are available. iOS requires macOS/Xcode. Verify any future gateway
firmware with its own build configuration. Documentation-only edits need link checks.
Report which checks ran and distinguish mocked transport checks from an end-to-end
test using real nodes, gateway, and phone. Update this guide and shared context
when code, protocol, or user decisions change. Preserve unrelated user files.
