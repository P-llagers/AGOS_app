import 'package:flutter/material.dart';

import '../../ui/agos_colors.dart';
import '../../data/gateway_client.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gateway',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: agosNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your local link to the rescue network.',
                style: TextStyle(color: Color(0xFF5B707C)),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.router_outlined, color: agosTeal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '1. Join the gateway’s Wi-Fi in your phone settings.\n2. Enter its address below and connect.',
                        style: TextStyle(height: 1.7),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _form,
                        child: TextFormField(
                          controller: _address,
                          enabled: !_working,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
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
                          fontSize: 12,
                          color: Color(0xFF5B707C),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explore before connecting',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Demo mode uses simulated readings and keeps them separate from saved gateway data.',
                        style: TextStyle(height: 1.5),
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
              const SizedBox(height: 20),
              const Text(
                'AGOS research prototype · Gateway firmware integration is still in development.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xFF5B707C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
