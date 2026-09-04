// now_playing_screen.dart — screen 4: current POI + live heading-ranked queue
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../models/poi.dart';
import '../services/poi_service.dart';
import '../services/sensor_service.dart';
import '../services/translation_service.dart';
import '../widgets/volume_button.dart';
import 'manual_poi_list_screen.dart';

class NowPlayingScreen extends StatefulWidget {
  final String monumentId;
  final List<Poi>? initialPois;

  const NowPlayingScreen({
    super.key,
    this.monumentId = 'qutub_minar',
    this.initialPois,
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final PoiService _poiService = PoiService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final SensorService _sensorService = SensorService();
  StreamSubscription<SensorReading>? _sensorSub;

  bool isPlaying = false;
  bool isLoading = true;
  bool isResolvingAudio = false;
  String? errorMessage;

  Poi? currentPoi;
  List<Poi> queue = [];
  List<Poi> _allPois = [];

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  double heading =
      214.0; // fallback until the first real sensor reading arrives

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => isPlaying = state == PlayerState.playing);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => isPlaying = false);
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      if (!mounted) return;
      setState(() => _duration = dur);
    });

    _loadPois();
    _startSensors();
  }

  Future<void> _startSensors() async {
    try {
      await _sensorService.start();
      _sensorSub = _sensorService.readings.listen((reading) {
        if (!mounted) return;
        setState(() => heading = reading.heading);
        _rerankQueue();
      });
    } catch (e) {
      debugPrint('NowPlayingScreen: sensors unavailable: $e');
    }
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _sensorService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPois() async {
    if (widget.initialPois != null) {
      _allPois = List<Poi>.from(widget.initialPois!);

      if (_allPois.isEmpty) {
        setState(() {
          currentPoi = null;
          queue = [];
          isLoading = false;
        });
        return;
      }

      setState(() {
        currentPoi = _allPois.first;
        queue = _allPois.skip(1).toList();
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final pois = await _poiService.fetchPoisByMonument(widget.monumentId);
      if (!mounted) return;

      _allPois = List<Poi>.from(pois);

      if (_allPois.isEmpty) {
        setState(() {
          currentPoi = null;
          queue = [];
          isLoading = false;
        });
        return;
      }

      currentPoi = _allPois.first;
      _rerankQueue();

      setState(() => isLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  double _virtualBearing(Poi poi, int index) {
    var hash = 0;
    for (final codeUnit in poi.id.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return ((hash + index * 47) % 360).toDouble();
  }

  double _angleDifference(double a, double b) {
    var diff = (a - b).abs() % 360;
    if (diff > 180) diff = 360 - diff;
    return diff;
  }

  void _rerankQueue({bool autoPlayChangedItem = false}) {
    if (_allPois.isEmpty) return;

    final selectedId = currentPoi?.id;
    final candidates = _allPois.where((poi) => poi.id != selectedId).toList();

    candidates.sort((a, b) {
      final ia = _allPois.indexOf(a);
      final ib = _allPois.indexOf(b);
      final scoreA = _angleDifference(heading, _virtualBearing(a, ia));
      final scoreB = _angleDifference(heading, _virtualBearing(b, ib));
      return scoreA.compareTo(scoreB);
    });

    final oldFirst = queue.isNotEmpty ? queue.first.id : null;

    if (!mounted) return;
    setState(() => queue = candidates);

    if (autoPlayChangedItem && queue.isNotEmpty && queue.first.id != oldFirst) {
      _playPoi(queue.first);
    }
  }

  Future<void> _playPoi(Poi poi) async {
    String audioUrl = poi.getAudioUrl(AppSettings.selectedLanguage).trim();

    if (AppSettings.selectedLanguage != 'en' &&
        !poi.audioUrls.containsKey(AppSettings.selectedLanguage)) {
      try {
        audioUrl = await TranslationService().getTranslatedAudioUrl(
          poiId: poi.id,
          sourceScript: poi.getScript('en'),
          sourceLang: 'en',
          targetLanguage: AppSettings.selectedLanguage,
          interestProfile: AppSettings.interestProfile,
        );
        poi.audioUrls[AppSettings.selectedLanguage] = audioUrl;
      } catch (e) {
        debugPrint('Translation failed: $e');
      }
    }

    if (audioUrl.isEmpty) return;

    try {
      await _audioPlayer.stop();
      setState(() {
        _position = Duration.zero;
        _duration = Duration.zero;
      });
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (_) {}
  }

  Future<void> _togglePlayback(Poi poi) async {
    String audioUrl = poi.getAudioUrl(AppSettings.selectedLanguage).trim();

    if (AppSettings.selectedLanguage != 'en' &&
        !poi.audioUrls.containsKey(AppSettings.selectedLanguage)) {
      setState(() => isResolvingAudio = true);
      try {
        audioUrl = await TranslationService().getTranslatedAudioUrl(
          poiId: poi.id,
          sourceScript: poi.getScript('en'),
          sourceLang: 'en',
          targetLanguage: AppSettings.selectedLanguage,
          interestProfile: AppSettings.interestProfile,
        );
        poi.audioUrls[AppSettings.selectedLanguage] = audioUrl;
      } catch (e) {
        debugPrint('Translation failed: $e');
      } finally {
        if (mounted) setState(() => isResolvingAudio = false);
      }
    }

    if (audioUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No audio URL is available for this POI.'),
        ),
      );
      return;
    }

    try {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => isPlaying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not play audio: $error')));
    }
  }

  Future<void> _seekBy(Duration delta) async {
    final maxMs = _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0;
    final newMs = (_position.inMilliseconds + delta.inMilliseconds).clamp(
      0,
      maxMs,
    );
    final newPosition = Duration(milliseconds: newMs);
    setState(() => _position = newPosition);
    await _audioPlayer.seek(newPosition);
  }

  Future<void> _selectPoi(Poi poi) async {
    await _audioPlayer.stop();
    if (!mounted) return;

    setState(() {
      currentPoi = poi;
      isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    _rerankQueue();
    await _playPoi(poi);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: _appBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: AppColors.terracotta,
                  size: 54,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Could not load POIs from Firebase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.maroon,
                  ),
                ),
                const SizedBox(height: 10),
                Text(errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadPois,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (currentPoi == null) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(
          child: Text('No POIs were found in the Firestore collection "pois".'),
        ),
      );
    }

    final poi = currentPoi!;

    return Scaffold(
      appBar: _appBar(
        onListPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManualPoiListScreen(
                pois: [poi, ...queue],
                onPoiSelected: _selectPoi,
              ),
            ),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _nowPlayingCard(poi),
            const SizedBox(height: 18),
            const Text(
              'UP NEXT (live ranked by heading)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: queue.isEmpty
                  ? const Center(
                      child: Text('No other POIs are currently in the queue.'),
                    )
                  : ListView.separated(
                      itemCount: queue.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final queuedPoi = queue[index];
                        final bearing = _virtualBearing(
                          queuedPoi,
                          _allPois.indexOf(queuedPoi),
                        );
                        final angle = _angleDifference(heading, bearing);

                        return InkWell(
                          onTap: () => _selectPoi(queuedPoi),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? AppColors.gold.withOpacity(0.18)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: index == 0
                                    ? AppColors.terracotta
                                    : Colors.black12,
                                width: index == 0 ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.sandstone,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.maroon,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        queuedPoi.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Bearing ${bearing.toInt()}°  •  ${angle.toInt()}° away',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      if (queuedPoi
                                          .getScript(
                                            AppSettings.selectedLanguage,
                                          )
                                          .isNotEmpty)
                                        Text(
                                          queuedPoi.getScript(
                                            AppSettings.selectedLanguage,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                index == 0
                                    ? VolumeButton(audioPlayer: _audioPlayer)
                                    : const Icon(
                                        Icons.play_arrow,
                                        color: AppColors.terracotta,
                                      ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _appBar({VoidCallback? onListPressed}) {
    return AppBar(
      backgroundColor: AppColors.maroon,
      title: const Text('DishaVaani', style: TextStyle(color: Colors.white)),
      actions: [
        if (onListPressed != null)
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: onListPressed,
          ),
      ],
    );
  }

  Widget _nowPlayingCard(Poi poi) {
    final isCurrentPlaying = isPlaying;
    final script = poi.getScript(AppSettings.selectedLanguage).isNotEmpty
        ? poi.getScript(AppSettings.selectedLanguage)
        : poi.getScript('en');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.terracotta, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.temple_hindu,
                  color: AppColors.maroon,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      script.isNotEmpty
                          ? script
                          : 'Description not available yet.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: script.isNotEmpty
                            ? Colors.black54
                            : Colors.black45,
                        fontStyle: script.isNotEmpty
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.replay_5,
                      color: AppColors.terracotta,
                    ),
                    iconSize: 26,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _seekBy(const Duration(seconds: -5)),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: isResolvingAudio ? null : () => _togglePlayback(poi),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.maroon,
                        shape: BoxShape.circle,
                      ),
                      child: isResolvingAudio
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isCurrentPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 26,
                            ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(
                      Icons.forward_5,
                      color: AppColors.terracotta,
                    ),
                    iconSize: 26,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _seekBy(const Duration(seconds: 5)),
                  ),
                ],
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.terracotta,
              inactiveTrackColor: AppColors.sandstone,
              thumbColor: AppColors.terracotta,
            ),
            child: Slider(
              min: 0,
              max: _duration.inMilliseconds > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1,
              value: _position.inMilliseconds
                  .clamp(
                    0,
                    _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1,
                  )
                  .toDouble(),
              onChanged: (value) => setState(
                () => _position = Duration(milliseconds: value.toInt()),
              ),
              onChangeEnd: (value) async =>
                  _audioPlayer.seek(Duration(milliseconds: value.toInt())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
