import 'package:material_ui/material_ui.dart';

import 'features/alerts/alerts_screen.dart';
import 'features/gateway/gateway_screen.dart';
import 'features/map/offline_map_screen.dart';
import 'features/monitor/monitor_controller.dart';
import 'features/monitor/monitor_screen.dart';
import 'ui/agos_colors.dart';

class AgosApp extends StatefulWidget {
  const AgosApp({super.key, required this.controller});
  final MonitorController controller;

  @override
  State<AgosApp> createState() => _AgosAppState();
}

class _AgosAppState extends State<AgosApp> {
  // Default landing tab after the 1-second splash is MAP (index 0).
  int _page = 0;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Barlow',
      colorScheme: const ColorScheme.dark(
        primary: agosAccentOrange,
        onPrimary: Colors.white,
        secondary: agosOnlineGreen,
        onSecondary: agosNavy,
        surface: agosSurface,
        onSurface: agosTextPrimary,
        error: agosAlertRed,
        onError: Colors.white,
        outline: agosBorderBright,
      ),
      scaffoldBackgroundColor: agosScaffoldBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: agosBarBg,
        foregroundColor: agosTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 62,
      ),
      cardTheme: CardThemeData(
        color: agosSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: agosBorder),
        ),
      ),
      dividerColor: agosBorder,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: agosBarBg,
        labelStyle: const TextStyle(color: agosMutedText),
        hintStyle: const TextStyle(color: agosLabelMuted),
        prefixIconColor: agosMutedText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: agosBorderBright),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: agosBorderBright),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: agosAccentOrange, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: agosAccentOrange,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Barlow',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: agosTextPrimary,
          side: const BorderSide(color: agosBorderBright),
          textStyle: const TextStyle(
            fontFamily: 'Barlow',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    return MaterialApp(
      title: 'AGOS · Rescue monitor',
      debugShowCheckedModeBanner: false,
      theme: baseTheme,
      home: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final showHeaderNotices = _page != 0;
          return Scaffold(
            backgroundColor: agosScaffoldBg,
            appBar: _AgosTopBar(
              controller: controller,
              onGatewayTap: () => setState(() => _page = 3),
            ),
            body: Column(
              children: [
                if (showHeaderNotices && controller.isDemo)
                  _Notice(
                    text: 'DEMO · Simulated readings. No real survivors are shown.',
                    color: const Color(0xFF2E2412),
                    borderColor: const Color(0xFF8C6924),
                    iconColor: agosWarningAmber,
                    icon: Icons.science_outlined,
                    action: TextButton(
                      onPressed: () => _restoreSaved(context),
                      child: const Text(
                        'Exit demo',
                        style: TextStyle(color: agosWarningAmber),
                      ),
                    ),
                  ),
                if (showHeaderNotices && controller.error != null)
                  _Notice(
                    text: controller.error!,
                    color: agosAlertBg,
                    borderColor: agosAlertBorder,
                    iconColor: agosAlertRed,
                    icon: Icons.wifi_off,
                  ),
                if (showHeaderNotices && controller.storageError != null)
                  _Notice(
                    text: controller.storageError!,
                    color: const Color(0xFF2E2412),
                    borderColor: const Color(0xFF8C6924),
                    iconColor: agosWarningAmber,
                    icon: Icons.save_outlined,
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _page,
                    children: [
                      OfflineMapScreen(
                        controller: controller,
                        onOpenSettings: () => setState(() => _page = 3),
                        onOpenAlerts: () => setState(() => _page = 2),
                      ),
                      MonitorScreen(
                        controller: controller,
                        onGateway: () => setState(() => _page = 3),
                      ),
                      AlertsScreen(
                        controller: controller,
                        onOpenSettings: () => setState(() => _page = 3),
                        onOpenNodes: () => setState(() => _page = 1),
                      ),
                      GatewayScreen(controller: controller),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _AgosBottomNavBar(
              selectedIndex: _page,
              onSelect: (index) => setState(() => _page = index),
            ),
          );
        },
      ),
    );
  }

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

class _AgosTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _AgosTopBar({required this.controller, required this.onGatewayTap});

  final MonitorController controller;
  final VoidCallback onGatewayTap;

  @override
  Size get preferredSize => const Size.fromHeight(62);

  Color _dotColor() {
    if (controller.isDemo) return agosWarningAmber;
    return switch (controller.status) {
      GatewayStatus.connected => agosOnlineGreen,
      GatewayStatus.connecting => agosWarningAmber,
      GatewayStatus.error => agosAlertRed,
      GatewayStatus.disconnected => agosLabelMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    const agosFontSize = 28.0;
    const gatewayFontSize = 12.5;

    return Container(
      decoration: const BoxDecoration(
        color: agosBarBg,
        border: Border(bottom: BorderSide(color: agosBorder, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'AGOS',
                        style: TextStyle(
                          fontFamily: 'Barlow Condensed',
                          fontWeight: FontWeight.w900,
                          fontSize: agosFontSize,
                          letterSpacing: agosFontSize * 0.08, // 8% tracking
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: const Color(0xFF102234),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(
                          color: agosBorderBright,
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: onGatewayTap,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.5,
                                height: 8.5,
                                decoration: BoxDecoration(
                                  color: _dotColor(),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'GATEWAY',
                                style: TextStyle(
                                  fontFamily: 'Barlow Semi Condensed',
                                  fontWeight: FontWeight.w600,
                                  fontSize: gatewayFontSize,
                                  letterSpacing:
                                      gatewayFontSize * 0.03, // 3% tracking
                                  color: agosTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemSpec {
  const _NavItemSpec({
    required this.label,
    required this.selectedAsset,
    required this.unselectedAsset,
  });

  final String label;
  final String selectedAsset;
  final String unselectedAsset;
}

class _AgosBottomNavBar extends StatelessWidget {
  const _AgosBottomNavBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
    _NavItemSpec(
      label: 'MAP',
      selectedAsset: 'lib/assets/map-c.png',
      unselectedAsset: 'lib/assets/map-uc.png',
    ),
    _NavItemSpec(
      label: 'NODES',
      selectedAsset: 'lib/assets/nodes-c.png',
      unselectedAsset: 'lib/assets/nodes-uc.png',
    ),
    _NavItemSpec(
      label: 'ALERTS',
      selectedAsset: 'lib/assets/warn-c.png',
      unselectedAsset: 'lib/assets/warn-uc.png',
    ),
    _NavItemSpec(
      label: 'SETTINGS',
      selectedAsset: 'lib/assets/settings-c.png',
      unselectedAsset: 'lib/assets/settings-uc.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const labelFontSize = 9.5;
    const labelLetterSpacing = labelFontSize * 0.08; // Exact 8% letter spacing

    return Container(
      decoration: const BoxDecoration(
        color: agosBarBg,
        border: Border(top: BorderSide(color: agosBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _AgosNavButton(
                    spec: _items[i],
                    selected: i == selectedIndex,
                    labelFontSize: labelFontSize,
                    labelLetterSpacing: labelLetterSpacing,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgosNavButton extends StatelessWidget {
  const _AgosNavButton({
    required this.spec,
    required this.selected,
    required this.labelFontSize,
    required this.labelLetterSpacing,
    required this.onTap,
  });

  final _NavItemSpec spec;
  final bool selected;
  final double labelFontSize;
  final double labelLetterSpacing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? agosAccentOrange : agosMutedText;
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x1FFF7A1A),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              selected ? spec.selectedAsset : spec.unselectedAsset,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  spec.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Barlow',
                    fontWeight: FontWeight.w600,
                    fontSize: labelFontSize,
                    letterSpacing: labelLetterSpacing,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    this.action,
  });

  final String text;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      border: Border(bottom: BorderSide(color: borderColor, width: 1)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 13,
                  color: agosTextPrimary,
                ),
              ),
            ),
          ],
        ),
        if (action != null)
          Align(alignment: Alignment.centerRight, child: action!),
      ],
    ),
  );
}
