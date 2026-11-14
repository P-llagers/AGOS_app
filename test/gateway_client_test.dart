import 'dart:convert';

import 'package:agos_app/data/gateway_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> snapshot({String source = 'live'}) => {
  'schema_version': 1,
  'source': source,
  'nodes': [
    {
      'payload': 'AGOS,POS,v=1,node=A,seq=1,fix=NO_FIX,sat=NA',
      'received_ago_ms': 1200,
      'rssi_dbm': -72,
      'snr_db': 8.5,
    },
  ],
};

void main() {
  test(
    'uses the documented endpoint and preserves gateway reception age',
    () async {
      final now = DateTime.utc(2026, 11, 14);
      final client = HttpGatewayClient(
        clock: () => now,
        client: MockClient((request) async {
          expect(request.url.toString(), 'http://192.168.4.1/api/v1/snapshot');
          return http.Response(jsonEncode(snapshot()), 200);
        }),
      );
      addTearDown(client.close);
      final result = await client.fetch(Uri.parse('http://192.168.4.1'));
      expect(result.isDemo, isFalse);
      expect(
        result.nodes.single.receivedAt,
        now.subtract(const Duration(milliseconds: 1200)),
      );
      expect(result.nodes.single.rssiDbm, -72);
    },
  );

  test('requires version and explicit live/demo provenance; rejects duplicate nodes', () {
    final now = DateTime.now();
    expect(
      GatewaySnapshot.fromJson(snapshot(source: 'demo'), now).isDemo,
      isTrue,
    );
    for (final bad in [
      {...snapshot(), 'schema_version': 2},
      {...snapshot(), 'source': null},
      {
        ...snapshot(),
        'nodes': [
          {
            'payload': 'AGOS,POS,v=1,node=A,seq=1,fix=NO_FIX,sat=NA',
            'received_ago_ms': -1,
          },
        ],
      },
      {
        ...snapshot(),
        'nodes': [
          ...snapshot()['nodes'] as List,
          ...snapshot()['nodes'] as List,
        ],
      },
    ]) {
      expect(() => GatewaySnapshot.fromJson(bad, now), throwsFormatException);
    }
  });

  test(
    'HTTP failures and malformed JSON do not become empty successful feeds',
    () async {
      final failed = HttpGatewayClient(
        client: MockClient((_) async => http.Response('', 503)),
      );
      final malformed = HttpGatewayClient(
        client: MockClient((_) async => http.Response('not-json', 200)),
      );
      addTearDown(failed.close);
      addTearDown(malformed.close);
      await expectLater(
        failed.fetch(Uri.parse('http://localhost')),
        throwsA(isA<GatewayException>()),
      );
      await expectLater(
        malformed.fetch(Uri.parse('http://localhost')),
        throwsFormatException,
      );
    },
  );

  test('connection address has no credentials or endpoint path', () {
    expect(
      parseGatewayAddress(' http://127.0.0.1:8080/ ').toString(),
      'http://127.0.0.1:8080',
    );
    for (final bad in [
      '192.168.4.1',
      'ftp://localhost',
      'http://a:b@localhost',
      'http://localhost/api',
      'http://localhost?x=1',
    ]) {
      expect(() => parseGatewayAddress(bad), throwsFormatException);
    }
  });
}
