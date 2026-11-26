import 'package:material_ui/material_ui.dart';

import '../../data/gateway_client.dart';
import '../../ui/agos_colors.dart';
import '../monitor/monitor_controller.dart';

class GatewayScreen extends StatefulWidget {
  const GatewayScreen({
    super.key,
    required this.controller,
    this.isDarkMode = true,
    this.onThemeChanged,
  });

  final MonitorController controller;
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  @override
  State<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends State<GatewayScreen> {
  final _form = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _addressFocus = FocusNode();
  late final _address = TextEditingController(
    text: widget.controller.gateway.toString(),
  );
  bool _working = false;

  // Local display & alert preference controls
  bool _sosSoundAndVibration = true;
  bool _lowBatteryAlerts = true;
  bool _delayedNodeAlerts = true;
  int _lowBatteryThreshold = 50;
  bool _useDecimalDegrees = true;

  @override
  void dispose() {
    _scrollController.dispose();
    _addressFocus.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _working = true);
    try {
      await widget.controller.setGateway(_address.text);
      await widget.controller.connect();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection settings could not be loaded or saved.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _focusGatewayConfig() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
    _addressFocus.requestFocus();
  }

  void _cycleBatteryThreshold() {
    const options = [20, 30, 40, 50];
    final nextIndex =
        (options.indexOf(_lowBatteryThreshold) + 1) % options.length;
    setState(() => _lowBatteryThreshold = options[nextIndex]);
  }

  String _formatSyncTime(DateTime? time) {
    if (time == null) return 'Not synced yet';
    final local = time.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'P.M.' : 'A.M.';
    return 'Last sync $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    final controller = widget.controller;
    final label = controller.isDemo
        ? 'Demo data'
        : switch (controller.status) {
            GatewayStatus.disconnected => 'Disconnected',
            GatewayStatus.connecting => 'Connecting',
            GatewayStatus.connected => 'Gateway connected',
            GatewayStatus.error => 'Connection interrupted',
          };
    final statusColor = controller.isDemo
        ? palette.warning
        : switch (controller.status) {
            GatewayStatus.disconnected => palette.textLabel,
            GatewayStatus.connecting => palette.warning,
            GatewayStatus.connected => palette.online,
            GatewayStatus.error => palette.danger,
          };

    final (uplinkStatusLabel, uplinkDotColor) = switch (controller.status) {
      GatewayStatus.connected => ('Online', palette.online),
      GatewayStatus.connecting => ('Connecting', palette.warning),
      GatewayStatus.error => ('Error', palette.danger),
      GatewayStatus.disconnected => ('Offline', palette.textLabel),
    };

    final (cacheStatusLabel, cacheDotColor) = controller.storageError != null
        ? ('Error', palette.danger)
        : controller.lastSync != null
        ? ('Saved', palette.online)
        : ('Ready', palette.online);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Local gateway connection and offline Cebu map configuration.',
                style: TextStyle(
                  fontFamily: 'Barlow',
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.router_outlined, color: statusColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Barlow',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '1. Join the gateway’s Wi-Fi in your phone settings.\n2. Enter its address below and connect.',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          height: 1.7,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: _form,
                        child: TextFormField(
                          controller: _address,
                          focusNode: _addressFocus,
                          enabled: !_working,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          style: TextStyle(color: palette.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Gateway address',
                            hintText: 'http://192.168.4.1',
                            prefixIcon: Icon(Icons.link),
                          ),
                          validator: (value) {
                            try {
                              parseGatewayAddress(value ?? '');
                              return null;
                            } on FormatException catch (error) {
                              return error.message;
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _working ? null : _connect,
                            icon: _working
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.wifi),
                            label: Text(_working ? 'Connecting…' : 'Connect'),
                          ),
                          if (controller.isPolling)
                            OutlinedButton(
                              onPressed: _working
                                  ? null
                                  : controller.disconnect,
                              child: const Text('Disconnect'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No internet connection is needed. The app does not change your phone’s Wi-Fi automatically.',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 12,
                          color: palette.textLabel,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore before connecting',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Demo mode uses simulated readings and keeps them separate from saved gateway data.',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          height: 1.5,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _working ? null : controller.showDemo,
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('Load demo readings'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline map pack',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cebu, Philippines & surrounding straits (bundled locally for offline use, zooms 7–13 with overzoom to 15.5).',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 13,
                          height: 1.5,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Map data attribution: Esri, HERE, Garmin, OpenStreetMap contributors, GIS User Community.',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 11.5,
                          color: palette.textLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'AGOS research prototype · Gateway firmware integration is still in development.',
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 12,
                  height: 1.5,
                  color: palette.textLabel,
                ),
              ),

              // Structured SETTINGS sections added below existing content
              const SizedBox(height: 24),
              Divider(height: 1, color: palette.border),
              const SizedBox(height: 22),
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  letterSpacing: 32 * 0.02,
                  color: palette.headerTitle,
                ),
              ),
              const SizedBox(height: 14),
              const _SettingsSectionTitle('CONNECTION'),
              const SizedBox(height: 10),
              _SettingsGroupCard(
                children: [
                  _SettingsRow(
                    title: 'Gateway',
                    subtitle:
                        '${controller.gateway.host} · Local Wi-Fi · $label',
                    trailing: InkWell(
                      onTap: _focusGatewayConfig,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontFamily: 'Barlow',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: palette.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _SettingsRow(
                    title: 'Gateway uplink',
                    subtitle: 'Local Wi-Fi · No internet required',
                    trailing: _StatusDotText(
                      color: uplinkDotColor,
                      label: uplinkStatusLabel,
                    ),
                  ),
                  _SettingsRow(
                    title: 'Local snapshot sync',
                    subtitle:
                        'On-device cache · ${_formatSyncTime(controller.lastSync)}',
                    trailing: _StatusDotText(
                      color: cacheDotColor,
                      label: cacheStatusLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SettingsSectionTitle('DISPLAY'),
              const SizedBox(height: 10),
              _SettingsGroupCard(
                children: [
                  _SettingsRow(
                    title: 'Theme',
                    subtitle: 'App appearance',
                    trailing: _ThemeModePill(
                      isDarkMode: widget.isDarkMode,
                      onChanged: (dark) => widget.onThemeChanged?.call(dark),
                    ),
                  ),
                  _SettingsRow(
                    title: 'Offline map',
                    subtitle: 'Cebu, Philippines · 0.5 MB',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: palette.online,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Downloaded',
                          style: TextStyle(
                            fontFamily: 'Barlow',
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: palette.online,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SettingsRow(
                    title: 'Coordinate format',
                    subtitle: 'How positions are shown',
                    onTap: () => setState(
                      () => _useDecimalDegrees = !_useDecimalDegrees,
                    ),
                    trailing: Text(
                      _useDecimalDegrees ? 'Decimal °' : 'DMS',
                      style: TextStyle(
                        fontFamily: 'Barlow',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SettingsSectionTitle('ALERTS'),
              const SizedBox(height: 10),
              _SettingsGroupCard(
                children: [
                  _SettingsRow(
                    title: 'SOS sound and vibration',
                    subtitle: 'Loud alarm when a node sends an SOS flag',
                    trailing: _AgosToggleSwitch(
                      value: _sosSoundAndVibration,
                      onChanged: (v) =>
                          setState(() => _sosSoundAndVibration = v),
                    ),
                  ),
                  _SettingsRow(
                    title: 'Low battery alerts',
                    subtitle: 'Notify when a node is below the threshold',
                    trailing: _AgosToggleSwitch(
                      value: _lowBatteryAlerts,
                      onChanged: (v) => setState(() => _lowBatteryAlerts = v),
                    ),
                  ),
                  _SettingsRow(
                    title: 'Delayed node alerts',
                    subtitle: 'Notify when a node misses its report',
                    trailing: _AgosToggleSwitch(
                      value: _delayedNodeAlerts,
                      onChanged: (v) => setState(() => _delayedNodeAlerts = v),
                    ),
                  ),
                  _SettingsRow(
                    title: 'Low battery threshold',
                    subtitle: 'Warn when a node drops below',
                    onTap: _cycleBatteryThreshold,
                    trailing: Text(
                      '$_lowBatteryThreshold%',
                      style: TextStyle(
                        fontFamily: 'Barlow',
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: palette.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'SOS and battery alert triggers will activate once firmware packets include priority and battery telemetry.',
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 11.5,
                  color: palette.textLabel,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    const fontSize = 12.5;
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Barlow',
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        letterSpacing: fontSize * 0.05, // Exact 5% letter spacing
        color: palette.sectionTitle,
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderBright, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, thickness: 1, color: palette.border),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Barlow',
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Barlow',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: palette.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 175),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: trailing,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

class _StatusDotText extends StatelessWidget {
  const _StatusDotText({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Barlow',
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ThemeModePill extends StatelessWidget {
  const _ThemeModePill({required this.isDarkMode, required this.onChanged});

  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.isDark
            ? const Color(0xFF0A1726)
            : const Color(0xFFE7EEF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.borderBright, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeOptionChip(
            label: 'Dark',
            icon: Icons.dark_mode_rounded,
            selected: isDarkMode,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 2),
          _ThemeOptionChip(
            label: 'Light',
            icon: Icons.light_mode_outlined,
            selected: !isDarkMode,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionChip extends StatelessWidget {
  const _ThemeOptionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    final selectedFg = palette.isDark ? agosNavy : Colors.white;
    final fg = selected ? selectedFg : palette.textMuted;

    return Material(
      color: selected ? palette.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgosToggleSwitch extends StatelessWidget {
  const _AgosToggleSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value
              ? palette.accent
              : (palette.isDark
                    ? const Color(0xFF1F364D)
                    : const Color(0xFFCBD6E2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
