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

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: margin ?? const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isDark
                ? (isEnabled ? const Color(0xFF2A1C24) : const Color(0xFF221A20))
                : (isEnabled ? const Color(0xFFFFF7F2) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled
                  ? (isDark
                      ? const Color(0xFFE5A17D).withOpacity(0.4)
                      : const Color(0xFFC1652F).withOpacity(0.35))
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE5D8CF)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? (isDark
                                ? const Color(0xFFE5A17D).withOpacity(0.18)
                                : const Color(0xFFC1652F).withOpacity(0.12))
                            : (isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.04)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEnabled
                            ? Icons.auto_awesome_rounded
                            : Icons.subtitles_off_rounded,
                        color: isEnabled
                            ? (isDark
                                ? const Color(0xFFE5A17D)
                                : const Color(0xFFC1652F))
                            : (isDark ? Colors.white38 : Colors.grey.shade500),
                        size: 20,
                      ),
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
                              fontFamily: 'serif',
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : const Color(0xFF2B1E22),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEnabled
                                ? 'AI-personalized POI narration'
                                : 'Standard pre-recorded narration',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withOpacity(0.55)
                                  : Colors.grey.shade700,
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
                activeThumbColor: Colors.white,
                activeTrackColor: isDark ? const Color(0xFFE5A17D) : const Color(0xFFC1652F),
                inactiveThumbColor: isDark ? Colors.white38 : Colors.grey.shade400,
                inactiveTrackColor: isDark ? Colors.white12 : Colors.grey.shade200,
                onChanged: (val) {
                  settings.toggleDynamicScripting(val);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}