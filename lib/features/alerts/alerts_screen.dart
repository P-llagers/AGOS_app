import 'package:material_ui/material_ui.dart';

import '../../models/node_observation.dart';
import '../../ui/agos_colors.dart';
import '../monitor/monitor_controller.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({
    super.key,
    required this.controller,
    required this.onOpenSettings,
  });

  final MonitorController controller;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final now = controller.now;
    final gpsWarnings =
        controller.nodes.where((node) => !node.hasCurrentFix(now)).toList()
          ..sort((a, b) => a.packet.nodeId.compareTo(b.packet.nodeId));
    final hasAnyAlert =
        controller.error != null ||
        controller.storageError != null ||
        gpsWarnings.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ALERTS',
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: agosTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Link errors and GPS fix warnings. SOS, immersion, and battery alerts are not yet transmitted by v1 sensor nodes.',
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 13.5,
                  height: 1.5,
                  color: agosMutedText,
                ),
              ),
              const SizedBox(height: 20),
              if (controller.error != null) ...[
                _AlertCard(
                  title: 'GATEWAY CONNECTION ERROR',
                  detail: controller.error!,
                  severityColor: agosAlertRed,
                  bgColor: agosAlertBg,
                  borderColor: agosAlertBorder,
                  icon: Icons.wifi_off,
                  actionLabel: 'Check gateway',
                  onAction: onOpenSettings,
                ),
                const SizedBox(height: 12),
              ],
              if (controller.storageError != null) ...[
                _AlertCard(
                  title: 'LOCAL STORAGE WARNING',
                  detail: controller.storageError!,
                  severityColor: agosWarningAmber,
                  bgColor: const Color(0xFF282012),
                  borderColor: const Color(0xFF7D6025),
                  icon: Icons.save_outlined,
                ),
                const SizedBox(height: 12),
              ],
              for (final node in gpsWarnings) ...[
                _GpsWarningCard(
                  node: node,
                  now: now,
                  isDemo: controller.isDemo,
                ),
                const SizedBox(height: 12),
              ],
              if (!hasAnyAlert)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: agosBarBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: agosBorderBright),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: agosMutedText,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No active alerts',
                          style: TextStyle(
                            fontFamily: 'Barlow',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: agosTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.nodes.isEmpty
                              ? 'No nodes are currently recorded. Connect to the local gateway in Settings to begin monitoring.'
                              : 'All recorded nodes currently have valid GPS fixes and the gateway link is healthy.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Barlow',
                            fontSize: 13.5,
                            height: 1.5,
                            color: agosMutedText,
                          ),
                        ),
                        if (controller.nodes.isEmpty) ...[
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: onOpenSettings,
                            icon: const Icon(Icons.router_outlined, size: 18),
                            label: const Text('Configure gateway'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.detail,
    required this.severityColor,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String detail;
  final Color severityColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: severityColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Barlow',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.7,
                    color: agosTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(
              fontFamily: 'Barlow',
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFFD8E4EE),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _GpsWarningCard extends StatelessWidget {
  const _GpsWarningCard({
    required this.node,
    required this.now,
    required this.isDemo,
  });

  final NodeObservation node;
  final DateTime now;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final age = node.ageAt(now);
    final elapsed = age.inSeconds < 60
        ? '${age.inSeconds}s ago'
        : age.inMinutes < 60
        ? '${age.inMinutes}m ago'
        : '${age.inHours}h ago';
    return _AlertCard(
      title: 'NODE ${node.packet.nodeId} · ${node.fixLabel(now).toUpperCase()}',
      detail:
          '${isDemo ? 'Simulated packet received' : 'Last packet received'} $elapsed · '
          'Position withheld until a fresh valid GPS fix arrives. '
          'GPS status is a device warning, not a wearer-health classification.',
      severityColor: agosWarningAmber,
      bgColor: agosSurface,
      borderColor: const Color(0xFF7D6025),
      icon: Icons.gps_off_rounded,
    );
  }
}
