// point_detect_screen.dart — screen 3: live compass + auto POI detection + playback
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../models/poi.dart';
import '../services/matching_engine.dart';
import '../services/poi_service.dart';
import '../services/sensor_service.dart';
import '../services/translation_service.dart';
import '../widgets/compass_needle.dart';
import '../widgets/volume_button.dart';
import 'now_playing_screen.dart';

class PointDetectScreen extends StatefulWidget {
  final String monumentId;
  const PointDetectScreen({super.key, required this.monumentId});

  @override
  State<PointDetectScreen> createState() => _PointDetectScreenState();
}

class _PointDetectScreenState extends State<PointDetectScreen> {
  double heading = 0;
  double? lat;
  double? long;
  String? _autoPlayedPoiId;

  final SensorService _sensorService = SensorService();
  StreamSubscription<SensorReading>? _sensorSub;
  final PoiService _poiService = PoiService();
  List<Poi> _monumentPois = [];

  final AudioPlayer _audioPlayer = AudioPlayer();
  final TranslationService _translationService = TranslationService();
  bool isPlaying = false;
  bool isResolvingAudio = false;
  String? _playingPoiId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<Poi> _inRangePois = [];
  Poi? get _topPoi => _inRangePois.isNotEmpty ? _inRangePois.first : null;

  @override
  void initState() {
    super.initState();
    _loadPois();
    _startSensors();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => isPlaying = state == PlayerState.playing);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        isPlaying = false;
        _position = Duration.zero;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });
  }

  Future<void> _loadPois() async {
    try {
      final pois = await _poiService.fetchPoisByMonument(widget.monumentId);
      if (!mounted) return;

      setState(() => _monumentPois = pois);

      if (lat != null && long != null) {
        _updateDetection(lat!, long!, heading);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load POIs: $error')),
      );
    }
  }

  Future<void> _startSensors() async {
    try {
      await _sensorService.start();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start sensors: $error')),
      );
      return;
    }

    _sensorSub = _sensorService.readings.listen((reading) async {
      if (!mounted) return;

      Poi? detectedPoi;

      if (_monumentPois.isNotEmpty) {
        final result = runMatchingEngine(reading.lat, reading.long, reading.heading, _monumentPois);
        detectedPoi = result.singleMatch ?? (result.queue.isNotEmpty ? result.queue.first : null);

        setState(() {
          heading = reading.heading;
          lat = reading.lat;
          long = reading.long;
          _inRangePois = detectedPoi != null ? [detectedPoi] : [];
        });
      } else {
        setState(() {
          heading = reading.heading;
          lat = reading.lat;
          long = reading.long;
          _inRangePois = [];
        });
      }

      if (detectedPoi != null && detectedPoi.id != _autoPlayedPoiId) {
        _autoPlayedPoiId = detectedPoi.id;
        await _togglePlayback(detectedPoi);
      }
    });
  }

  Future<String?> _resolveAudioUrl(Poi poi) async {
    final lang = AppSettings.selectedLanguage;

    final existingUrl = poi.audioUrls[lang];
    if (existingUrl != null && existingUrl.trim().isNotEmpty) {
      return existingUrl;
    }

    final englishScript = poi.getScript('en');
    if (englishScript.isEmpty) return null;

    setState(() => isResolvingAudio = true);

    try {
      final newUrl = await _translationService.getTranslatedAudioUrl(
        poiId: poi.id,
        sourceScript: englishScript,
        sourceLang: 'en',
        targetLanguage: lang,
      );
      poi.audioUrls[lang] = newUrl;
      return newUrl;
    } catch (e) {
      debugPrint('Translation call failed: $e');
      return null;
    } finally {
      if (mounted) setState(() => isResolvingAudio = false);
    }
  }

  void _updateDetection(double userLat, double userLong, double userHeading) {
    if (_monumentPois.isEmpty) {
      if (mounted) setState(() => _inRangePois = []);
      return;
    }

    final result = runMatchingEngine(userLat, userLong, userHeading, _monumentPois);

    if (!mounted) return;
    setState(() => _inRangePois = result.singleMatch != null ? [result.singleMatch!] : result.queue);
  }

  Future<void> _togglePlayback(Poi poi) async {
    if (isPlaying && _playingPoiId == poi.id) {
      await _audioPlayer.pause();
      return;
    }

    final audioUrl = await _resolveAudioUrl(poi);
    if (audioUrl == null || audioUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio available in this language yet.')),
      );
      return;
    }

    try {
      _playingPoiId = poi.id;
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (error) {
      if (!mounted) return;
      setState(() => isPlaying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not play audio: $error')));
    }
  }

  Future<void> _seekBy(Duration delta) async {
    final maxMs = _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0;
    final newMs = (_position.inMilliseconds + delta.inMilliseconds).clamp(0, maxMs);
    final newPosition = Duration(milliseconds: newMs);
    setState(() => _position = newPosition);
    await _audioPlayer.seek(newPosition);
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _sensorService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _monumentName(String monumentId) {
    return monumentId
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _headingLabel(double heading) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((heading % 360) / 22.5).round() % 16;
    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    final topPoi = _topPoi;
    final radians = heading * 3.141592653589793 / 180;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.maroon,
        elevation: 4,
        leading: IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        title: const Text('DishaVaani', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                children: [
                  Text(_monumentName(widget.monumentId), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.maroon)),
                  const SizedBox(height: 4),
                  Text(
                    lat != null && long != null ? '${lat!.toStringAsFixed(4)}° N, ${long!.toStringAsFixed(4)}° E' : 'Waiting for GPS...',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: topPoi != null ? AppColors.terracotta.withOpacity(0.12) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(topPoi != null ? Icons.radar : Icons.search, size: 15, color: topPoi != null ? AppColors.terracotta : Colors.black45),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      topPoi != null ? 'POI detected — ${topPoi.name}' : 'Scanning for nearby POIs...',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: topPoi != null ? AppColors.terracotta : Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('${heading.toInt()}° ${_headingLabel(heading)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.maroon)),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: -radians,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.terracotta, width: 3)),
                            ),
                            const Positioned(top: 6, child: CompassLabel('N')),
                            const Positioned(bottom: 6, child: CompassLabel('S')),
                            const Positioned(left: 6, child: CompassLabel('W')),
                            const Positioned(right: 6, child: CompassLabel('E')),
                          ],
                        ),
                      ),
                      const CompassNeedle(size: 90),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.terracotta, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.temple_hindu, color: AppColors.maroon, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Now approaching', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                  Text(
                                    topPoi?.name ?? 'Nothing playing yet',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.maroon),
                                  ),
                                ],
                              ),
                            ),
                            VolumeButton(audioPlayer: _audioPlayer),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_5, color: AppColors.terracotta),
                                iconSize: 26,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _seekBy(const Duration(seconds: -5)),
                              ),
                              const SizedBox(width: 18),
                              GestureDetector(
                                onTap: topPoi == null || isResolvingAudio ? null : () => _togglePlayback(topPoi),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(color: AppColors.maroon, shape: BoxShape.circle),
                                  child: isResolvingAudio
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                        )
                                      : Icon(isPlaying && _playingPoiId == topPoi?.id ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 24),
                                ),
                              ),
                              const SizedBox(width: 18),
                              IconButton(
                                icon: const Icon(Icons.forward_5, color: AppColors.terracotta),
                                iconSize: 26,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _seekBy(const Duration(seconds: 5)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                            activeTrackColor: AppColors.terracotta,
                            inactiveTrackColor: AppColors.sandstone,
                            thumbColor: AppColors.terracotta,
                          ),
                          child: Slider(
                            min: 0,
                            max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1,
                            value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1).toDouble(),
                            onChanged: (value) => setState(() => _position = Duration(milliseconds: value.toInt())),
                            onChangeEnd: (value) async => _audioPlayer.seek(Duration(milliseconds: value.toInt())),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_position), style: const TextStyle(fontSize: 10, color: Colors.black45)),
                              Text(_formatDuration(_duration), style: const TextStyle(fontSize: 10, color: Colors.black45)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () async {
                if (isPlaying) await _audioPlayer.pause();
                if (!context.mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NowPlayingScreen(monumentId: widget.monumentId, initialPois: _inRangePois.isNotEmpty ? _inRangePois : null),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _inRangePois.length > 1 ? 'View ${_inRangePois.length} nearby' : 'View manual list',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_up, size: 16, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}