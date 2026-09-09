// point_detect.dart — screen 3: live compass + auto POI detection + playback
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../models/poi.dart';
import '../services/matching_engine.dart';
import '../services/poi.dart';
import '../services/sensor.dart';
import '../services/translation.dart';
import '../widgets/compass_needle.dart';
import '../widgets/theme_mode_toggle.dart';
import '../widgets/volume_button.dart';
import 'now_playing.dart';
import '../services/device_identity.dart';
import '../services/profile_store.dart';
import '../services/scripting_settings.dart';
import '../widgets/dynamic_scripting_toggle.dart';


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
  final Map<String, String> _dynamicAudioCache = {};
  bool isPlaying = false;
  bool isResolvingAudio = false;
  bool _hasSensorPermission = false;
  bool _isRequestingSensorPermission = false;
  String? _playingPoiId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<Poi> _inRangePois = [];
  Poi? get _topPoi => _inRangePois.isNotEmpty ? _inRangePois.first : null;

  @override
  void initState() {
    super.initState();
    _loadPois();

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not load POIs: $error')));
    }
  }

  Future<bool> _startSensors() async {
    try {
      await _sensorService.start();
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start sensors: $error')),
      );
      return false;
    }

    _sensorSub = _sensorService.readings.listen((reading) async {
      if (!mounted) return;

      Poi? detectedPoi;

      if (_monumentPois.isNotEmpty) {
        final result = runMatchingEngine(
          reading.lat,
          reading.long,
          reading.heading,
          _monumentPois,
        );
        detectedPoi =
            result.singleMatch ??
            (result.queue.isNotEmpty ? result.queue.first : null);

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
        final deviceId = await DeviceIdentity.getId();
        onPoiDetected(detectedPoi.id, deviceId);
        await _togglePlayback(detectedPoi);
      }
    });
    return true;
  }

  Future<void> _requestSensorPermission() async {
    setState(() => _isRequestingSensorPermission = true);
    try {
      final started = await _startSensors();
      if (mounted && started) setState(() => _hasSensorPermission = true);
    } finally {
      if (mounted) setState(() => _isRequestingSensorPermission = false);
    }
  }

  Future<String?> _resolveAudioUrl(Poi poi) async {
    final lang = AppSettings.selectedLanguage;
    final isDynamic = ScriptingSettings().isDynamicScriptingEnabled;

    if (!isDynamic) {
      print(
        '[Scripting Engine] ⏸ Dynamic scripting disabled: Serving read-aloud TTS narration for POI: ${poi.id} ($lang)',
      );
      final readAloudCacheKey = '${poi.id}_${lang}_read_aloud';
      if (_dynamicAudioCache.containsKey(readAloudCacheKey)) {
        print('[Scripting Engine] 💾 Serving read-aloud from in-memory session cache');
        return _dynamicAudioCache[readAloudCacheKey];
      }

      final cachedReadAloud = poi.getReadAloudUrl(lang);
      if (cachedReadAloud.isNotEmpty) {
        print('[Scripting Engine] 💾 Serving read-aloud from POI cache: $cachedReadAloud');
        _dynamicAudioCache[readAloudCacheKey] = cachedReadAloud;
        return cachedReadAloud;
      }

      final englishScript = poi.getScript('en');
      if (englishScript.isNotEmpty) {
        setState(() => isResolvingAudio = true);
        try {
          final newUrl = await _translationService.getTranslatedAudioUrl(
            poiId: poi.id,
            sourceScript: englishScript,
            sourceLang: 'en',
            targetLanguage: lang,
            interestProfile: null,
            readAloud: true,
            onScriptResolved: (script) {
              poi.scripts[lang] = script;
            },
          );
          print('[Scripting Engine] ✅ Read-aloud TTS resolved: $newUrl');
          _dynamicAudioCache[readAloudCacheKey] = newUrl;
          poi.readAloudUrls[lang] = newUrl;
          return newUrl;
        } catch (e) {
          print('[Scripting Engine] ⚠️ Read-aloud failed: $e, falling back to static audio');
        } finally {
          if (mounted) setState(() => isResolvingAudio = false);
        }
      }

      final staticUrl = poi.audioUrls[lang] ?? poi.audioUrls['en'];
      if (staticUrl != null && staticUrl.trim().isNotEmpty) {
        return staticUrl;
      }
      return null;
    }

    print(
      '[Scripting Engine] ⚡ Dynamic scripting enabled: requesting AI narration for POI: ${poi.id}',
    );

    // If dynamic audio was already generated in this session, return it from memory
    final cacheKey = '${poi.id}_$lang';
    if (_dynamicAudioCache.containsKey(cacheKey)) {
      print('[Scripting Engine] 💾 Serving from in-memory session cache for $cacheKey');
      return _dynamicAudioCache[cacheKey];
    }

    final englishScript = poi.getScript('en');
    if (englishScript.isEmpty) {
      print('[Scripting Engine] ⚠️ English source script is empty for POI: ${poi.id}');
      return null;
    }

    setState(() => isResolvingAudio = true);

    try {
      final profile = await ProfileStore().loadProfile();
      final profileMap = profile.weights.isNotEmpty ? profile.toJson() : null;
      print('[Scripting Engine] 👤 Loaded user interest profile: $profileMap');

      final newUrl = await _translationService.getTranslatedAudioUrl(
        poiId: poi.id,
        sourceScript: englishScript,
        sourceLang: 'en',
        targetLanguage: lang,
        interestProfile: profileMap,
        onScriptResolved: (script) {
          print('[Scripting Engine] 📝 Received personalized script: $script');
          poi.scripts[lang] = script;
        },
      );
      print('[Scripting Engine] ✅ Dynamic audio resolved: $newUrl');
      _dynamicAudioCache[cacheKey] = newUrl;
      poi.audioUrls[lang] = newUrl;
      return newUrl;
    } catch (e) {
      print('[Scripting Engine] ❌ Translation/personalization failed: $e');
      print('[Scripting Engine] ↩️ Falling back to static audio');
      return poi.audioUrls[lang] ?? poi.audioUrls['en'];
    } finally {
      if (mounted) setState(() => isResolvingAudio = false);
    }
  }

  void _updateDetection(double userLat, double userLong, double userHeading) {
    if (_monumentPois.isEmpty) {
      if (mounted) setState(() => _inRangePois = []);
      return;
    }

    final result = runMatchingEngine(
      userLat,
      userLong,
      userHeading,
      _monumentPois,
    );

    if (!mounted) return;
    setState(
      () => _inRangePois = result.singleMatch != null
          ? [result.singleMatch!]
          : result.queue,
    );
  }

  Future<void> _togglePlayback(Poi poi) async {
    if (isPlaying && _playingPoiId == poi.id) {
      await _audioPlayer.pause();
      return;
    }

    final deviceId = await DeviceIdentity.getId();
    onPoiDetected(poi.id, deviceId);

    final audioUrl = await _resolveAudioUrl(poi);
    if (audioUrl == null || audioUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No audio available in this language yet.'),
        ),
      );
      return;
    }

    try {
      _playingPoiId = poi.id;
      await _audioPlayer.play(UrlSource(audioUrl));
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
    const directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    final index = ((heading % 360) / 22.5).round() % 16;
    return directions[index];
  }

  String? _poiAssetPath(Poi poi) {
    final name = poi.name.toLowerCase();
    final id = poi.id.toLowerCase();

    // 1. Specific Qutub Minar POIs
    if (name.contains('wall') || name.contains('carving') || id.contains('carving')) {
      return 'assets/images/qutub_wall_carving.png';
    } else if (name.contains('iron') || id.contains('iron')) {
      return 'assets/images/qutub_iron_pillar.jpg';
    } else if (name.contains('darwaza') || id.contains('darwaza')) {
      return 'assets/images/qutub_alai_darwaza.jpg';
    } else if (name.contains('chirantana') ||
        id.contains('chirantana') ||
        name.contains('quwwat') ||
        id.contains('quwwat') ||
        name.contains('mosque') ||
        id.contains('mosque') ||
        name.contains('room')) {
      return 'assets/images/quwwat_ul_islam.jpg';
    } else if (name.contains('victory') ||
        name.contains('tower') ||
        id.contains('tower') ||
        id == 'qutub_minar_tower') {
      return 'assets/images/qutub_minar_tower.jpg';
    }

    // 2. Other Monument POIs
    if (name.contains('lahori') ||
        id.contains('lahori') ||
        name.contains('diwan') ||
        id.contains('diwan') ||
        name.contains('red fort') ||
        id.contains('red_fort')) {
      return 'assets/images/red_fort_lahori_gate.jpg';
    } else if (name.contains('humayun') ||
        id.contains('humayun') ||
        name.contains('charbagh') ||
        id.contains('charbagh')) {
      return 'assets/images/humayuns_tomb.jpg';
    } else if (name.contains('india gate') ||
        id.contains('india_gate') ||
        name.contains('amar jawan') ||
        id.contains('memorial')) {
      return 'assets/images/india_gate.jpg';
    } else if (name.contains('baoli') ||
        name.contains('baoli') ||
        name.contains('agrasen') ||
        id.contains('agrashan')) {
      return 'assets/images/agrasen_ki_baoli.jpg';
    } else if (name.contains('jama') || id.contains('jama')) {
      return 'assets/images/jama_masjid.jpg';
    }

    // Fallback for any Qutub Minar POI
    if (poi.monumentId.toLowerCase().contains('qutub')) {
      return 'assets/images/qutub_minar_tower.jpg';
    }

    return null;
  }

  Widget _buildPoiThumbnail(Poi? poi, bool isDark) {
    if (poi == null) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF38252C) : AppColors.sandstone,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder,
          ),
        ),
        child: Icon(
          Icons.temple_hindu,
          color: isDark ? const Color(0xFFE5A17D) : AppColors.terracotta,
          size: 24,
        ),
      );
    }

    final asset = _poiAssetPath(poi);
    if (asset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _poiThumbnailFallback(isDark),
          ),
        ),
      );
    }

    return _poiThumbnailFallback(isDark);
  }

  Widget _poiThumbnailFallback(bool isDark) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF38252C) : AppColors.sandstone,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder,
        ),
      ),
      child: Icon(
        Icons.account_balance,
        color: isDark ? const Color(0xFFE5A17D) : AppColors.terracotta,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPoi = _topPoi;
    final radians = heading * 3.141592653589793 / 180;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, _, child) {
        final isDark = AppSettings.isDarkMode;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF141215) : AppColors.lightBgMid,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: isDark ? Colors.white : AppColors.maroon,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.home_outlined,
                color: isDark ? Colors.white : AppColors.maroon,
              ),
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            ),
            title: Text(
              'DishaVaani',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.maroon,
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: const [
              DynamicScriptingToggle(isCompact: true),
              ThemeModeToggle(),
              SizedBox(width: 8),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppColors.darkBgTop,
                        AppColors.darkBgMid,
                        AppColors.darkBgBottom,
                      ]
                    : [
                        AppColors.lightBgTop,
                        AppColors.lightBgMid,
                        AppColors.lightBgBottom,
                      ],
              ),
            ),
            child: SafeArea(
              child: !_hasSensorPermission
                  ? _SensorPermissionPrompt(
                      isRequesting: _isRequestingSensorPermission,
                      onRequest: _requestSensorPermission,
                      isDark: isDark,
                    )
                  : Column(
                      children: [
                        // Monument Name & Location
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                          child: Column(
                            children: [
                              Text(
                                _monumentName(widget.monumentId),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Georgia',
                                  color: isDark ? Colors.white : AppColors.maroon,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: isDark
                                        ? const Color(0xFFE5A17D).withOpacity(0.7)
                                        : AppColors.terracotta,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    lat != null && long != null
                                        ? '${lat!.toStringAsFixed(4)}° N, ${long!.toStringAsFixed(4)}° E'
                                        : 'Waiting for GPS...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.55)
                                          : AppColors.lightTextSecondary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                    // POI Scanning / Detection Pill
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 7,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? (topPoi != null
                                ? const Color(0xFF382229)
                                : const Color(0xFF1E1A1E).withOpacity(0.8))
                            : (topPoi != null
                                ? const Color(0xFFFFF0E6)
                                : Colors.white.withOpacity(0.85)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? (topPoi != null
                                  ? const Color(0xFFE5A17D).withOpacity(0.35)
                                  : Colors.white.withOpacity(0.06))
                              : (topPoi != null
                                  ? AppColors.terracotta.withOpacity(0.4)
                                  : AppColors.lightBorder),
                          width: 1,
                        ),
                        boxShadow: topPoi != null
                            ? [
                                BoxShadow(
                                  color: (isDark
                                          ? const Color(0xFFE5A17D)
                                          : AppColors.terracotta)
                                      .withOpacity(0.15),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            topPoi != null ? Icons.radar : Icons.search,
                            size: 15,
                            color: topPoi != null
                                ? (isDark
                                    ? const Color(0xFFE5A17D)
                                    : AppColors.terracotta)
                                : (isDark ? Colors.white54 : Colors.black45),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              topPoi != null
                                  ? 'POI detected — ${topPoi.name}'
                                  : 'Scanning for nearby POIs...',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: topPoi != null
                                    ? (isDark
                                        ? const Color(0xFFE5A17D)
                                        : AppColors.terracotta)
                                    : (isDark
                                        ? Colors.white60
                                        : AppColors.lightTextSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Heading Value
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${heading.toInt()}°',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _headingLabel(heading),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE5A17D)
                                  : AppColors.terracotta,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Compass Dial
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ambient radial glow
                              Container(
                                width: 230,
                                height: 230,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      (isDark
                                              ? const Color(0xFFE5A17D)
                                              : AppColors.terracotta)
                                          .withOpacity(0.09),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.55, 1.0],
                                  ),
                                ),
                              ),
                              // Rotating Dial
                              Transform.rotate(
                                angle: -radians,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer frosted glass disc
                                    Container(
                                      width: 216,
                                      height: 216,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? const Color(0xFF221A20).withOpacity(0.6)
                                            : Colors.white.withOpacity(0.8),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFFE5A17D).withOpacity(0.35)
                                              : AppColors.terracotta.withOpacity(0.35),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.black.withOpacity(0.35)
                                                : AppColors.terracotta.withOpacity(0.12),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                          BoxShadow(
                                            color: (isDark
                                                    ? const Color(0xFFE5A17D)
                                                    : AppColors.terracotta)
                                                .withOpacity(0.1),
                                            blurRadius: 14,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Inner fine track ring
                                    Container(
                                      width: 172,
                                      height: 172,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.07)
                                              : Colors.black.withOpacity(0.06),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    // 12 Degree Tick marks (every 30 degrees)
                                    ...List.generate(12, (i) {
                                      final deg = i * 30;
                                      if (deg % 90 == 0) return const SizedBox.shrink();
                                      final angleRad = deg * 3.141592653589793 / 180;
                                      return Transform.rotate(
                                        angle: angleRad,
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            width: 1.5,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withOpacity(0.2)
                                                  : Colors.black.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(1),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    Positioned(
                                      top: 10,
                                      child: CompassLabel('N', isDark: isDark),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      child: CompassLabel('S', isDark: isDark),
                                    ),
                                    Positioned(
                                      left: 12,
                                      child: CompassLabel('W', isDark: isDark),
                                    ),
                                    Positioned(
                                      right: 12,
                                      child: CompassLabel('E', isDark: isDark),
                                    ),
                                  ],
                                ),
                              ),
                              CompassNeedle(size: 96, isDark: isDark),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Floating Glass Bottom Player Card
                    GestureDetector(
                      onTap: () async {
                        if (isPlaying) await _audioPlayer.pause();
                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NowPlayingScreen(
                              monumentId: widget.monumentId,
                              initialPois: _monumentPois.isNotEmpty ? _monumentPois : null,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF231D21)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.09)
                                : AppColors.lightBorder,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.4)
                                  : AppColors.terracotta.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildPoiThumbnail(topPoi, isDark),
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
                                            Text(
                                              'NOW APPROACHING',
                                              style: TextStyle(
                                                fontSize: 10,
                                                letterSpacing: 1.1,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? const Color(0xFFE5A17D).withOpacity(0.9)
                                                    : AppColors.terracotta,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              topPoi?.name ?? 'Nothing playing yet',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      VolumeButton(
                                        audioPlayer: _audioPlayer,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.replay_5,
                                            color: isDark
                                                ? const Color(0xFFE5A17D)
                                                : AppColors.terracotta,
                                          ),
                                          iconSize: 26,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _seekBy(const Duration(seconds: -5)),
                                        ),
                                        const SizedBox(width: 18),
                                        GestureDetector(
                                          onTap: topPoi == null || isResolvingAudio
                                              ? null
                                              : () => _togglePlayback(topPoi),
                                          child: Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF752433)
                                                  : AppColors.maroon,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (isDark
                                                          ? const Color(0xFF752433)
                                                          : AppColors.maroon)
                                                      .withOpacity(0.4),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: isResolvingAudio
                                                ? const Padding(
                                                    padding: EdgeInsets.all(13),
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Icon(
                                                    isPlaying && _playingPoiId == topPoi?.id
                                                        ? Icons.pause
                                                        : Icons.play_arrow,
                                                    color: Colors.white,
                                                    size: 26,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        IconButton(
                                          icon: Icon(
                                            Icons.forward_5,
                                            color: isDark
                                                ? const Color(0xFFE5A17D)
                                                : AppColors.terracotta,
                                          ),
                                          iconSize: 26,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _seekBy(const Duration(seconds: 5)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.8,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 5,
                                      ),
                                      overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 10,
                                      ),
                                      activeTrackColor: isDark
                                          ? const Color(0xFFE5A17D)
                                          : AppColors.terracotta,
                                      inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                                      thumbColor: isDark
                                          ? const Color(0xFFE5A17D)
                                          : AppColors.terracotta,
                                    ),
                                    child: Slider(
                                      min: 0,
                                      max: _duration.inMilliseconds > 0
                                          ? _duration.inMilliseconds.toDouble()
                                          : 1,
                                      value: _position.inMilliseconds
                                          .clamp(
                                            0,
                                            _duration.inMilliseconds > 0
                                                ? _duration.inMilliseconds
                                                : 1,
                                          )
                                          .toDouble(),
                                      onChanged: (value) => setState(
                                        () => _position = Duration(
                                          milliseconds: value.toInt(),
                                        ),
                                      ),
                                      onChangeEnd: (value) async => _audioPlayer.seek(
                                        Duration(milliseconds: value.toInt()),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(_position),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark
                                                ? Colors.white.withOpacity(0.5)
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(_duration),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark
                                                ? Colors.white.withOpacity(0.5)
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Navigation Bar
                    InkWell(
                      onTap: () async {
                        if (isPlaying) await _audioPlayer.pause();
                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NowPlayingScreen(
                              monumentId: widget.monumentId,
                              initialPois: _monumentPois.isNotEmpty ? _monumentPois : null,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.25)
                              : Colors.white.withOpacity(0.6),
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.06),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFFE5A17D).withOpacity(0.85)
                                  : AppColors.terracotta,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _inRangePois.length > 1
                                  ? 'View ${_inRangePois.length} nearby in player'
                                  : 'Open Now Playing & Guide',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withOpacity(0.8)
                                    : AppColors.maroon,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
      },
    );
  }
}

class _SensorPermissionPrompt extends StatelessWidget {
  final bool isRequesting;
  final VoidCallback onRequest;
  final bool isDark;

  const _SensorPermissionPrompt({
    required this.isRequesting,
    required this.onRequest,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF231D21) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.4) : AppColors.terracotta.withOpacity(0.08),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore,
                size: 72,
                color: isDark ? const Color(0xFFE5A17D) : AppColors.terracotta,
              ),
              const SizedBox(height: 20),
              Text(
                'Ready to find nearby stories',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                  color: isDark ? Colors.white : AppColors.maroon,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'DishaVaani needs your location and compass to detect monuments around you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.65) : AppColors.lightTextSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isRequesting ? null : onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF752433) : AppColors.maroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ALLOW LOCATION + COMPASS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void onPoiDetected(String poiId, String deviceId) async {
  final useDynamicScripting = ScriptingSettings().isDynamicScriptingEnabled;

  if (useDynamicScripting) {
    print('[Scripting Engine] 🎯 Triggering AI Gemini dynamic script for POI: $poiId (Device: $deviceId)');
  } else {
    print('[Scripting Engine] 🎯 Serving static pre-recorded audio script for POI: $poiId');
  }
}