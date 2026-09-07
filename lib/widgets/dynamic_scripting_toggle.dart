import 'package:flutter/material.dart';
import '../services/scripting_settings.dart';

class DynamicScriptingToggle extends StatelessWidget {
  final bool isCompact;
  final EdgeInsetsGeometry? margin;

  const DynamicScriptingToggle({
    super.key,
    this.isCompact = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final settings = ScriptingSettings();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final isEnabled = settings.isDynamicScriptingEnabled;

        if (isCompact) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEnabled ? Icons.auto_awesome : Icons.subtitles_off_outlined,
                  size: 20,
                  color: isEnabled ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 4),
                Switch(
                  value: isEnabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.indigo.shade300,
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.white24,
                  onChanged: (val) {
                    settings.toggleDynamicScripting(val);
                  },
                ),
              ],
            ),
          );
        }

        return Card(
          elevation: 3,
          margin: margin ?? const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isEnabled ? Colors.indigo.shade50 : Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isEnabled ? Icons.auto_awesome : Icons.subtitles_off_outlined,
                        color: isEnabled ? Colors.indigo : Colors.grey.shade600,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Dynamic Scripting (AI)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isEnabled
                                    ? Colors.indigo.shade900
                                    : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEnabled
                                  ? 'AI-personalized POI narration'
                                  : 'Standard pre-recorded narration',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isEnabled,
                  activeThumbColor: Colors.indigo,
                  activeTrackColor: Colors.indigo.shade200,
                  onChanged: (val) {
                    settings.toggleDynamicScripting(val);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}