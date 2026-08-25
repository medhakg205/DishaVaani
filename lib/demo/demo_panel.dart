import 'package:flutter/material.dart';
import 'demo_controller.dart';

class DemoPanel extends StatelessWidget {
  final DemoController controller;

  const DemoPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final demo = controller.demoMode;
        final auto = controller.autoPlay;

        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune),
                    SizedBox(width: 8),
                    Text(
                      'Demo Simulation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Demo Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: demo,
                      onChanged: controller.setDemoMode,
                    ),
                  ],
                ),

                Text(
                  demo
                      ? 'Manual simulation enabled'
                      : 'Real phone compass enabled',
                  style: TextStyle(
                    color: demo ? Colors.orange : Colors.green,
                    fontSize: 13,
                  ),
                ),

                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Compass Heading',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${controller.heading.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Slider(
                  min: 0,
                  max: 360,
                  divisions: 360,
                  value: controller.heading.clamp(0.0, 360.0),
                  onChanged: demo && !auto
                      ? controller.setHeading
                      : null,
                ),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0°'),
                    Text('90°'),
                    Text('180°'),
                    Text('270°'),
                    Text('360°'),
                  ],
                ),

                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: demo
                        ? Colors.orange.withValues(alpha: 0.10)
                        : Colors.green.withValues(alpha: 0.10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        demo
                            ? Icons.gamepad
                            : Icons.explore,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          demo
                              ? auto
                                  ? 'Auto Play is controlling the heading'
                                  : 'Move the slider to change heading'
                              : 'Rotate the phone to change heading',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Mock Coordinates',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Latitude: '
                  '${controller.latitude.toStringAsFixed(4)}',
                ),

                Text(
                  'Longitude: '
                  '${controller.longitude.toStringAsFixed(4)}',
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: demo
                            ? controller.toggleAutoPlay
                            : null,
                        icon: Icon(
                          auto
                              ? Icons.stop
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          auto ? 'Stop Auto Play' : 'Auto Play',
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    OutlinedButton.icon(
                      onPressed: controller.reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
