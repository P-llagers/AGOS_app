import 'package:flutter/material.dart';

import 'app.dart';
import 'data/gateway_client.dart';
import 'data/local_store.dart';
import 'features/monitor/monitor_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<MonitorController> _startup = _initialize();

  Future<MonitorController> _initialize() async {
    final store = await LocalStore.open();
    final controller = MonitorController(
      client: HttpGatewayClient(),
      store: store,
    );
    try {
      await controller.initialize();
      return controller;
    } catch (_) {
      controller.dispose();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MonitorController>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.hasData) return AgosApp(controller: snapshot.requireData);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storage_outlined, size: 48),
                        const SizedBox(height: 16),
                        const Text('Local storage could not open.'),
                        const Text(
                          'Your saved readings have not been replaced.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              setState(() => _startup = _initialize()),
                          child: const Text('Try again'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}
