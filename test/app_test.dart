import 'package:agos_app/app.dart';
import 'package:agos_app/data/gateway_client.dart';
import 'package:agos_app/data/local_store.dart';
import 'package:agos_app/features/map/cebu_offline_map.dart';
import 'package:agos_app/features/monitor/monitor_controller.dart';
import 'package:agos_app/splash_screen.dart';
import 'package:agos_app/ui/agos_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
    'opens on offline Cebu MAP disconnected with no fake nodes, styled navbar, and working tabs',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = (await tester.runAsync(createController))!;
      await tester.pumpWidget(AgosApp(controller: controller));
      await tester.pump();

      // Starts disconnected on MAP tab with truthful 0-node HUD and no fake SOS
      expect(controller.status, GatewayStatus.disconnected);
      expect(find.text('AGOS'), findsOneWidget);
      expect(find.text('GATEWAY'), findsOneWidget);
      expect(find.byType(CebuOfflineMap), findsOneWidget);
      expect(find.text('NODES'), findsWidgets);
      expect(find.text('SOS ACTIVE'), findsOneWidget);
      expect(find.text('LAST UP-LINK'), findsOneWidget);
      expect(find.text('--:--'), findsOneWidget);
      expect(
        find.text('Gateway disconnected · No nodes recorded'),
        findsOneWidget,
      );
      expect(find.textContaining('ACTIVE SOS'), findsNothing);

      // Verify header typography and right alignment of GATEWAY indicator
      final agosTitle = tester.widget<Text>(find.text('AGOS'));
      expect(agosTitle.style?.fontFamily, 'Barlow Condensed');
      expect(agosTitle.style?.fontWeight, FontWeight.w900);
      expect(
        agosTitle.style?.letterSpacing,
        closeTo((agosTitle.style?.fontSize ?? 28) * 0.08, 0.001),
      );

      final gatewayLabel = tester.widget<Text>(find.text('GATEWAY'));
      expect(gatewayLabel.style?.fontFamily, 'Barlow Semi Condensed');
      expect(gatewayLabel.style?.fontWeight, FontWeight.w600);
      expect(
        gatewayLabel.style?.letterSpacing,
        closeTo((gatewayLabel.style?.fontSize ?? 12.5) * 0.03, 0.001),
      );
      expect(tester.getTopRight(find.text('GATEWAY')).dx, greaterThan(330));

      // Verify custom navbar typography & colors (Barlow SemiBold, 8% tracking, #FF7A1A / #9FB5C8)
      final mapLabel = tester.widget<Text>(find.text('MAP'));
      expect(mapLabel.style?.fontFamily, 'Barlow');
      expect(mapLabel.style?.fontWeight, FontWeight.w600);
      expect(
        mapLabel.style?.letterSpacing,
        closeTo((mapLabel.style?.fontSize ?? 11) * 0.08, 0.001),
      );
      expect(mapLabel.style?.color, agosAccentOrange);

      final settingsLabel = tester.widget<Text>(find.text('SETTINGS'));
      expect(settingsLabel.style?.fontFamily, 'Barlow');
      expect(settingsLabel.style?.fontWeight, FontWeight.w600);
      expect(settingsLabel.style?.color, agosMutedText);

      // Verify zoom & recenter buttons on map work without error
      final mapWidget = tester.widget<CebuOfflineMap>(
        find.byType(CebuOfflineMap),
      );
      final initialZoom = mapWidget.controller.zoom;
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(mapWidget.controller.zoom, greaterThan(initialZoom));
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
      await tester.tap(find.byTooltip('Recenter on Cebu'));
      await tester.pump();
      expect(mapWidget.controller.zoom, cebuDefaultZoom);

      // Switch to NODES tab and trigger explicit demo
      await tester.tap(find.text('NODES').last);
      await tester.pumpAndSettle();
      expect(find.text('Waiting for the first signal'), findsOneWidget);
      await tester.ensureVisible(find.text('Explore demo'));
      await tester.tap(find.text('Explore demo'));
      await tester.pumpAndSettle();
      expect(
        find.text('DEMO · Simulated readings. No real survivors are shown.'),
        findsOneWidget,
      );
      expect(find.text('Node A'), findsOneWidget);

      // Switch to ALERTS tab
      await tester.tap(find.text('ALERTS').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('NODE B'), findsOneWidget);

      // Switch to SETTINGS tab
      await tester.tap(find.text('SETTINGS').last);
      await tester.pumpAndSettle();
      expect(find.text('Gateway address'), findsOneWidget);

      // Return to MAP and confirm demo banner is shown
      await tester.tap(find.text('MAP').last);
      await tester.pumpAndSettle();
      expect(find.text('DEMO · SIMULATED READINGS'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'larger text fits narrow MAP, NODES, ALERTS, and SETTINGS views',
    (tester) async {
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
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('NODES').last);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('ALERTS').last);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('SETTINGS').last);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

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
    expect(gradient.colors, const [Color(0xFF235C96), Color(0xFF071523)]);
  });
}
