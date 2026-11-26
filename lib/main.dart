import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/gateway_client.dart';
import 'data/local_store.dart';
import 'features/monitor/monitor_controller.dart';
import 'splash_screen.dart';

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
    final stopwatch = Stopwatch()..start();
    MonitorController? controller;

    try {
      final store = await LocalStore.open();
      controller = MonitorController(client: HttpGatewayClient(), store: store);
      await controller.initialize();
      await _waitForMinimumSplash(stopwatch);
      return controller;
    } catch (_) {
      controller?.dispose();
      await _waitForMinimumSplash(stopwatch);
      rethrow;
    }
  }

  Future<void> _waitForMinimumSplash(Stopwatch stopwatch) async {
    final elapsed = stopwatch.elapsed;
    const minimum = Duration(seconds: 1);
    if (elapsed < minimum) {
      await Future<void>.delayed(minimum - elapsed);
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
          body: snapshot.hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
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
                    ),
                  ),
                )
              : const SplashScreen(),
        ),
      );
    },
  );
}
