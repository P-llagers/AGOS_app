import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import '../models/node_observation.dart';

/// Latest snapshots by gateway, not the gateway's full packet/CSV history.
class LocalStore {
  LocalStore(this.database);
  final Database database;
  final _cache = stringMapStoreFactory.store('gateway_snapshots');
  final _settings = stringMapStoreFactory.store('settings');

  static Future<LocalStore> open() async {
    if (kIsWeb) {
      return LocalStore(await databaseFactoryWeb.openDatabase('agos_v1'));
    }
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return LocalStore(
      await databaseFactoryIo.openDatabase(
        path.join(directory.path, 'agos_v1.db'),
      ),
    );
  }

  Future<String?> loadGateway() async =>
      (await _settings.record('gateway').get(database))?['url'] as String?;

  Future<void> saveGateway(String url) async {
    await _settings.record('gateway').put(database, {'url': url});
  }

  Future<List<NodeObservation>> loadNodes(String gateway) async {
    final record = await _cache.record(gateway).get(database);
    if (record == null) return [];
    return (record['nodes'] as List)
        .map(
          (item) => NodeObservation.fromStoredJson(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> saveNodes(String gateway, List<NodeObservation> nodes) async {
    await _cache.record(gateway).put(database, {
      'nodes': nodes.map((node) => node.toStoredJson()).toList(),
    });
  }

  Future<void> close() => database.close();
}
