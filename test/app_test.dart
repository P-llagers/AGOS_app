import 'package:agos_app/app.dart';
import 'package:agos_app/data/gateway_client.dart';
import 'package:agos_app/data/local_store.dart';
import 'package:agos_app/features/monitor/monitor_controller.dart';
import 'package:agos_app/splash_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

class NoGateway implements GatewayClient {
  @override
  Future<GatewaySnapshot> fetch(Uri baseUrl) =>
      throw StateError('No gateway attached');
  @override
  void close() {}
}

void main() {
  var counter = 0;
  Future<MonitorController> createController() async {
    final controller = MonitorController(
      client: NoGateway(),
      store: LocalStore(
        await databaseFactoryMemory.openDatabase('widget-${counter++}'),
      ),
    );
    await controller.initialize();
    return controller;
  }

  testWidgets(
    'starts disconnected, demo is explicit, and navigation works on a phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = (await tester.runAsync(createController))!;
      await tester.pumpWidget(AgosApp(controller: controller));
      expect(find.text('Waiting for the first signal'), findsOneWidget);
      expect(controller.status, GatewayStatus.disconnected);
      await tester.ensureVisible(find.text('Explore demo'));
      await tester.tap(find.text('Explore demo'));
      await tester.pumpAndSettle();
      expect(
        find.text('DEMO · Simulated readings. No real survivors are shown.'),
        findsOneWidget,
      );
      expect(find.text('Node A'), findsOneWidget);
      await tester.tap(find.text('Map').last);
      await tester.pumpAndSettle();
      expect(find.text('Map data has not been added yet.'), findsOneWidget);
      await tester.tap(find.text('Gateway').last);
      await tester.pumpAndSettle();
      expect(find.text('Gateway address'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('larger text fits the narrow monitor and map', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = (await tester.runAsync(createController))!;
    controller.showDemo();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: AgosApp(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows the splash screen branding and gradient', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('LOGO'), findsOneWidget);
    expect(find.text('AGOS'), findsOneWidget);
    expect(find.text('RESCUE MONITOR'), findsOneWidget);

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(SplashScreen),
        matching: find.byType(Container).first,
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(
      gradient.colors,
      const [
        Color(0xFF235C96),
        Color(0xFF071523),
      ],
    );
  });
}
