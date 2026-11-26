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
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  ThemeData _buildTheme(AgosPalette palette) {
    final brightness = palette.isDark ? Brightness.dark : Brightness.light;
    final colorScheme = palette.isDark
        ? ColorScheme.dark(
            primary: palette.accent,
            onPrimary: Colors.white,
            secondary: palette.online,
            onSecondary: agosNavy,
            surface: palette.surface,
            onSurface: palette.textPrimary,
            error: palette.danger,
            onError: Colors.white,
            outline: palette.borderBright,
          )
        : ColorScheme.light(
            primary: palette.accent,
            onPrimary: Colors.white,
            secondary: palette.online,
            onSecondary: Colors.white,
            surface: palette.surface,
            onSurface: palette.textPrimary,
            error: palette.danger,
            onError: Colors.white,
            outline: palette.borderBright,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Barlow',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.barBg,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 62,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.border),
        ),
      ),
      dividerColor: palette.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputFill,
        labelStyle: TextStyle(color: palette.textMuted),
        hintStyle: TextStyle(color: palette.textLabel),
        prefixIconColor: palette.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.borderBright),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.borderBright),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
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
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.borderBright),
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGOS · Rescue monitor',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(AgosPalette.light),
      darkTheme: _buildTheme(AgosPalette.dark),
      themeMode: _themeMode,
      home: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final palette = AgosPalette.of(context);
          final controller = widget.controller;
          final showHeaderNotices = _page != 0;
          return Scaffold(
            backgroundColor: palette.scaffoldBg,
            appBar: _AgosTopBar(
              controller: controller,
              onGatewayTap: () => setState(() => _page = 3),
            ),
            body: Column(
              children: [
                if (showHeaderNotices && controller.isDemo)
                  _Notice(
                    text: 'DEMO · Simulated readings. No real survivors are shown.',
                    color: palette.isDark
                        ? const Color(0xFF2E2412)
                        : const Color(0xFFFFF4DC),
                    borderColor: palette.isDark
                        ? const Color(0xFF8C6924)
                        : const Color(0xFFE0B45A),
                    iconColor: palette.warning,
                    textColor: palette.textPrimary,
                    icon: Icons.science_outlined,
                    action: TextButton(
                      onPressed: () => _restoreSaved(context),
                      child: Text(
                        'Exit demo',
                        style: TextStyle(color: palette.warning),
                      ),
                    ),
                  ),
                if (showHeaderNotices && controller.error != null)
                  _Notice(
                    text: controller.error!,
                    color: palette.isDark
                        ? agosAlertBg
                        : const Color(0xFFFFECEE),
                    borderColor: palette.isDark
                        ? agosAlertBorder
                        : const Color(0xFFE48C92),
                    iconColor: palette.danger,
                    textColor: palette.textPrimary,
                    icon: Icons.wifi_off,
                  ),
                if (showHeaderNotices && controller.storageError != null)
                  _Notice(
                    text: controller.storageError!,
                    color: palette.isDark
                        ? const Color(0xFF2E2412)
                        : const Color(0xFFFFF4DC),
                    borderColor: palette.isDark
                        ? const Color(0xFF8C6924)
                        : const Color(0xFFE0B45A),
                    iconColor: palette.warning,
                    textColor: palette.textPrimary,
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
                      GatewayScreen(
                        controller: controller,
                        isDarkMode: _themeMode == ThemeMode.dark,
                        onThemeChanged: (dark) => setState(
                          () => _themeMode = dark
                              ? ThemeMode.dark
                              : ThemeMode.light,
                        ),
                      ),
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

  Color _dotColor(AgosPalette palette) {
    if (controller.isDemo) return palette.warning;
    return switch (controller.status) {
      GatewayStatus.connected => palette.online,
      GatewayStatus.connecting => palette.warning,
      GatewayStatus.error => palette.danger,
      GatewayStatus.disconnected => palette.textLabel,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    const agosFontSize = 28.0;
    const gatewayFontSize = 12.5;

    return Container(
      decoration: BoxDecoration(
        color: palette.barBg,
        border: Border(bottom: BorderSide(color: palette.border, width: 1)),
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
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
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
                          color: palette.headerTitle,
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
                      color: palette.pillBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: palette.borderBright, width: 1),
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
                                  color: _dotColor(palette),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'GATEWAY',
                                style: TextStyle(
                                  fontFamily: 'Barlow Semi Condensed',
                                  fontWeight: FontWeight.w600,
                                  fontSize: gatewayFontSize,
                                  letterSpacing:
                                      gatewayFontSize * 0.03, // 3% tracking
                                  color: palette.textPrimary,
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
    final palette = AgosPalette.of(context);
    const labelFontSize = 9.5;
    const labelLetterSpacing = labelFontSize * 0.08; // Exact 8% letter spacing

    return Container(
      decoration: BoxDecoration(
        color: palette.barBg,
        border: Border(top: BorderSide(color: palette.border, width: 1)),
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
    final palette = AgosPalette.of(context);
    final textColor = selected ? palette.accent : palette.navUnselected;
    return InkWell(
      onTap: onTap,
      splashColor: palette.accent.withAlpha(32),
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
              // Tint selected icon to #C24D08 in light mode; preserve #FF7A1A PNG in dark mode.
              color: palette.isDark
                  ? null
                  : (selected ? palette.accent : palette.navUnselected),
              colorBlendMode: palette.isDark ? null : BlendMode.srcIn,
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
    required this.textColor,
    required this.icon,
    this.action,
  });

  final String text;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
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
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 13,
                  color: textColor,
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
