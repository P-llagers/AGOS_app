import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/node_observation.dart';
import '../../ui/agos_colors.dart';
import '../monitor/monitor_controller.dart';
import 'cebu_offline_map.dart';

class OfflineMapScreen extends StatefulWidget {
  const OfflineMapScreen({
    super.key,
    required this.controller,
    required this.onOpenSettings,
    required this.onOpenAlerts,
  });

  final MonitorController controller;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAlerts;

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  final CebuMapController _mapController = CebuMapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _showNodeSheet(BuildContext context, NodeObservation node) {
    final now = widget.controller.now;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: agosSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: agosBorderBright),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: agosOnlineGreen,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      node.packet.nodeId,
                      style: const TextStyle(
                        fontFamily: 'Barlow',
                        fontWeight: FontWeight.w700,
                        color: agosNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NODE ${node.packet.nodeId}',
                          style: const TextStyle(
                            fontFamily: 'Barlow',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: agosTextPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          widget.controller.isDemo
                              ? 'Simulated reading · ${node.fixLabel(now)}'
                              : node.fixLabel(now),
                          style: const TextStyle(
                            fontFamily: 'Barlow',
                            fontSize: 13,
                            color: agosMutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (node.hasCurrentFix(now))
                Text(
                  '${node.packet.latitude!.toStringAsFixed(6)}°N, ${node.packet.longitude!.toStringAsFixed(6)}°E',
                  style: const TextStyle(
                    fontFamily: 'Barlow',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: agosTextPrimary,
                  ),
                )
              else
                const Text(
                  'Current GPS position unavailable',
                  style: TextStyle(
                    fontFamily: 'Barlow',
                    fontSize: 14,
                    color: agosWarningAmber,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'RSSI ${node.rssiDbm == null ? '—' : '${node.rssiDbm} dBm'} · '
                'SNR ${node.snrDb == null ? '—' : '${node.snrDb!.toStringAsFixed(1)} dB'} · '
                'Satellites ${node.packet.satellites ?? '—'}',
                style: const TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 13,
                  color: agosMutedText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Priority and battery telemetry are not reported by v1 sensor packets.',
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 12,
                  color: agosLabelMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUplinkTime(DateTime? time) {
    if (time == null) return '--:--';
    final local = time.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  (Color, String) _statusSummary(MonitorController controller) {
    if (controller.isDemo) {
      return (agosWarningAmber, 'Demo mode · Simulated readings only');
    }
    return switch (controller.status) {
      GatewayStatus.connected => (
        agosOnlineGreen,
        controller.nodes.isEmpty
            ? 'Gateway connected · No nodes recorded'
            : 'Gateway connected · ${controller.currentFixCount} current GPS ${controller.currentFixCount == 1 ? 'fix' : 'fixes'}',
      ),
      GatewayStatus.connecting => (
        agosWarningAmber,
        'Contacting local gateway...',
      ),
      GatewayStatus.error => (
        agosAlertRed,
        'Gateway unavailable · Check local Wi-Fi',
      ),
      GatewayStatus.disconnected => (
        agosLabelMuted,
        controller.nodes.isEmpty
            ? 'Gateway disconnected · No nodes recorded'
            : 'Offline cache · ${controller.nodes.length} saved ${controller.nodes.length == 1 ? 'node' : 'nodes'}',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final (statusColor, statusText) = _statusSummary(controller);
    final hasTopBanner =
        controller.error != null ||
        controller.isDemo ||
        controller.storageError != null;

    return Stack(
      children: [
        // Real offline zoomable map of Cebu, Philippines
        Positioned.fill(
          child: CebuOfflineMap(
            controller: _mapController,
            nodes: controller.nodes,
            now: controller.now,
            onNodeTap: (node) => _showNodeSheet(context, node),
          ),
        ),

        // Conditional top alert/notice banner (only shown for real errors/demo; no fake SOS)
        if (hasTopBanner)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _MapTopBanner(
              controller: controller,
              onTap: controller.error != null
                  ? widget.onOpenSettings
                  : widget.onOpenAlerts,
              onExitDemo: () => controller.exitDemo(),
            ),
          ),

        // Right-side map zoom & recenter controls (+, -, 4-point compass star)
        Positioned(
          top: hasTopBanner ? 104 : 18,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapControlButton(
                tooltip: 'Zoom in',
                onPressed: () => _mapController.zoomBy(0.8),
                child: const Icon(Icons.add, color: agosTextPrimary, size: 22),
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                tooltip: 'Zoom out',
                onPressed: () => _mapController.zoomBy(-0.8),
                child: const Icon(
                  Icons.remove,
                  color: agosTextPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                tooltip: 'Recenter on Cebu',
                onPressed: _mapController.recenter,
                child: const _CompassStarIcon(
                  size: 20,
                  color: Color(0xFF6DA6D9),
                ),
              ),
            ],
          ),
        ),

        // Bottom summary HUD card matching the AGOS UI layout
        Positioned(
          left: 12,
          right: 12,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 13),
            decoration: BoxDecoration(
              color: agosSurfaceTranslucent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: agosBorderBright, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _HudStat(
                        label: 'NODES',
                        value: '${controller.nodes.length}',
                        valueColor: agosTextPrimary,
                      ),
                    ),
                    Expanded(
                      child: _HudStat(
                        label: 'SOS ACTIVE',
                        value: controller.nodes.isEmpty ? '0' : '—',
                        valueColor: controller.nodes.isEmpty
                            ? agosAlertRed
                            : agosMutedText,
                      ),
                    ),
                    Expanded(
                      child: _HudStat(
                        label: 'LAST UP-LINK',
                        value: _formatUplinkTime(controller.lastSync),
                        valueColor: agosTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: agosMutedText,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapTopBanner extends StatelessWidget {
  const _MapTopBanner({
    required this.controller,
    required this.onTap,
    required this.onExitDemo,
  });

  final MonitorController controller;
  final VoidCallback onTap;
  final VoidCallback onExitDemo;

  @override
  Widget build(BuildContext context) {
    final isError = controller.error != null;
    final isDemo = !isError && controller.isDemo;

    final bgColor = isError ? agosAlertBg : const Color(0xEB2D2312);
    final borderColor = isError ? agosAlertBorder : const Color(0xFFB3862D);
    final iconColor = isError ? agosAlertRed : agosWarningAmber;
    final title = isError
        ? 'GATEWAY LINK ERROR'
        : isDemo
        ? 'DEMO · SIMULATED READINGS'
        : 'STORAGE NOTICE';
    final subtitle = isError
        ? controller.error!
        : isDemo
        ? 'No real survivors are shown.'
        : controller.storageError!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isDemo ? Icons.science_outlined : Icons.warning_amber_rounded,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Barlow',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: agosTextPrimary,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Barlow',
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                        color: Color(0xFFDCE7F0),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDemo)
                TextButton(
                  onPressed: onExitDemo,
                  style: TextButton.styleFrom(
                    foregroundColor: agosWarningAmber,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text(
                    'EXIT',
                    style: TextStyle(
                      fontFamily: 'Barlow',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: agosTextPrimary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudStat extends StatelessWidget {
  const _HudStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Barlow',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: agosLabelMuted,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Barlow',
                fontWeight: FontWeight.w800,
                fontSize: 27,
                color: valueColor,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: agosButtonGlass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: const BorderSide(color: agosBorderBright, width: 1),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(width: 42, height: 42, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _CompassStarIcon extends StatelessWidget {
  const _CompassStarIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CompassStarPainter(color),
    );
  }
}

class _CompassStarPainter extends CustomPainter {
  const _CompassStarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rOuter = size.width * 0.48;
    final rInner = size.width * 0.17;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final r = i.isEven ? rOuter : rInner;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CompassStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
