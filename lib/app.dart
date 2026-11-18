import 'package:material_ui/material_ui.dart';

import 'features/monitor/monitor_controller.dart';
import 'features/monitor/monitor_screen.dart';
import 'features/gateway/gateway_screen.dart';
import 'features/map/offline_map_screen.dart';
import 'ui/agos_colors.dart';

class AgosApp extends StatefulWidget {
  const AgosApp({super.key, required this.controller});
  final MonitorController controller;

  @override
  State<AgosApp> createState() => _AgosAppState();
}

class _AgosAppState extends State<AgosApp> {
  int _page = 0;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AGOS · Rescue monitor',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: agosTeal,
        primary: agosTeal,
        secondary: agosNavy,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F6F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: agosNavy,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 76,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E9EC)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    home: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final wide = MediaQuery.sizeOf(context).width >= 760;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: agosTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.radar, color: Colors.white, size: 27),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AGOS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'RESCUE MONITOR',
                      style: TextStyle(fontSize: 10, letterSpacing: 1.8),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (wide)
                const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Chip(
                    label: Text('Prototype'),
                    avatar: Icon(Icons.science_outlined, size: 17),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isDemo)
                _Notice(
                  text:
                      'DEMO · Simulated readings. No real survivors are shown.',
                  color: const Color(0xFFFFEDC2),
                  icon: Icons.science_outlined,
                  action: TextButton(
                    onPressed: () => _restoreSaved(context),
                    child: const Text('Exit demo'),
                  ),
                ),
              if (controller.error != null)
                _Notice(
                  text: controller.error!,
                  color: const Color(0xFFFFE8E4),
                  icon: Icons.wifi_off,
                ),
              if (controller.storageError != null)
                _Notice(
                  text: controller.storageError!,
                  color: const Color(0xFFFFEDC2),
                  icon: Icons.save_outlined,
                ),
              Expanded(
                child: Row(
                  children: [
                    if (wide)
                      NavigationRail(
                        selectedIndex: _page,
                        onDestinationSelected: (index) =>
                            setState(() => _page = index),
                        labelType: NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.people_outline),
                            selectedIcon: Icon(Icons.people),
                            label: Text('Monitor'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.map_outlined),
                            selectedIcon: Icon(Icons.map),
                            label: Text('Map'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.router_outlined),
                            selectedIcon: Icon(Icons.router),
                            label: Text('Gateway'),
                          ),
                        ],
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: _page,
                        children: [
                          MonitorScreen(
                            controller: controller,
                            onGateway: () => setState(() => _page = 2),
                          ),
                          OfflineMapScreen(controller: controller),
                          GatewayScreen(controller: controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _page,
                  onDestinationSelected: (index) =>
                      setState(() => _page = index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: 'Monitor',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: 'Map',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.router_outlined),
                      selectedIcon: Icon(Icons.router),
                      label: 'Gateway',
                    ),
                  ],
                ),
        );
      },
    ),
  );

  Future<void> _restoreSaved(BuildContext context) async {
    try {
      await widget.controller.exitDemo();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved readings could not be loaded.')),
        );
      }
    }
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.color,
    required this.icon,
    this.action,
  });
  final String text;
  final Color color;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    color: color,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
        if (action != null)
          Align(alignment: Alignment.centerRight, child: action!),
      ],
    ),
  );
}
