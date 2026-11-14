import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/node_observation.dart';
import '../models/position_packet.dart';

class GatewaySnapshot {
  const GatewaySnapshot({required this.nodes, required this.isDemo});
  final List<NodeObservation> nodes;
  final bool isDemo;

  factory GatewaySnapshot.fromJson(Object? value, DateTime now) {
    if (value is! Map<String, dynamic> ||
        value['schema_version'] != 1 ||
        !{'live', 'demo'}.contains(value['source']) ||
        value['nodes'] is! List) {
      throw const FormatException('Unsupported gateway snapshot.');
    }
    final records = value['nodes'] as List;
    if (records.length > 1024) {
      throw const FormatException('Too many node records.');
    }
    final ids = <String>{};
    final nodes = <NodeObservation>[];
    for (final record in records) {
      if (record is! Map<String, dynamic> || record['payload'] is! String) {
        throw const FormatException('Invalid node record.');
      }
      final age = record['received_ago_ms'];
      final rssi = record['rssi_dbm'];
      final snr = record['snr_db'];
      if (age is! int ||
          age < 0 ||
          age > 0xffffffff ||
          (rssi != null && rssi is! int) ||
          (snr != null && (snr is! num || !snr.isFinite))) {
        throw const FormatException('Invalid reception metadata.');
      }
      final packet = PositionPacket.parse(record['payload'] as String);
      if (!ids.add(packet.nodeId)) {
        throw const FormatException('Duplicate node ID.');
      }
      nodes.add(
        NodeObservation(
          packet: packet,
          receivedAt: now.subtract(Duration(milliseconds: age)),
          rssiDbm: rssi as int?,
          snrDb: (snr as num?)?.toDouble(),
        ),
      );
    }
    return GatewaySnapshot(
      nodes: List.unmodifiable(nodes),
      isDemo: value['source'] == 'demo',
    );
  }
}

abstract interface class GatewayClient {
  Future<GatewaySnapshot> fetch(Uri baseUrl);
  void close();
}

class HttpGatewayClient implements GatewayClient {
  HttpGatewayClient({http.Client? client, DateTime Function()? clock})
    : _client = client ?? http.Client(),
      _clock = clock ?? DateTime.now;
  final http.Client _client;
  final DateTime Function() _clock;

  @override
  Future<GatewaySnapshot> fetch(Uri baseUrl) async {
    final response = await _client
        .get(
          baseUrl.resolve('/api/v1/snapshot'),
          headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
        )
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw GatewayException('Gateway returned HTTP ${response.statusCode}.');
    }
    if (response.bodyBytes.length > 262144) {
      throw const FormatException('Gateway snapshot exceeds 256 KiB.');
    }
    return GatewaySnapshot.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)),
      _clock(),
    );
  }

  @override
  void close() => _client.close();
}

class GatewayException implements Exception {
  const GatewayException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Base address only: no credentials, query, fragment, or API path.
Uri parseGatewayAddress(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme) ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      uri.port < 1 ||
      uri.port > 65535) {
    throw const FormatException(
      'Enter a base address, for example http://192.168.4.1',
    );
  }
  return uri.replace(path: '');
}
