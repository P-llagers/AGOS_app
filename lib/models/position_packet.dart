enum FixState { valid, noFix, stale }

/// Current ASCII v1 firmware payload, not the proposed binary packet.
class PositionPacket {
  const PositionPacket._({
    required this.raw,
    required this.nodeId,
    required this.sequence,
    required this.fix,
    this.fixAgeMs,
    this.latitude,
    this.longitude,
    this.satellites,
  });

  static const maxFixAgeMs = 5000; // thesis1/include/position_packet.h.
  final String raw;
  final String nodeId;
  final int sequence;
  final FixState fix;
  final int? fixAgeMs;
  final double? latitude;
  final double? longitude;
  final int? satellites;

  factory PositionPacket.parse(String raw) {
    Never invalid() =>
        throw const FormatException('Invalid AGOS position packet.');
    if (raw.isEmpty ||
        raw.length > 255 ||
        raw.codeUnits.any((c) => c < 32 || c > 126)) {
      invalid();
    }
    final parts = raw.split(',');
    if (parts.length < 3 || parts[0] != 'AGOS' || parts[1] != 'POS') invalid();
    final fields = <String, String>{};
    for (final part in parts.skip(2)) {
      final pair = part.split('=');
      if (pair.length != 2 || pair[1].isEmpty || fields.containsKey(pair[0])) {
        invalid();
      }
      fields[pair[0]] = pair[1];
    }
    if (fields['v'] != '1') {
      throw const FormatException('Unsupported AGOS packet version.');
    }
    final node = fields['node'];
    if (node == null || !RegExp(r'^[A-Za-z0-9_-]$').hasMatch(node)) invalid();
    final sequence = _uint32(fields['seq']);
    final fix = switch (fields['fix']) {
      'VALID' => FixState.valid,
      'NO_FIX' => FixState.noFix,
      'STALE' => FixState.stale,
      _ => invalid(),
    };
    final sat = fields['sat'];
    if (sat == null) invalid();
    final satellites = sat == 'NA' ? null : _uint32(sat);
    final expected = {'v', 'node', 'seq', 'fix', 'sat'};
    int? age;
    double? lat;
    double? lon;
    if (fix == FixState.valid) {
      expected.addAll({'age_ms', 'lat', 'lon'});
      age = _uint32(fields['age_ms']);
      lat = double.tryParse(fields['lat'] ?? '');
      lon = double.tryParse(fields['lon'] ?? '');
      if (age > maxFixAgeMs ||
          lat == null ||
          lon == null ||
          !lat.isFinite ||
          !lon.isFinite ||
          lat.abs() > 90 ||
          lon.abs() > 180) {
        invalid();
      }
    }
    if (fields.length != expected.length ||
        !fields.keys.every(expected.contains)) {
      invalid();
    }
    return PositionPacket._(
      raw: raw,
      nodeId: node,
      sequence: sequence,
      fix: fix,
      fixAgeMs: age,
      latitude: lat,
      longitude: lon,
      satellites: satellites,
    );
  }

  static int _uint32(String? value) {
    if (value == null || !RegExp(r'^\d+$').hasMatch(value)) {
      throw const FormatException('Expected an unsigned integer.');
    }
    final result = int.tryParse(value);
    if (result == null || result > 0xffffffff) {
      throw const FormatException('Integer exceeds the packet range.');
    }
    return result;
  }
}
