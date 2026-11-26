import 'package:material_ui/material_ui.dart';

import '../../ui/agos_colors.dart';
import '../monitor/monitor_controller.dart';

enum _AlertsFilter { all, critical, warnings, info }

enum _AlertSeverity { critical, warning, info }

class _AlertEntry {
  const _AlertEntry({
    required this.severity,
    required this.header,
    required this.timestamp,
    required this.headline,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final _AlertSeverity severity;
  final String header;
  final String timestamp;
  final String headline;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    super.key,
    required this.controller,
    required this.onOpenSettings,
    required this.onOpenNodes,
  });

  final MonitorController controller;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenNodes;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _AlertsFilter _filter = _AlertsFilter.all;

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final local = time.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'P.M.' : 'A.M.';
    return '$hour12:$minute $period';
  }

  List<_AlertEntry> _buildAlerts(MonitorController controller) {
    final now = controller.now;
    final entries = <_AlertEntry>[];

    if (controller.error != null) {
      entries.add(
        _AlertEntry(
          severity: _AlertSeverity.warning,
          header: 'WARNING · GATEWAY',
          timestamp: _formatTime(now),
          headline: 'Gateway connection interrupted',
          body: controller.error!,
          actionLabel: 'Open connection settings',
          onAction: widget.onOpenSettings,
        ),
      );
    }

    if (controller.storageError != null) {
      entries.add(
        _AlertEntry(
          severity: _AlertSeverity.warning,
          header: 'WARNING · STORAGE',
          timestamp: _formatTime(now),
          headline: 'Local snapshot could not be saved',
          body: controller.storageError!,
          actionLabel: 'Open connection settings',
          onAction: widget.onOpenSettings,
        ),
      );
    }

    final gpsWarnings =
        controller.nodes.where((node) => !node.hasCurrentFix(now)).toList()
          ..sort((a, b) => a.packet.nodeId.compareTo(b.packet.nodeId));

    for (final node in gpsWarnings) {
      final age = node.ageAt(now);
      final elapsed = age.inSeconds < 60
          ? '${age.inSeconds} seconds'
          : age.inMinutes < 60
          ? '${age.inMinutes} ${age.inMinutes == 1 ? 'minute' : 'minutes'}'
          : '${age.inHours} ${age.inHours == 1 ? 'hour' : 'hours'}';
      entries.add(
        _AlertEntry(
          severity: _AlertSeverity.warning,
          header: 'WARNING · NODE ${node.packet.nodeId}',
          timestamp: _formatTime(node.receivedAt),
          headline: node.fixLabel(now),
          body:
              '${controller.isDemo ? 'Simulated packet received' : 'Last packet received'} $elapsed ago. '
              'Coordinates are withheld until a fresh valid GPS fix arrives.',
          actionLabel: 'View node ${node.packet.nodeId}',
          onAction: widget.onOpenNodes,
        ),
      );
    }

    if (controller.isDemo) {
      entries.add(
        _AlertEntry(
          severity: _AlertSeverity.info,
          header: 'INFO · DEMO MODE',
          timestamp: _formatTime(now),
          headline: 'Simulated readings active',
          body: 'Demo readings are isolated from saved gateway data. No real survivors are shown.',
          actionLabel: 'Open connection settings',
          onAction: widget.onOpenSettings,
        ),
      );
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    final controller = widget.controller;
    final allAlerts = _buildAlerts(controller);
    final attentionCount = allAlerts
        .where(
          (a) =>
              a.severity == _AlertSeverity.critical ||
              a.severity == _AlertSeverity.warning,
        )
        .length;
    final visibleAlerts = switch (_filter) {
      _AlertsFilter.all => allAlerts,
      _AlertsFilter.critical =>
        allAlerts.where((a) => a.severity == _AlertSeverity.critical).toList(),
      _AlertsFilter.warnings =>
        allAlerts.where((a) => a.severity == _AlertSeverity.warning).toList(),
      _AlertsFilter.info =>
        allAlerts.where((a) => a.severity == _AlertSeverity.info).toList(),
    };

    const titleFontSize = 32.0;
    const attentionFontSize = 13.5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ALERTS',
                          style: TextStyle(
                            fontFamily: 'Barlow Condensed',
                            fontWeight: FontWeight.w700,
                            fontSize: titleFontSize,
                            letterSpacing: titleFontSize * 0.02, // 2% tracking
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
                      child: Text(
                        '$attentionCount need attention',
                        style: TextStyle(
                          fontFamily: 'Barlow Semi Condensed',
                          fontWeight: FontWeight.w500,
                          fontSize: attentionFontSize,
                          letterSpacing:
                              attentionFontSize * 0.01, // 1% tracking
                          color: palette.isDark
                              ? const Color(0xFF8BB8DC)
                              : palette.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AlertFilterPill(
                    label: 'All',
                    selected: _filter == _AlertsFilter.all,
                    onTap: () => setState(() => _filter = _AlertsFilter.all),
                  ),
                  _AlertFilterPill(
                    label: 'Critical',
                    selected: _filter == _AlertsFilter.critical,
                    onTap: () =>
                        setState(() => _filter = _AlertsFilter.critical),
                  ),
                  _AlertFilterPill(
                    label: 'Warnings',
                    selected: _filter == _AlertsFilter.warnings,
                    onTap: () =>
                        setState(() => _filter = _AlertsFilter.warnings),
                  ),
                  _AlertFilterPill(
                    label: 'Info',
                    selected: _filter == _AlertsFilter.info,
                    onTap: () => setState(() => _filter = _AlertsFilter.info),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (visibleAlerts.isEmpty)
                _AlertsEmptyCard(
                  filter: _filter,
                  hasNodes: controller.nodes.isNotEmpty,
                  onOpenSettings: widget.onOpenSettings,
                )
              else
                for (final alert in visibleAlerts) ...[
                  _TacticalAlertCard(entry: alert),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertFilterPill extends StatelessWidget {
  const _AlertFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    const buttonFontSize = 14.5;

    return Material(
      color: selected ? palette.pillSelectedBg : palette.pillBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? palette.accent : palette.borderBright,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Barlow Semi Condensed',
              fontWeight: FontWeight.w500,
              fontSize: buttonFontSize,
              letterSpacing: buttonFontSize * -0.01, // -1% tracking
              color: palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TacticalAlertCard extends StatelessWidget {
  const _TacticalAlertCard({required this.entry});

  final _AlertEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    final (
      bgColor,
      borderColor,
      accentColor,
      bodyColor,
      icon,
    ) = switch (entry.severity) {
      _AlertSeverity.critical => (
        palette.isDark ? const Color(0xFF34131B) : const Color(0xFFFFF0F2),
        palette.isDark ? const Color(0xFFE04850) : const Color(0xFFD9434E),
        palette.isDark ? const Color(0xFFF0626A) : const Color(0xFFC22734),
        palette.isDark ? const Color(0xFFE0C8CC) : const Color(0xFF5A2A30),
        Icons.warning_amber_rounded,
      ),
      _AlertSeverity.warning => (
        palette.isDark ? const Color(0xFF28200D) : const Color(0xFFFFF8E8),
        palette.isDark ? const Color(0xFFC99626) : const Color(0xFFD19622),
        palette.isDark ? const Color(0xFFF4B63B) : const Color(0xFF9F6700),
        palette.isDark ? const Color(0xFFDDD3BD) : const Color(0xFF5B4A23),
        Icons.warning_amber_rounded,
      ),
      _AlertSeverity.info => (
        palette.isDark ? const Color(0xFF0F2337) : const Color(0xFFEEF6FD),
        palette.isDark ? const Color(0xFF3E7EB0) : const Color(0xFF4F8EC0),
        palette.isDark ? const Color(0xFF69B3EA) : const Color(0xFF1D6296),
        palette.isDark ? const Color(0xFFC4D7E8) : const Color(0xFF2B4C66),
        Icons.info_outline_rounded,
      ),
    };
    final linkColor = palette.isDark ? Colors.white : palette.textPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  entry.header,
                  style: TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: 0.6,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.timestamp,
                style: TextStyle(
                  fontFamily: 'Barlow Semi Condensed',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  letterSpacing: 0.6,
                  color: bodyColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.headline,
            style: TextStyle(
              fontFamily: 'Barlow',
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: palette.headerTitle,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.body,
            style: TextStyle(
              fontFamily: 'Barlow',
              fontWeight: FontWeight.w400,
              fontSize: 13.5,
              height: 1.45,
              color: bodyColor,
            ),
          ),
          if (entry.actionLabel != null && entry.onAction != null) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: entry.onAction,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  entry.actionLabel!,
                  style: TextStyle(
                    fontFamily: 'Barlow Semi Condensed',
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: linkColor,
                    decoration: TextDecoration.underline,
                    decorationColor: linkColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertsEmptyCard extends StatelessWidget {
  const _AlertsEmptyCard({
    required this.filter,
    required this.hasNodes,
    required this.onOpenSettings,
  });

  final _AlertsFilter filter;
  final bool hasNodes;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final palette = AgosPalette.of(context);
    final (title, body, showSettingsLink) = switch (filter) {
      _AlertsFilter.all => (
        'No active alerts',
        hasNodes
            ? 'All recorded nodes currently have valid GPS fixes and the gateway link is healthy. SOS and battery alerts are not yet transmitted by v1 sensor nodes.'
            : 'No nodes are currently recorded and no link warnings are active. SOS, immersion, and battery alerts are not yet transmitted by v1 sensor nodes.',
        !hasNodes,
      ),
      _AlertsFilter.critical => (
        'No critical alerts',
        'SOS and water-immersion flags are not yet transmitted by current v1 sensor packets.',
        false,
      ),
      _AlertsFilter.warnings => (
        'No warnings',
        'Gateway link and recorded node GPS status currently have no active warnings.',
        false,
      ),
      _AlertsFilter.info => (
        'No informational notices',
        'Session notices such as demo mode will appear here when active.',
        false,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderBright, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Barlow Condensed',
              fontWeight: FontWeight.w700,
              fontSize: 21,
              letterSpacing: 0.4,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Barlow',
              fontSize: 13.5,
              height: 1.45,
              color: palette.textMuted,
            ),
          ),
          if (showSettingsLink) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: onOpenSettings,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'Open connection settings',
                  style: TextStyle(
                    fontFamily: 'Barlow Semi Condensed',
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: palette.headerTitle,
                    decoration: TextDecoration.underline,
                    decorationColor: palette.headerTitle,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
