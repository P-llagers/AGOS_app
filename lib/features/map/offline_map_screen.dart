import 'package:flutter/material.dart';

import '../../ui/agos_colors.dart';
import '../monitor/monitor_controller.dart';

class OfflineMapScreen extends StatelessWidget {
  const OfflineMapScreen({super.key, required this.controller});
  final MonitorController controller;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F2F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    size: 64,
                    color: agosTeal,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Offline map',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: agosNavy,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Map data has not been added yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Node readings are available in Monitor. This view will show survivor positions once an offline map is installed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.6, color: Color(0xFF5B707C)),
                ),
                const SizedBox(height: 24),
                Chip(
                  avatar: const Icon(Icons.gps_fixed, size: 17),
                  label: Text(
                    '${controller.currentFixCount} current GPS ${controller.currentFixCount == 1 ? 'fix' : 'fixes'}',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Distance and bearing are not available yet.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
