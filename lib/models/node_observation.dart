import 'position_packet.dart';

class NodeObservation {
  const NodeObservation({
    required this.packet,
    required this.receivedAt,
    this.rssiDbm,
    this.snrDb,
  });

  final PositionPacket packet;

  /// Approximate gateway reception time, estimated from received_ago_ms.
  final DateTime receivedAt;
  final int? rssiDbm;
  final double? snrDb;

  Duration ageAt(DateTime now) {
    final age = now.difference(receivedAt);
    return age.isNegative ? Duration.zero : age;
  }

  bool hasCurrentFix(DateTime now) =>
      !now.isBefore(receivedAt) &&
      packet.fix == FixState.valid &&
      (packet.fixAgeMs! + ageAt(now).inMilliseconds) <=
          PositionPacket.maxFixAgeMs;

  String fixLabel(DateTime now) => switch (packet.fix) {
    FixState.noFix => 'No GPS fix',
    FixState.stale => 'Stale GPS fix',
    FixState.valid =>
      hasCurrentFix(now) ? 'Current GPS fix' : 'GPS fix expired',
  };

  Map<String, Object?> toStoredJson() => {
    'payload': packet.raw,
    'received_at': receivedAt.toUtc().toIso8601String(),
    'rssi_dbm': rssiDbm,
    'snr_db': snrDb,
  };

  factory NodeObservation.fromStoredJson(Map<String, Object?> json) =>
      NodeObservation(
        packet: PositionPacket.parse(json['payload'] as String),
        receivedAt: DateTime.parse(json['received_at'] as String),
        rssiDbm: json['rssi_dbm'] as int?,
        snrDb: (json['snr_db'] as num?)?.toDouble(),
      );
}
