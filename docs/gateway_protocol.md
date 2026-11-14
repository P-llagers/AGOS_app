# App-side gateway snapshot contract, version 1

Introduced with the Flutter skeleton on 2026-11-14. This is a new app-side
implementation choice, **not an existing ESP32 endpoint or a format specified by
the proposal**. The sensor LoRa wire format is unchanged.

## Transport

The phone joins the gateway's Wi-Fi manually. A configured base address
(initial suggestion `http://192.168.4.1`) serves:

```http
GET /api/v1/snapshot
Accept: application/json
Cache-Control: no-cache
```

Return HTTP 200, UTF-8 JSON, and `Cache-Control: no-store`. The app polls every
2 seconds during a connection session, permits one in-flight request per session,
and reports an error after a 4-second timeout. These are development transport
choices, not validated sensing or contact thresholds.

For browser development provide CORS for the preview origin, `GET`/`OPTIONS`, and
the headers above. The mock enables development origins. A real gateway's CORS
policy is a separate decision; native phones do not depend on browser CORS.
Browser local-network permission prompts may require user action.

## Response

This example is synthetic:

```json
{
  "schema_version": 1,
  "source": "demo",
  "nodes": [
    {
      "payload": "AGOS,POS,v=1,node=A,seq=1,fix=VALID,age_ms=200,lat=14.599500,lon=120.984200,sat=8",
      "received_ago_ms": 1200,
      "rssi_dbm": -72,
      "snr_db": 8.5
    },
    {
      "payload": "AGOS,POS,v=1,node=B,seq=1,fix=NO_FIX,sat=NA",
      "received_ago_ms": 3000,
      "rssi_dbm": -89,
      "snr_db": 3.2
    }
  ]
}
```

- `schema_version`: numeric `1`; other versions are rejected.
- `source`: required `live` for actual LoRa data or `demo` for simulated data.
  Demo responses are labeled and never written to the live cache. This is the
  gateway's declaration, not cryptographic authentication.
- `nodes`: complete latest-record table, at most 1024 records, one per node ID.
  Empty `[]` means a successful empty snapshot, not a connection error. Responses
  above 256 KiB are rejected.
- `payload`: original ASCII position packet with no console prefix or newline.
  Do not include diagnostic `AGOS,TEST` packets as positions.
- `received_ago_ms`: required integer in 0..4294967295, measuring elapsed time
  since the gateway **received that packet**. Do not reset this age when a phone
  fetches a snapshot. Remove expired records instead of wrapping age to zero.
- `rssi_dbm`: optional integer/null for that packet's reception.
- `snr_db`: optional finite number/null for the same reception.

Malformed records and duplicate node IDs reject the response rather than silently
erasing the previous snapshot. Additional top-level metadata is allowed; changing
required fields or semantics needs a version change.

The app estimates reception time as phone response time minus `received_ago_ms`.
This does not synchronize clocks, and network delay/LoRa airtime are not fully
captured. Accurate timing and history need a future clock contract and measurement.

## Existing LoRa packet

Inspect `../../thesis1/include/position_packet.h` and
`../../thesis1/src/agos_node.cpp` before changing this parser.

- Header `AGOS,POS`; `v=1`; a single-character alphanumeric, `_`, or `-` node ID;
  unsigned 32-bit `seq`; `fix=VALID|NO_FIX|STALE`; `sat` unsigned 32-bit or `NA`.
  Duplicate and unknown v1 payload fields are rejected.
- `VALID` needs `age_ms` in 0..5000 and finite `lat` (-90..90), `lon` (-180..180).
  A genuinely valid `(0,0)` is accepted. Firmware checks current RMC status;
  the app cannot independently verify that claim from the packet.
- `NO_FIX`/`STALE` omit `lat`, `lon`, and `age_ms`. Never insert zero coordinates.
- Maximum 255 ASCII bytes, without whitespace/newline framing.
- Sequence numbers restart on reboot. Do not reject all rebooted-node packets
  using a globally increasing-sequence assumption. No history deduplication exists.
- Priority, battery, SOS, immersion, and TTL fields are not currently transmitted.

The app withholds current coordinates once fix age plus time since gateway
reception exceeds 5000 ms. Raw packets remain inspectable with context. A phone
clock moving behind the estimated reception time also withholds the fix. No wearer
is classified critical or safe from missing GPS or missing packets.

## Cache and disconnection

Only successful `live` responses replace that gateway address's saved snapshot.
An error retains the previous readings while GPS freshness continues to expire.
Switching addresses loads a separate cache. Demo mode never overwrites it. No
gateway is contacted automatically at startup.

This API does not implement LoRa ACKs, retries, mesh, or authentication. HTTP
success establishes that an endpoint answered, not radio delivery or wearer health.
