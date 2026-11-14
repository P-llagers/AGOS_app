import 'dart:async';
import 'dart:io';

import 'package:agos_app/data/demo_data.dart';
import 'package:agos_app/data/gateway_client.dart';
import 'package:agos_app/data/local_store.dart';
import 'package:agos_app/features/monitor/monitor_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';

class FakeGateway implements GatewayClient {
  Future<GatewaySnapshot> Function()? handler;
  @override
  Future<GatewaySnapshot> fetch(Uri baseUrl) => handler!();
  @override
  void close() {}
}

void main() {
  var counter = 0;
  late LocalStore store;
  late FakeGateway client;
  late MonitorController controller;
  final now = DateTime.utc(2026, 11, 14);

  setUp(() async {
    store = LocalStore(
      await databaseFactoryMemory.openDatabase('controller-${counter++}'),
    );
    client = FakeGateway()
      ..handler = () async =>
          GatewaySnapshot(nodes: demoNodes(now), isDemo: false);
    controller = MonitorController(
      client: client,
      store: store,
      clock: () => now,
    );
    await controller.initialize();
  });
  tearDown(() => controller.dispose());

  test('live cache survives demo and stays partitioned by gateway', () async {
    await controller.connect();
    expect(controller.status, GatewayStatus.connected);
    expect(await store.loadNodes(controller.gateway.toString()), hasLength(3));
    controller.showDemo();
    expect(controller.isDemo, isTrue);
    expect(controller.isPolling, isFalse);
    await controller.exitDemo();
    expect(controller.isDemo, isFalse);
    expect(controller.isSavedSnapshot, isTrue);
    expect(controller.nodes, hasLength(3));
    await controller.setGateway('http://192.168.4.2');
    expect(controller.nodes, isEmpty);
    expect(await store.loadNodes('http://192.168.4.1'), hasLength(3));
  });

  test(
    'simulated gateway responses are never persisted as live readings',
    () async {
      client.handler = () async =>
          GatewaySnapshot(nodes: demoNodes(now), isDemo: true);
      await controller.connect();
      expect(controller.isDemo, isTrue);
      expect(await store.loadNodes(controller.gateway.toString()), isEmpty);
    },
  );

  test(
    'failed refresh preserves readings and reports connection failure',
    () async {
      await controller.connect();
      client.handler = () async => throw const FormatException('bad packet');
      await controller.refresh();
      expect(controller.status, GatewayStatus.error);
      expect(controller.error, contains('rejected'));
      expect(controller.nodes, hasLength(3));
    },
  );

  test(
    'late network reply cannot replace demo or write to live cache',
    () async {
      final pending = Completer<GatewaySnapshot>();
      final started = Completer<void>();
      client.handler = () {
        started.complete();
        return pending.future;
      };
      final connecting = controller.connect();
      await started.future;
      controller.showDemo();
      pending.complete(const GatewaySnapshot(nodes: [], isDemo: false));
      await connecting;
      expect(controller.isDemo, isTrue);
      expect(controller.nodes, hasLength(3));
      expect(await store.loadNodes(controller.gateway.toString()), isEmpty);
    },
  );

  test(
    'database restores reception time after file close and reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'agos-store-test-',
      );
      final file = '${directory.path}/cache.db';
      final first = LocalStore(await databaseFactoryIo.openDatabase(file));
      await first.saveGateway('http://192.168.4.1');
      await first.saveNodes('http://192.168.4.1', demoNodes(now));
      await first.close();
      final reopened = LocalStore(await databaseFactoryIo.openDatabase(file));
      try {
        expect(await reopened.loadGateway(), 'http://192.168.4.1');
        final saved = await reopened.loadNodes('http://192.168.4.1');
        expect(saved.first.receivedAt, now);
        expect(
          saved.first.hasCurrentFix(now.add(const Duration(seconds: 6))),
          isFalse,
        );
      } finally {
        await reopened.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
