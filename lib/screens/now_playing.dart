// now_playing.dart — DishaVaani glass/Spotify-style now playing screen
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../models/poi.dart';
import '../services/poi.dart';
import '../services/sensor.dart';
import '../services/profile_store.dart';
import '../services/scripting_settings.dart';
import '../services/translation.dart';
import '../widgets/theme_mode_toggle.dart';
import 'manual_poi_list.dart';

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
  final ScrollController _scriptScrollController = ScrollController();
  final Map<String, String> _dynamicAudioCache = {};

  StreamSubscription<SensorReading>? _sensorSub;
  Timer? _resumeAutoScrollTimer;

  List<Poi> _allPois = [];
  List<Poi> queue = [];
  Poi? currentPoi;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  double heading = 214.0;
  bool isPlaying = false;
  bool isLoading = true;
  bool isResolvingAudio = false;
  bool _userIsScrolling = false;
  String? errorMessage;
  String? _loadedPoiId;
  double _playbackSpeed = 1.0;
  final Set<String> _favoritePoiIds = {};

  void _togglePlaybackSpeed() {
    const speeds = [1.0, 1.2, 1.5, 2.0, 0.8];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    setState(() {
      _playbackSpeed = speeds[nextIndex];
    });
    _audioPlayer.setPlaybackRate(_playbackSpeed);
  }

  String _getMonumentDisplayName() {
    if (widget.monumentId.toLowerCase() == 'qutub_minar') {
      return 'Qutub Minar';
    }
    return widget.monumentId
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => isPlaying = state == PlayerState.playing);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
      _autoScrollScript();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => isPlaying = false);
    });

    _loadPois();
    _startSensors();
  }

  @override
  void dispose() {
    _resumeAutoScrollTimer?.cancel();
    _sensorSub?.cancel();
    _sensorService.dispose();
    _scriptScrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data / heading ranking
  // ---------------------------------------------------------------------------

  Future<void> _loadPois() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final pois = widget.initialPois != null
          ? List<Poi>.from(widget.initialPois!)
          : await _poiService.fetchPoisByMonument(widget.monumentId);

      if (!mounted) return;

      _allPois = pois;

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
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
      debugPrint('DishaVaani heading sensor unavailable: $e');
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

  void _rerankQueue() {
    if (_allPois.isEmpty) return;

    final selectedId = currentPoi?.id;
    final candidates = _allPois
        .where((poi) => poi.id != selectedId)
        .toList();

    candidates.sort((a, b) {
      final ia = _allPois.indexOf(a);
      final ib = _allPois.indexOf(b);
      final scoreA = _angleDifference(heading, _virtualBearing(a, ia));
      final scoreB = _angleDifference(heading, _virtualBearing(b, ib));
      return scoreA.compareTo(scoreB);
    });

    if (!mounted) return;
    setState(() => queue = candidates);
  }

  // ---------------------------------------------------------------------------
  // Audio
  // ---------------------------------------------------------------------------

  Future<String?> _resolveAudioUrl(Poi poi, {bool showLoading = false}) async {
    final lang = AppSettings.selectedLanguage;
    final dynamicScripting = ScriptingSettings().isDynamicScriptingEnabled;

    if (dynamicScripting) {
      final cacheKey = '${poi.id}_$lang';
      if (_dynamicAudioCache.containsKey(cacheKey)) {
        return _dynamicAudioCache[cacheKey];
      }

      if (showLoading && mounted) {
        setState(() => isResolvingAudio = true);
      }

      try {
        final profile = await ProfileStore().loadProfile();
        final profileMap = profile.weights.isNotEmpty ? profile.toJson() : null;

        final url = await TranslationService().getTranslatedAudioUrl(
          poiId: poi.id,
          sourceScript: poi.getScript('en'),
          sourceLang: 'en',
          targetLanguage: lang,
          interestProfile: profileMap,
          onScriptResolved: (script) {
            poi.scripts[lang] = script;
            if (mounted) setState(() {});
          },
        );

        _dynamicAudioCache[cacheKey] = url;
        poi.audioUrls[lang] = url;
        return url;
      } catch (e) {
        debugPrint('Dynamic audio resolution failed: $e');
        final fallback = poi.getAudioUrl(lang).trim();
        return fallback.isEmpty ? null : fallback;
      } finally {
        if (showLoading && mounted) {
          setState(() => isResolvingAudio = false);
        }
      }
    }

    final readAloudKey = '${poi.id}_${lang}_read_aloud';
    if (_dynamicAudioCache.containsKey(readAloudKey)) {
      return _dynamicAudioCache[readAloudKey];
    }

    final cachedReadAloud = poi.getReadAloudUrl(lang).trim();
    if (cachedReadAloud.isNotEmpty) {
      _dynamicAudioCache[readAloudKey] = cachedReadAloud;
      return cachedReadAloud;
    }

    final englishScript = poi.getScript('en').trim();
    if (englishScript.isNotEmpty) {
      if (showLoading && mounted) {
        setState(() => isResolvingAudio = true);
      }

      try {
        final url = await TranslationService().getTranslatedAudioUrl(
          poiId: poi.id,
          sourceScript: englishScript,
          sourceLang: 'en',
          targetLanguage: lang,
          interestProfile: null,
          readAloud: true,
          onScriptResolved: (script) {
            poi.scripts[lang] = script;
            if (mounted) setState(() {});
          },
        );

        _dynamicAudioCache[readAloudKey] = url;
        poi.readAloudUrls[lang] = url;
        return url;
      } catch (e) {
        debugPrint('Read aloud resolution failed: $e');
      } finally {
        if (showLoading && mounted) {
          setState(() => isResolvingAudio = false);
        }
      }
    }

    final staticUrl = poi.getAudioUrl(lang).trim();
    return staticUrl.isEmpty ? null : staticUrl;
  }

  Future<void> _togglePlayback(Poi poi) async {
    final url = await _resolveAudioUrl(poi, showLoading: true);

    if (url == null || url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio is available for this POI.')),
      );
      return;
    }

    try {
      if (isPlaying && _loadedPoiId == poi.id) {
        await _audioPlayer.pause();
        return;
      }

      if (_loadedPoiId == poi.id && _position > Duration.zero) {
        await _audioPlayer.resume();
        return;
      }

      _loadedPoiId = poi.id;
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (!mounted) return;
      setState(() => isPlaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play audio: $e')),
      );
    }
  }

  Future<void> _selectPoi(Poi poi) async {
    await _audioPlayer.stop();

    if (!mounted) return;

    _resumeAutoScrollTimer?.cancel();
    if (_scriptScrollController.hasClients) {
      _scriptScrollController.jumpTo(0);
    }

    setState(() {
      currentPoi = poi;
      isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _loadedPoiId = null;
      _userIsScrolling = false;
    });

    _rerankQueue();
    await _togglePlayback(poi);
  }

  Future<void> _seekBy(Duration delta) async {
    final maxMs = _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0;
    final newMs = (_position.inMilliseconds + delta.inMilliseconds).clamp(0, maxMs);
    final position = Duration(milliseconds: newMs);
    setState(() => _position = position);
    await _audioPlayer.seek(position);
  }

  Future<void> _skipToNext() async {
    if (queue.isEmpty) return;
    await _selectPoi(queue.first);
  }

  Future<void> _skipToPrevious() async {
    if (_allPois.isEmpty || currentPoi == null) return;
    final index = _allPois.indexOf(currentPoi!);
    if (index > 0) {
      await _selectPoi(_allPois[index - 1]);
    }
  }

  // ---------------------------------------------------------------------------
  // Script scrolling — follows audio progress but pauses when user scrolls.
  // ---------------------------------------------------------------------------

  void _handleManualScroll() {
    _userIsScrolling = true;
    _resumeAutoScrollTimer?.cancel();
    _resumeAutoScrollTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _userIsScrolling = false);
      _autoScrollScript();
    });
  }

  void _autoScrollScript() {
    if (_userIsScrolling || !_scriptScrollController.hasClients) return;
    if (_duration.inMilliseconds <= 0) return;

    final maxScroll = _scriptScrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final progress = (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);
    final target = maxScroll * progress;

    _scriptScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(1, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ---------------------------------------------------------------------------
  // Images
  // ---------------------------------------------------------------------------

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
        id.contains('baoli') ||
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

  String _poiImageUrl(Poi poi) {
    final name = poi.name.toLowerCase();
    final id = poi.id.toLowerCase();
    if (name.contains('iron') || id.contains('iron')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Iron_Pillar_of_Delhi.jpg/400px-Iron_Pillar_of_Delhi.jpg';
    } else if (name.contains('victory') || name.contains('tower') || id.contains('tower')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Qutb_Minar.jpg/400px-Qutb_Minar.jpg';
    } else if (name.contains('darwaza') || id.contains('darwaza')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Alai_Darwaza%2C_Qutb_Complex%2C_Delhi.jpg/400px-Alai_Darwaza%2C_Qutb_Complex%2C_Delhi.jpg';
    } else if (name.contains('chirantana') || id.contains('chirantana') || name.contains('room')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Quwwat-ul-Islam_Mosque_Qutb_complex.jpg/400px-Quwwat-ul-Islam_Mosque_Qutb_complex.jpg';
    }
    return 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Qutb_Minar.jpg/800px-Qutb_Minar.jpg';
  }

  Widget _poiImage(Poi poi) {
    final assetPath = _poiAssetPath(poi);

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Image.network(
          _poiImageUrl(poi),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _imageFallback(),
        ),
      );
    }

    return Image.network(
      _poiImageUrl(poi),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white38,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _imageFallback(),
    );
  }

  Widget _poiThumbnail(Poi poi) {
    final assetPath = _poiAssetPath(poi);

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.network(
          _poiImageUrl(poi),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _thumbnailFallback(),
        ),
      );
    }

    return Image.network(
      _poiImageUrl(poi),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFF2C2226),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white38,
                strokeWidth: 1.5,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _thumbnailFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A312B), Color(0xFF26181B)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.account_balance_rounded,
          size: 54,
          color: Colors.white38,
        ),
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      color: const Color(0xFF2C2226),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 20,
          color: Colors.white38,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, _, child) {
        final isDark = AppSettings.isDarkMode;

        if (isLoading) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF141215) : AppColors.lightBgMid,
            appBar: _appBar(isDark: isDark),
            body: Center(
              child: CircularProgressIndicator(
                color: isDark ? const Color(0xFFE5A17D) : AppColors.terracotta,
              ),
            ),
          );
        }

        if (errorMessage != null) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF141215) : AppColors.lightBgMid,
            appBar: _appBar(isDark: isDark),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 52,
                      color: isDark ? const Color(0xFFE5A17D) : AppColors.terracotta,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Could not load the POIs.',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.maroon,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
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
            backgroundColor: isDark ? const Color(0xFF141215) : AppColors.lightBgMid,
            appBar: _appBar(isDark: isDark),
            body: Center(
              child: Text(
                'No POIs were found for this monument.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                ),
              ),
            ),
          );
        }

        final poi = currentPoi!;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF141215) : AppColors.lightBgMid,
          appBar: _appBar(
            isDark: isDark,
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                children: [
                  _buildNowPlayingCard(poi, isDark),
                  const SizedBox(height: 18),
                  _buildUpNextHeader(isDark),
                  const SizedBox(height: 10),
                  ..._buildQueueItems(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _appBar({VoidCallback? onListPressed, required bool isDark}) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: isDark ? Colors.white : AppColors.maroon,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white70 : AppColors.maroon,
          size: 20,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DishaVaani',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.maroon,
              fontFamily: 'Georgia',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _getMonumentDisplayName(),
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      actions: [
        if (onListPressed != null)
          IconButton(
            onPressed: onListPressed,
            icon: Icon(
              Icons.format_list_bulleted_rounded,
              color: isDark ? Colors.white70 : AppColors.maroon,
              size: 22,
            ),
          ),
        const ThemeModeToggle(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNowPlayingCard(Poi poi, bool isDark) {
    final lang = AppSettings.selectedLanguage;
    final script = poi.getScript(lang).trim().isNotEmpty
        ? poi.getScript(lang).trim()
        : poi.getScript('en').trim();

    final positionMs = _position.inMilliseconds.clamp(
      0,
      _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1,
    );
    final durationMs = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF231D21) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : AppColors.terracotta.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          children: [
            // Top Monument Image
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: double.infinity,
                height: 195,
                child: _poiImage(poi),
              ),
            ),

            const SizedBox(height: 14),

            // Title, Subtitle, and Favorite Heart Icon
            Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(
                        poi.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMonumentDisplayName(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.55)
                              : AppColors.lightTextSecondary,
                          fontSize: 12.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(
                      _favoritePoiIds.contains(poi.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _favoritePoiIds.contains(poi.id)
                          ? (isDark ? const Color(0xFFE27D60) : AppColors.crimsonAction)
                          : (isDark ? Colors.white70 : Colors.black45),
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_favoritePoiIds.contains(poi.id)) {
                          _favoritePoiIds.remove(poi.id);
                        } else {
                          _favoritePoiIds.add(poi.id);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Description / Narration Script (centered, scrollable)
            Container(
              width: double.infinity,
              height: 94,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    if (notification.dragDetails != null) {
                      _handleManualScroll();
                    }
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scriptScrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    script.isEmpty ? 'No narration text available.' : script,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.72) : Colors.black87,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Progress Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.8,
                activeTrackColor: isDark ? const Color(0xFFE5A17D) : AppColors.terracotta,
                inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                thumbColor: isDark ? const Color(0xFFE5A17D) : AppColors.terracotta,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 11),
              ),
              child: Slider(
                min: 0,
                max: durationMs,
                value: positionMs.toDouble().clamp(0.0, durationMs).toDouble(),
                onChanged: (value) {
                  setState(() {
                    _position = Duration(milliseconds: value.toInt());
                  });
                },
                onChangeEnd: (value) {
                  _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            ),

            // Time stamps
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.55) : AppColors.lightTextSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.55) : AppColors.lightTextSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Controls row: Replay 15, Prev, Play/Pause, Next, Forward 15
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _replay15Button(isDark),
                IconButton(
                  onPressed: _skipToPrevious,
                  icon: Icon(
                    Icons.skip_previous,
                    color: isDark ? Colors.white : AppColors.maroon,
                    size: 32,
                  ),
                ),
                _mainPlayButton(poi, isDark),
                IconButton(
                  onPressed: _skipToNext,
                  icon: Icon(
                    Icons.skip_next,
                    color: isDark ? Colors.white : AppColors.maroon,
                    size: 32,
                  ),
                ),
                _forward15Button(isDark),
              ],
            ),

            const SizedBox(height: 4),

            // Bottom utility row: PIP icon & Speed button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.picture_in_picture_alt_outlined,
                      color: isDark ? Colors.white.withOpacity(0.7) : AppColors.maroon,
                      size: 22,
                    ),
                  ),
                  GestureDetector(
                    onTap: _togglePlaybackSpeed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white24 : AppColors.lightBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        '${_playbackSpeed.toStringAsFixed(1)}x',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.maroon,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainPlayButton(Poi poi, bool isDark) {
    return GestureDetector(
      onTap: isResolvingAudio ? null : () => _togglePlayback(poi),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF752433) : AppColors.maroon,
          boxShadow: [
            BoxShadow(
              color: (isDark ? const Color(0xFF752433) : AppColors.maroon).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isResolvingAudio
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(
                isPlaying && _loadedPoiId == poi.id
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 34,
              ),
      ),
    );
  }

  Widget _buildUpNextHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Up Next',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.maroon,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 14,
              color: isDark ? Colors.white.withOpacity(0.55) : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Live ranked by heading',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white.withOpacity(0.55) : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildQueueItems(bool isDark) {
    if (queue.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.04) : AppColors.lightBorder,
            ),
          ),
          child: Center(
            child: Text(
              'No other POIs are currently in the queue.',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return List.generate(queue.length, (index) {
      final queuedPoi = queue[index];
      final allIndex = _allPois.indexOf(queuedPoi);
      final bearing = _virtualBearing(queuedPoi, allIndex);
      final angle = _angleDifference(heading, bearing);
      final isFirst = index == 0;
      final script = queuedPoi
          .getScript(AppSettings.selectedLanguage)
          .trim();

      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _selectPoi(queuedPoi),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isFirst
                    ? (isDark ? const Color(0xFF38252C) : const Color(0xFFFFF0E6))
                    : (isDark ? const Color(0xFF1E1B1E) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? (isFirst
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.04))
                      : (isFirst
                          ? AppColors.terracotta.withOpacity(0.3)
                          : AppColors.lightBorder),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.65)
                            : AppColors.lightTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: _poiThumbnail(queuedPoi),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          queuedPoi.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bearing ${bearing.toInt()}°  •  ${angle.toInt()}° away',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.55)
                                : AppColors.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (script.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            script,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.38)
                                  : Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isFirst)
                    Icon(
                      Icons.volume_up,
                      color: isDark
                          ? Colors.white.withOpacity(0.75)
                          : AppColors.terracotta,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.play_arrow,
                      color: isDark
                          ? Colors.white.withOpacity(0.75)
                          : AppColors.terracotta,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _replay15Button(bool isDark) {
    final iconColor = isDark ? Colors.white : AppColors.maroon;

    return IconButton(
      onPressed: () => _seekBy(const Duration(seconds: -15)),
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.replay,
            color: iconColor,
            size: 27,
          ),
          Positioned(
            bottom: 6.5,
            child: Text(
              '15',
              style: TextStyle(
                color: iconColor.withOpacity(0.9),
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _forward15Button(bool isDark) {
    final iconColor = isDark ? Colors.white : AppColors.maroon;

    return IconButton(
      onPressed: () => _seekBy(const Duration(seconds: 15)),
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scaleX: -1,
            child: Icon(
              Icons.replay,
              color: iconColor,
              size: 27,
            ),
          ),
          Positioned(
            bottom: 6.5,
            child: Text(
              '15',
              style: TextStyle(
                color: iconColor.withOpacity(0.9),
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
