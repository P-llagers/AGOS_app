import 'package:material_ui/material_ui.dart';

import '../../models/node_observation.dart';
import '../../ui/agos_colors.dart';
import 'monitor_controller.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({
    super.key,
    required this.controller,
    required this.onGateway,
  });
  final MonitorController controller;
  final VoidCallback onGateway;

  @override
  Widget build(BuildContext context) {
    final nodes = [...controller.nodes]
      ..sort((a, b) => a.packet.nodeId.compareTo(b.packet.nodeId));
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
                      _feedLabel,
                      style: const TextStyle(
                        fontFamily: 'Barlow',
                        color: agosMutedText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onGateway,
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
                      now: controller.now,
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
            ],
          ),
        ),
      ),
    );
  }

  String get _feedLabel {
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
      GatewayStatus.error => 'Gateway feed interrupted. Previously received readings remain visible.',
      GatewayStatus.disconnected => 'An offline view of your rescue network. Connect a gateway to start receiving readings.',
    };
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
