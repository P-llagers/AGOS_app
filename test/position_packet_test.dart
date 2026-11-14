import 'package:agos_app/models/node_observation.dart';
import 'package:agos_app/models/position_packet.dart';
import 'package:flutter_test/flutter_test.dart';

const validPacket =
    'AGOS,POS,v=1,node=A,seq=4294967295,fix=VALID,age_ms=200,lat=0.000000,lon=0.000000,sat=8';

void main() {
  test('reads current firmware format and accepts a valid zero coordinate', () {
    final packet = PositionPacket.parse(validPacket);
    expect(packet.nodeId, 'A');
    expect(packet.sequence, 0xffffffff);
    expect(packet.latitude, 0);
    expect(packet.longitude, 0);
    expect(packet.fixAgeMs, 200);
    expect(packet.satellites, 8);
  });

  test(
    'missing/stale fixes have no position and allow unavailable satellites',
    () {
      for (final fix in ['NO_FIX', 'STALE']) {
        final packet = PositionPacket.parse(
          'AGOS,POS,v=1,node=B,seq=0,fix=$fix,sat=NA',
        );
        expect(packet.latitude, isNull);
        expect(packet.longitude, isNull);
        expect(packet.satellites, isNull);
        expect(
          () => PositionPacket.parse('${packet.raw},lat=14,lon=120'),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'rejects malformed, conflicting, unsupported or out-of-range payloads',
    () {
      for (final raw in [
        validPacket.replaceFirst('v=1', 'v=2'),
        '$validPacket,node=B',
        '$validPacket,battery=90',
        validPacket.replaceFirst('lat=0.000000', 'lat=91'),
        validPacket.replaceFirst('lon=0.000000', 'lon=NaN'),
        validPacket.replaceFirst('seq=4294967295', 'seq=4294967296'),
        validPacket.replaceFirst('age_ms=200', 'age_ms=5001'),
        validPacket.replaceFirst('seq=4294967295', 'seq=-1'),
        '$validPacket\n',
        'AGOS,TEST,node=A,seq=1',
        List.filled(256, 'a').join(),
      ]) {
        expect(
          () => PositionPacket.parse(raw),
          throwsFormatException,
          reason: raw,
        );
      }
    },
  );

  test(
    'ages a valid fix without silently presenting old coordinates as current',
    () {
      final received = DateTime.utc(2026, 11, 14);
      final node = NodeObservation(
        packet: PositionPacket.parse(validPacket),
        receivedAt: received,
      );
      expect(
        node.hasCurrentFix(received.add(const Duration(milliseconds: 4800))),
        isTrue,
      );
      expect(
        node.hasCurrentFix(received.add(const Duration(milliseconds: 4801))),
        isFalse,
      );
      expect(
        node.hasCurrentFix(received.subtract(const Duration(seconds: 1))),
        isFalse,
      );
      expect(
        node.fixLabel(received.add(const Duration(seconds: 6))),
        'GPS fix expired',
      );
    },
  );
}
