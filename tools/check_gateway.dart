import 'dart:io';

import 'package:agos_app/data/gateway_client.dart';

/// Reads one snapshot. Useful with mock_gateway.py or future ESP32 firmware.
Future<void> main(List<String> arguments) async {
  final client = HttpGatewayClient();
  try {
    final address = parseGatewayAddress(
      arguments.isEmpty ? 'http://127.0.0.1:8080' : arguments.single,
    );
    final snapshot = await client.fetch(address);
    stdout.writeln(
      'Snapshot accepted: ${snapshot.nodes.length} nodes; '
      'source=${snapshot.isDemo ? 'demo' : 'live'}',
    );
  } catch (error) {
    stderr.writeln('Gateway check failed: $error');
    exitCode = 1;
  } finally {
    client.close();
  }
}
