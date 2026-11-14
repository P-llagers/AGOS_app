import '../models/node_observation.dart';
import '../models/position_packet.dart';

/// Synthetic fixtures, never written to the live cache.
List<NodeObservation> demoNodes(DateTime now) => [
  NodeObservation(
    packet: PositionPacket.parse(
      'AGOS,POS,v=1,node=A,seq=1,fix=VALID,age_ms=200,lat=14.599500,lon=120.984200,sat=8',
    ),
    receivedAt: now,
    rssiDbm: -72,
    snrDb: 8.5,
  ),
  NodeObservation(
    packet: PositionPacket.parse('AGOS,POS,v=1,node=B,seq=1,fix=NO_FIX,sat=NA'),
    receivedAt: now.subtract(const Duration(seconds: 12)),
    rssiDbm: -89,
    snrDb: 3.2,
  ),
  NodeObservation(
    packet: PositionPacket.parse('AGOS,POS,v=1,node=C,seq=1,fix=STALE,sat=4'),
    receivedAt: now.subtract(const Duration(minutes: 2)),
    rssiDbm: -101,
    snrDb: -1.5,
  ),
];
