import 'package:material_ui/material_ui.dart';

import '../../data/gateway_client.dart';
import '../../ui/agos_colors.dart';
import '../monitor/monitor_controller.dart';

class GatewayScreen extends StatefulWidget {
  const GatewayScreen({super.key, required this.controller});
  final MonitorController controller;
  @override
  State<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends State<GatewayScreen> {
  final _form = GlobalKey<FormState>();
  late final _address = TextEditingController(
    text: widget.controller.gateway.toString(),
  );
  bool _working = false;

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
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
        ? agosWarningAmber
        : switch (controller.status) {
            GatewayStatus.disconnected => agosLabelMuted,
            GatewayStatus.connecting => agosWarningAmber,
            GatewayStatus.connected => agosOnlineGreen,
            GatewayStatus.error => agosAlertRed,
          };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SETTINGS',
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
                'Local gateway connection and offline Cebu map configuration.',
                style: TextStyle(fontFamily: 'Barlow', color: agosMutedText),
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
                              style: const TextStyle(
                                fontFamily: 'Barlow',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: agosTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '1. Join the gateway’s Wi-Fi in your phone settings.\n2. Enter its address below and connect.',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          height: 1.7,
                          color: agosMutedText,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: _form,
                        child: TextFormField(
                          controller: _address,
                          enabled: !_working,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          style: const TextStyle(color: agosTextPrimary),
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
                      const Text(
                        'No internet connection is needed. The app does not change your phone’s Wi-Fi automatically.',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 12,
                          color: agosLabelMuted,
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
                      const Text(
                        'Explore before connecting',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: agosTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Demo mode uses simulated readings and keeps them separate from saved gateway data.',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          height: 1.5,
                          color: agosMutedText,
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
                    children: const [
                      Text(
                        'Offline map pack',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: agosTextPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Cebu, Philippines & surrounding straits (bundled locally for offline use, zooms 7–13 with overzoom to 15.5).',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 13,
                          height: 1.5,
                          color: agosMutedText,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Map data attribution: Esri, HERE, Garmin, OpenStreetMap contributors, GIS User Community.',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 11.5,
                          color: agosLabelMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'AGOS research prototype · Gateway firmware integration is still in development.',
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 12,
                  height: 1.5,
                  color: agosLabelMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
