import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/demo_data.dart';
import '../../data/gateway_client.dart';
import '../../data/local_store.dart';
import '../../models/node_observation.dart';

enum GatewayStatus { disconnected, connecting, connected, error }

class MonitorController extends ChangeNotifier {
  MonitorController({
    required this.client,
    required this.store,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final GatewayClient client;
  final LocalStore store;
  final DateTime Function() _clock;
  Uri gateway = Uri.parse('http://192.168.4.1');
  List<NodeObservation> nodes = const [];
  GatewayStatus status = GatewayStatus.disconnected;
  bool isDemo = false;
  bool isSavedSnapshot = false;
  String? error;
  String? storageError;
  DateTime? lastSync;
  Timer? _poll;
  Timer? _ticker;
  int _generation = 0;
  bool _disposed = false;
  int? _activeRequest;
  DateTime get now => _clock();
  bool get isPolling => _poll != null;
  bool get isBusy => _activeRequest == _generation;
  int get currentFixCount => nodes.where((n) => n.hasCurrentFix(now)).length;
  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<void> initialize() async {
    final saved = await store.loadGateway();
    if (saved != null) gateway = parseGatewayAddress(saved);
    nodes = List.unmodifiable(await store.loadNodes(gateway.toString()));
    isSavedSnapshot = nodes.isNotEmpty;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _notify());
  }

  Future<void> setGateway(String address) async {
    final next = parseGatewayAddress(address);
    disconnect();
    final generation = _generation;
    await store.saveGateway(next.toString());
    if (!_isCurrent(generation)) return;
    gateway = next;
    isDemo = false;
    lastSync = null;
    nodes = const [];
    final saved = await store.loadNodes(next.toString());
    if (!_isCurrent(generation)) return;
    nodes = List.unmodifiable(saved);
    isSavedSnapshot = nodes.isNotEmpty;
    _notify();
  }

  Future<void> connect() async {
    disconnect();
    final generation = _generation;
    isDemo = false;
    nodes = const [];
    final saved = await store.loadNodes(gateway.toString());
    if (!_isCurrent(generation)) return;
    nodes = List.unmodifiable(saved);
    isSavedSnapshot = nodes.isNotEmpty;
    status = GatewayStatus.connecting;
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed || isBusy || !isPolling) return;
    final generation = _generation;
    final address = gateway;
    _activeRequest = generation;
    error = null;
    _notify();
    try {
      final snapshot = await client.fetch(address);
      if (!_isCurrent(generation)) return;
      nodes = snapshot.nodes;
      isDemo = snapshot.isDemo;
      isSavedSnapshot = false;
      lastSync = now;
      status = GatewayStatus.connected;
      storageError = null;
      if (!snapshot.isDemo) {
        try {
          await store.saveNodes(address.toString(), snapshot.nodes);
        } catch (_) {
          if (_isCurrent(generation)) {
            storageError = 'Readings could not be saved on this device.';
          }
        }
      }
    } on FormatException {
      if (!_isCurrent(generation)) return;
      status = GatewayStatus.error;
      error = 'Gateway data was rejected. Check the gateway protocol version.';
    } catch (_) {
      if (!_isCurrent(generation)) return;
      status = GatewayStatus.error;
      error =
          'Gateway unavailable. Check Wi-Fi and the gateway address. Retrying…';
    } finally {
      if (_activeRequest == generation) _activeRequest = null;
      _notify();
    }
  }

  void showDemo() {
    disconnect();
    isDemo = true;
    isSavedSnapshot = false;
    lastSync = null;
    storageError = null;
    nodes = List.unmodifiable(demoNodes(now));
    _notify();
  }

  Future<void> exitDemo() async {
    disconnect();
    final generation = _generation;
    final saved = await store.loadNodes(gateway.toString());
    if (!_isCurrent(generation)) return;
    isDemo = false;
    nodes = List.unmodifiable(saved);
    isSavedSnapshot = nodes.isNotEmpty;
    lastSync = null;
    _notify();
  }

  void disconnect() {
    _generation++;
    _poll?.cancel();
    _poll = null;
    status = GatewayStatus.disconnected;
    error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _poll?.cancel();
    _ticker?.cancel();
    client.close();
    unawaited(store.close());
    super.dispose();
  }
}
