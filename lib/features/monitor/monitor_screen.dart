import 'package:material_ui/material_ui.dart';

import '../../models/node_observation.dart';
import '../../ui/agos_colors.dart';
import 'monitor_controller.dart';

enum _NodesFilter { all, sos, delayed }

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({
    super.key,
    required this.controller,
    required this.onGateway,
  });
  final MonitorController controller;
  final VoidCallback onGateway;

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  _NodesFilter _filter = _NodesFilter.all;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final now = controller.now;
    final nodes = [...controller.nodes]
      ..sort((a, b) => a.packet.nodeId.compareTo(b.packet.nodeId));
    final delayedNodes = nodes.where((n) => !n.hasCurrentFix(now)).toList();
    final filteredNodes = switch (_filter) {
      _NodesFilter.all => nodes,
      _NodesFilter.sos => const <NodeObservation>[],
      _NodesFilter.delayed => delayedNodes,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: agosSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: agosBorderBright),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ON THE WATER. WITHIN REACH.',
                      style: TextStyle(
                        fontFamily: 'Barlow',
                        color: agosOnlineGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Every signal matters.',
                      style: TextStyle(
                        fontFamily: 'Barlow',
                        color: agosTextPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _feedLabel(controller),
                      style: const TextStyle(
                        fontFamily: 'Barlow',
                        color: agosMutedText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: widget.onGateway,
                      icon: const Icon(Icons.router_outlined, size: 18),
                      label: Text(
                        controller.isPolling
                            ? 'View gateway'
                            : 'Set up gateway',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      value: '${nodes.length}',
                      label: 'Nodes recorded',
                      icon: Icons.sensors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Metric(
                      value: '${controller.currentFixCount}',
                      label: 'Current GPS fixes',
                      icon: Icons.gps_fixed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Node readings',
                      style: TextStyle(
                        fontFamily: 'Barlow',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: agosTextPrimary,
                      ),
                    ),
                  ),
                  Text(
                    controller.isDemo
                        ? 'SIMULATED'
                        : controller.isSavedSnapshot || !controller.isPolling
                        ? 'SAVED / OFFLINE'
                        : 'GATEWAY FEED',
                    style: const TextStyle(
                      fontFamily: 'Barlow',
                      fontSize: 10.5,
                      color: agosOnlineGreen,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'GPS and link status · Rescue priorities are not yet reported by the nodes.',
                style: TextStyle(
                  fontFamily: 'Barlow',
                  color: agosMutedText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (nodes.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.sensors_off,
                          size: 40,
                          color: agosMutedText,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Waiting for the first signal',
                          style: TextStyle(
                            fontFamily: 'Barlow',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: agosTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connect to your gateway to receive node readings, or explore a simulated example.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Barlow',
                            color: agosMutedText,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: controller.showDemo,
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('Explore demo'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final node in nodes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NodeCard(
                      node: node,
                      now: now,
                      isDemo: controller.isDemo,
                    ),
                  ),
              const SizedBox(height: 14),
              const Text(
                'AGOS · Autonomous Geolocation for Open-sea Survival',
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 11,
                  color: agosLabelMuted,
                ),
              ),

              // Tactical NODES directory & filter section added at the bottom
              const SizedBox(height: 24),
              const Divider(height: 1, color: agosBorder),
              const SizedBox(height: 22),
              _TacticalNodesSection(
                allCount: nodes.length,
                sosCount: 0,
                delayedCount: delayedNodes.length,
                filter: _filter,
                onFilterChanged: (next) => setState(() => _filter = next),
                updatedLabel: _updatedTimestampLabel(controller),
                filteredNodes: filteredNodes,
                now: now,
                isDemo: controller.isDemo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _updatedTimestampLabel(MonitorController controller) {
    final stamp = controller.lastSync ??
        (controller.isDemo ? controller.now : null) ??
        (controller.nodes.isNotEmpty
            ? controller.nodes
                  .map((n) => n.receivedAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
            : null);
    if (stamp == null) return 'Updated --:--';
    final local = stamp.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'P.M.' : 'A.M.';
    return 'Updated $hour12:$minute $period';
  }

  String _feedLabel(MonitorController controller) {
    if (controller.isDemo) {
      return 'You are exploring a simulated scene. These readings are not live.';
    }
    return switch (controller.status) {
      GatewayStatus.connected =>
        controller.storageError == null
            ? 'Gateway connected. Readings are saved on this device.'
            : 'Gateway connected. Readings are available for this session.',
      GatewayStatus.connecting =>
        'Contacting the gateway. Waiting for a valid response.',
      GatewayStatus.error =>
        'Gateway feed interrupted. Previously received readings remain visible.',
      GatewayStatus.disconnected =>
        'An offline view of your rescue network. Connect a gateway to start receiving readings.',
    };
  }
}

class _TacticalNodesSection extends StatelessWidget {
  const _TacticalNodesSection({
    required this.allCount,
    required this.sosCount,
    required this.delayedCount,
    required this.filter,
    required this.onFilterChanged,
    required this.updatedLabel,
    required this.filteredNodes,
    required this.now,
    required this.isDemo,
  });

  final int allCount;
  final int sosCount;
  final int delayedCount;
  final _NodesFilter filter;
  final ValueChanged<_NodesFilter> onFilterChanged;
  final String updatedLabel;
  final List<NodeObservation> filteredNodes;
  final DateTime now;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    const titleFontSize = 32.0;
    const updatedFontSize = 13.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Flexible(
              child: Padding(
                padding: EdgeInsets.only(right: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NODES',
                    style: TextStyle(
                      fontFamily: 'Barlow Condensed',
                      fontWeight: FontWeight.w700,
                      fontSize: titleFontSize,
                      letterSpacing: titleFontSize * 0.02, // 2% tracking
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
                child: Text(
                  updatedLabel,
                  style: const TextStyle(
                    fontFamily: 'Barlow Semi Condensed',
                    fontWeight: FontWeight.w500,
                    fontSize: updatedFontSize,
                    letterSpacing: updatedFontSize * 0.01, // 1% tracking
                    color: Color(0xFFDCE7F0),
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
            _NodesFilterPill(
              label: 'All $allCount',
              selected: filter == _NodesFilter.all,
              onTap: () => onFilterChanged(_NodesFilter.all),
            ),
            _NodesFilterPill(
              label: 'SOS $sosCount',
              selected: filter == _NodesFilter.sos,
              onTap: () => onFilterChanged(_NodesFilter.sos),
            ),
            _NodesFilterPill(
              label: 'Delayed $delayedCount',
              selected: filter == _NodesFilter.delayed,
              onTap: () => onFilterChanged(_NodesFilter.delayed),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (filteredNodes.isEmpty)
          _TacticalEmptyCard(filter: filter, allCount: allCount)
        else
          for (final node in filteredNodes)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TacticalNodeCard(node: node, now: now, isDemo: isDemo),
            ),
      ],
    );
  }
}

class _NodesFilterPill extends StatelessWidget {
  const _NodesFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const buttonFontSize = 14.5;

    return Material(
      color: selected ? const Color(0xFF1A344D) : const Color(0xFF102235),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? agosAccentOrange : agosBorderBright,
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
            style: const TextStyle(
              fontFamily: 'Barlow Semi Condensed',
              fontWeight: FontWeight.w500,
              fontSize: buttonFontSize,
              letterSpacing: buttonFontSize * -0.01, // -1% tracking
              color: agosTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TacticalEmptyCard extends StatelessWidget {
  const _TacticalEmptyCard({required this.filter, required this.allCount});

  final _NodesFilter filter;
  final int allCount;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (filter) {
      _NodesFilter.all => (
        'No nodes recorded',
        'Live or simulated node status cards will appear here once packets are received.',
      ),
      _NodesFilter.sos => (
        'No active SOS alerts',
        'Current v1 sensor packets do not report SOS status yet.',
      ),
      _NodesFilter.delayed => (
        allCount == 0 ? 'No delayed nodes' : 'All recorded nodes are current',
        allCount == 0
            ? 'Connect a gateway to monitor node contact and GPS freshness.'
            : 'Every recorded node currently has a fresh valid GPS fix.',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: agosSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: agosBorderBright, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Barlow Condensed',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 0.4,
              color: agosTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Barlow',
              fontSize: 13.5,
              height: 1.45,
              color: agosMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticalNodeCard extends StatelessWidget {
  const _TacticalNodeCard({
    required this.node,
    required this.now,
    required this.isDemo,
  });

  final NodeObservation node;
  final DateTime now;
  final bool isDemo;

  String _formatCoord(double lat, double lon) {
    final ns = lat >= 0 ? 'N' : 'S';
    final ew = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(3)}° $ns, ${lon.abs().toStringAsFixed(3)}° $ew';
  }

  @override
  Widget build(BuildContext context) {
    final current = node.hasCurrentFix(now);
    final age = node.ageAt(now);
    final elapsed = age.inSeconds < 60
        ? '${age.inSeconds} sec ago'
        : age.inMinutes < 60
        ? '${age.inMinutes} min ago'
        : '${age.inHours} hr ago';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF102336),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: agosBorderBright, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  isDemo
                      ? 'NODE ${node.packet.nodeId} (DEMO)'
                      : 'NODE ${node.packet.nodeId}',
                  style: const TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 25,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _TacticalStatusBadge(online: current),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TacticalStatColumn(
                  label: 'LAST HOP',
                  value: elapsed,
                ),
              ),
              Expanded(
                child: _TacticalStatColumn(
                  label: 'SIGNAL',
                  value: node.rssiDbm == null ? '—' : '${node.rssiDbm} dBm',
                ),
              ),
              const Expanded(
                child: _TacticalStatColumn(
                  label: 'BATTERY',
                  value: 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            current &&
                    node.packet.latitude != null &&
                    node.packet.longitude != null
                ? _formatCoord(node.packet.latitude!, node.packet.longitude!)
                : '${node.fixLabel(now)} · Position unavailable',
            style: const TextStyle(
              fontFamily: 'Barlow',
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
              letterSpacing: 0.6,
              color: agosMutedText,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticalStatusBadge extends StatelessWidget {
  const _TacticalStatusBadge({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final bgColor = online ? const Color(0xFF0E2F2C) : const Color(0xFF2B2312);
    final borderColor = online ? agosOnlineGreen : const Color(0xFFC49228);
    final fgColor = online ? agosOnlineGreen : agosWarningAmber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (online)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: fgColor,
                shape: BoxShape.circle,
              ),
            )
          else
            Icon(Icons.access_time_rounded, size: 13, color: fgColor),
          const SizedBox(width: 6),
          Text(
            online ? 'ONLINE' : 'DELAYED',
            style: TextStyle(
              fontFamily: 'Barlow Semi Condensed',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              letterSpacing: 0.6,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticalStatColumn extends StatelessWidget {
  const _TacticalStatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Barlow Semi Condensed',
                fontWeight: FontWeight.w500,
                fontSize: 11.5,
                letterSpacing: 0.6,
                color: agosLabelMuted,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Barlow',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: agosTextPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: agosAccentOrange, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Barlow',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: agosTextPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Barlow',
              fontSize: 12,
              color: agosMutedText,
            ),
          ),
        ],
      ),
    ),
  );
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.node,
    required this.now,
    required this.isDemo,
  });
  final NodeObservation node;
  final DateTime now;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final current = node.hasCurrentFix(now);
    final age = node.ageAt(now);
    final elapsed = age.inSeconds < 60
        ? '${age.inSeconds}s ago'
        : age.inMinutes < 60
        ? '${age.inMinutes}m ago'
        : '${age.inHours}h ago';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: current
                      ? const Color(0xFF143C38)
                      : const Color(0xFF2B2518),
                  foregroundColor: current ? agosOnlineGreen : agosWarningAmber,
                  child: Text(
                    node.packet.nodeId,
                    style: const TextStyle(
                      fontFamily: 'Barlow',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Node ${node.packet.nodeId}',
                        style: const TextStyle(
                          fontFamily: 'Barlow',
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: agosTextPrimary,
                        ),
                      ),
                      Text(
                        '${isDemo ? 'Simulated reception' : 'Last received'} $elapsed',
                        style: const TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 12,
                          color: agosMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  current ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: current ? agosOnlineGreen : agosWarningAmber,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              node.fixLabel(now),
              style: const TextStyle(
                fontFamily: 'Barlow',
                fontWeight: FontWeight.w600,
                color: agosTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              current
                  ? '${node.packet.latitude!.toStringAsFixed(6)}, ${node.packet.longitude!.toStringAsFixed(6)}'
                  : 'Current position unavailable',
              style: const TextStyle(
                fontFamily: 'Barlow',
                color: agosMutedText,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 6,
              children: [
                Text(
                  'RSSI ${node.rssiDbm == null ? '—' : '${node.rssiDbm} dBm'}',
                  style: const TextStyle(
                    fontFamily: 'Barlow',
                    fontSize: 12,
                    color: agosMutedText,
                  ),
                ),
                Text(
                  'SNR ${node.snrDb == null ? '—' : '${node.snrDb!.toStringAsFixed(1)} dB'}',
                  style: const TextStyle(
                    fontFamily: 'Barlow',
                    fontSize: 12,
                    color: agosMutedText,
                  ),
                ),
                Text(
                  'Satellites ${node.packet.satellites ?? '—'}',
                  style: const TextStyle(
                    fontFamily: 'Barlow',
                    fontSize: 12,
                    color: agosMutedText,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Priority not reported',
                  style: TextStyle(
                    fontFamily: 'Barlow',
                    fontSize: 12,
                    color: agosLabelMuted,
                  ),
                ),
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: agosSurface,
                    isScrollControlled: true,
                    builder: (context) => SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Node ${node.packet.nodeId} · packet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            SelectableText(
                              node.packet.raw,
                              style: const TextStyle(
                                color: agosOnlineGreen,
                                fontFamily: 'Barlow',
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Coordinates in the packet are the sender’s last report. GPS age and time since reception determine whether they are still current.',
                              style: TextStyle(color: agosMutedText),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: const Text('View packet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
