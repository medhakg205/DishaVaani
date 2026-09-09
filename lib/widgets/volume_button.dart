// volume_button.dart — speaker icon that pops a floating volume slider
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class VolumeButton extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final bool isDark;
  const VolumeButton({
    super.key,
    required this.audioPlayer,
    this.isDark = false,
  });

  @override
  State<VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends State<VolumeButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  double _volume = 1.0;

  void _toggleSlider() {
    if (_overlayEntry != null) {
      _closeSlider();
    } else {
      _openSlider();
    }
  }

  void _openSlider() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeSlider,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.bottomRight,
            offset: const Offset(0, -8),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              child: Container(
                width: 160,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF231D21) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.12)
                        : AppColors.terracotta.withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDark ? Colors.black54 : Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: StatefulBuilder(
                  builder: (context, setPopupState) {
                    return Row(
                      children: [
                        Icon(
                          Icons.volume_down,
                          size: 14,
                          color: widget.isDark ? Colors.white38 : Colors.black45,
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                              activeTrackColor: const Color(0xFFE5A17D),
                              inactiveTrackColor: widget.isDark
                                  ? Colors.white24
                                  : AppColors.sandstone,
                              thumbColor: const Color(0xFFE5A17D),
                            ),
                            child: Slider(
                              min: 0,
                              max: 1,
                              value: _volume,
                              onChanged: (value) {
                                setPopupState(() => _volume = value);
                                setState(() {});
                                widget.audioPlayer.setVolume(value);
                              },
                            ),
                          ),
                        ),
                        Icon(
                          Icons.volume_up,
                          size: 14,
                          color: widget.isDark
                              ? const Color(0xFFE5A17D)
                              : AppColors.terracotta,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  void _closeSlider() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {});
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        icon: Icon(
          _volume == 0 ? Icons.volume_off : Icons.volume_up,
          color: widget.isDark ? const Color(0xFFE5A17D) : AppColors.terracotta,
        ),
        onPressed: _toggleSlider,
        splashRadius: 20,
      ),
    );
  }
}
