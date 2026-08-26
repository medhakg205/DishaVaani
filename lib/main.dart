import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/poi.dart';
import 'services/poi_service.dart';
import 'services/translation_service.dart';
import 'package:geolocator/geolocator.dart';
import 'sensor_service.dart';
import 'dart:async';
import 'matching_engine.dart';
import 'app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DishaVaaniApp());
}

const Color maroon = Color(0xFF6B2737);
const Color terracotta = Color(0xFFC1652F);
const Color gold = Color(0xFFD4A24E);
const Color sandstone = Color(0xFFF5EFE6);

class DishaVaaniApp extends StatelessWidget {
  const DishaVaaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DishaVaani',
      theme: ThemeData(
        fontFamily: 'Georgia',
        scaffoldBackgroundColor: sandstone,
        colorScheme: ColorScheme.fromSeed(seedColor: maroon),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------- SCREEN 1: Splash ----------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isRequestingPermission = false;

  Future<void> _requestPermissionsAndContinue(BuildContext context) async {
    setState(() => _isRequestingPermission = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;
    setState(() => _isRequestingPermission = false);

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required to use DishaVaani.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: maroon, width: 3),
                ),
                child: const Icon(
                  Icons.explore,
                  size: 80,
                  color: terracotta,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'DISHAVAANI',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: maroon,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Point your phone. Listen in your language.\nNo QR codes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isRequestingPermission
                      ? null
                      : () => _requestPermissionsAndContinue(context),
                  child: _isRequestingPermission
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('ALLOW LOCATION + COMPASS'),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: maroon,
                    side: const BorderSide(color: maroon),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LanguageSelectScreen()),
                    );
                  },
                  child: const Text('CHOOSE LANGUAGE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Language Selection ----------
class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  late String selectedLanguageCode;

  final List<Map<String, dynamic>> languages = [
    {'name': 'English', 'native': 'English', 'code': 'en'},
    {'name': 'Hindi', 'native': 'हिन्दी', 'code': 'hi'},
    {'name': 'Tamil', 'native': 'தமிழ்', 'code': 'ta'},
    {'name': 'Telugu', 'native': 'తెలుగు', 'code': 'te'},
    {'name': 'Kannada', 'native': 'ಕನ್ನಡ', 'code': 'kn'},
    {'name': 'Malayalam', 'native': 'മലയാളം', 'code': 'ml'},
    {'name': 'Marathi', 'native': 'मराठी', 'code': 'mr'},
    {'name': 'Bengali', 'native': 'বাংলা', 'code': 'bn'},
    {'name': 'Gujarati', 'native': 'ગુજરાતી', 'code': 'gu'},
    {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'code': 'pa'},
  ];

  @override
  void initState() {
    super.initState();
    // Reflect whatever was already selected before, so reopening this
    // screen doesn't silently reset the user's choice.
    selectedLanguageCode = AppSettings.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maroon,
        elevation: 4,
        title: const Text('Choose Language', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your preferred narration language',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final bool isSelected = selectedLanguageCode == lang['code'];

                  return InkWell(
                    onTap: () => setState(() => selectedLanguageCode = lang['code']),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? terracotta : Colors.black12,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lang['name'],
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(lang['native'],
                                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.check_circle, color: terracotta),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Step 4: this is the actual moment the user's choice
                  // becomes the app-wide selected language.
                  AppSettings.selectedLanguage = selectedLanguageCode;
                  Navigator.pop(context);
                },
                child: const Text('CONFIRM'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- SCREEN 2: Home / Select Site ----------
// (unchanged)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PoiService _poiService = PoiService();

  bool isLoading = true;
  String? errorMessage;
  Map<String, int> monumentPoiCounts = {};
  String? selectedMonumentId;

  @override
  void initState() {
    super.initState();
    _loadMonuments();
  }

  Future<void> _loadMonuments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final pois = await _poiService.fetchAllPois();
      final poiCounts = <String, int>{};

      for (final poi in pois) {
        final monumentId = poi.monumentId.trim();

        if (monumentId.isNotEmpty) {
          poiCounts[monumentId] = (poiCounts[monumentId] ?? 0) + 1;
        }
      }

      if (!mounted) return;

      setState(() {
        monumentPoiCounts = poiCounts;
        selectedMonumentId = poiCounts.isNotEmpty ? poiCounts.keys.first : null;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  String _monumentName(String monumentId) {
    return monumentId
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maroon,
        elevation: 4,
        title: const Text('DishaVaani', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: gold.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.map,
                  size: 60,
                  color: maroon,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'NEARBY MONUMENTS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: terracotta),
                ),
              )
            else if (errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load monuments from Firebase.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadMonuments,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (monumentPoiCounts.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No monuments with POIs were found.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...monumentPoiCounts.entries.map(
                (entry) => InkWell(
                  onTap: () {
                    setState(() {
                      selectedMonumentId = entry.key;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedMonumentId == entry.key ? terracotta : Colors.black12,
                        width: selectedMonumentId == entry.key ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: sandstone,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: terracotta,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _monumentName(entry.key),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${entry.value} POI${entry.value == 1 ? '' : 's'}',
                          style: const TextStyle(color: Colors.black45),
                        ),
                        if (selectedMonumentId == entry.key)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, color: terracotta),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: selectedMonumentId == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PointDetectScreen(
                              monumentId: selectedMonumentId!,
                            ),
                          ),
                        );
                      },
                child: const Text('START LISTENING →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- SCREEN 3: Point & Detect ----------
// (unchanged)

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

  final SensorService _sensorService = SensorService();
  StreamSubscription<SensorReading>? _sensorSub;
  final PoiService _poiService = PoiService();
  List<Poi> _monumentPois = [];

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String? _playingPoiId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Placeholder wiring point: once the matching engine is connected,
  // this becomes the real top-ranked / in-range POI list.
  List<Poi> get _inRangePois => _monumentPois;
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
    setState(() {
      _position = position;
    });
  });

  _audioPlayer.onDurationChanged.listen((duration) {
    if (!mounted) return;
    setState(() {
      _duration = duration;
    });
  });
}

  Future<void> _loadPois() async {
    try {
      final pois = await _poiService.fetchPoisByMonument(widget.monumentId);
      if (!mounted) return;
      setState(() {
        _monumentPois = pois;
      });
    } catch (error) {
      // handle error display later
    }
  }

  Future<void> _startSensors() async {
    await _sensorService.start();
    _sensorSub = _sensorService.readings.listen((reading) {
      if (!mounted) return;
      setState(() {
        heading = reading.heading;
        lat = reading.lat;
        long = reading.long;
      });
    });
  }

  Future<void> _togglePlayback(Poi poi) async {
    final audioUrl = poi.getAudioUrl('en').trim();

    if (audioUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio URL is available for this POI.')),
      );
      return;
    }

    try {
      if (isPlaying && _playingPoiId == poi.id) {
        await _audioPlayer.pause();
      } else {
        _playingPoiId = poi.id;
        await _audioPlayer.play(UrlSource(audioUrl));
      }
        } catch (error) {
      if (!mounted) return;
      setState(() => isPlaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play audio: $error')),
      );
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

    final seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final topPoi = _topPoi;
    final radians = heading * 3.141592653589793 / 180;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: maroon,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        title: const Text('DishaVaani', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                children: [
                  Text(
                    _monumentName(widget.monumentId),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: maroon,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lat != null && long != null
                        ? '${lat!.toStringAsFixed(4)}° N, ${long!.toStringAsFixed(4)}° E'
                        : 'Waiting for GPS...',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),  
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: topPoi != null ? terracotta.withOpacity(0.12) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    topPoi != null ? Icons.radar : Icons.search,
                    size: 15,
                    color: topPoi != null ? terracotta : Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      topPoi != null ? 'POI detected — ${topPoi.name}' : 'Scanning for nearby POIs...',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: topPoi != null ? terracotta : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${heading.toInt()}°',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: maroon,
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned(top: 0, child: _CompassLabel('N')),
                    const Positioned(bottom: 0, child: _CompassLabel('S')),
                    const Positioned(left: 0, child: _CompassLabel('W')),
                    const Positioned(right: 0, child: _CompassLabel('E')),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: terracotta, width: 3),
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: radians,
                          child: const _CompassNeedle(size: 90),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Now playing bar ----
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: terracotta, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
                            child: Row(
                children: [
                  // Monument icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.temple_hindu,
                      color: maroon,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // POI name + controls + slider
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
                                  const Text(
                                    'Now approaching',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    topPoi?.name ?? 'Nothing playing yet',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: maroon,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _VolumeButton(audioPlayer: _audioPlayer),
                          ],
                        ),

                        const SizedBox(height: 2),
                        // Play controls: -5s / play-pause / +5s, always visible, centered above the slider
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_5, color: terracotta),
                                iconSize: 26,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _seekBy(const Duration(seconds: -5)),
                              ),
                              const SizedBox(width: 18),
                              GestureDetector(
                                onTap: topPoi == null ? null : () => _togglePlayback(topPoi),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: maroon,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPlaying && _playingPoiId == topPoi?.id
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              IconButton(
                                icon: const Icon(Icons.forward_5, color: terracotta),
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
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10,
                            ),
                            activeTrackColor: terracotta,
                            inactiveTrackColor: sandstone,
                            thumbColor: terracotta,
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
                            onChanged: (value) {
                              setState(() {
                                _position = Duration(
                                  milliseconds: value.toInt(),
                                );
                              });
                            },
                            onChangeEnd: (value) async {
                              await _audioPlayer.seek(
                                Duration(
                                  milliseconds: value.toInt(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NowPlayingScreen(
                      monumentId: widget.monumentId,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _inRangePois.length > 1
                          ? 'View ${_inRangePois.length} nearby'
                          : 'View manual list',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
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

class _CompassLabel extends StatelessWidget {
  final String label;
  const _CompassLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CompassNeedle extends StatelessWidget {
  final double size;
  const _CompassNeedle({this.size = 70});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NeedlePainter()),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final tipLength = size.height / 2;
    final halfWidth = size.width / 6;

    final northPaint = Paint()..color = maroon;
    final southPaint = Paint()..color = Colors.black26;

    final northPath = Path()
      ..moveTo(center.dx, center.dy - tipLength)
      ..lineTo(center.dx - halfWidth, center.dy)
      ..lineTo(center.dx + halfWidth, center.dy)
      ..close();

    final southPath = Path()
      ..moveTo(center.dx, center.dy + tipLength)
      ..lineTo(center.dx - halfWidth, center.dy)
      ..lineTo(center.dx + halfWidth, center.dy)
      ..close();

    canvas.drawPath(southPath, southPaint);
    canvas.drawPath(northPath, northPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// ---------- Reusable volume popup button ----------
class _VolumeButton extends StatefulWidget {
  final AudioPlayer audioPlayer;
  const _VolumeButton({required this.audioPlayer});

  @override
  State<_VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends State<_VolumeButton> {
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
          // Tap outside to dismiss
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: terracotta.withOpacity(0.4)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: StatefulBuilder(
                  builder: (context, setPopupState) {
                    return Row(
                      children: [
                        const Icon(Icons.volume_down, size: 14, color: Colors.black45),
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
                              activeTrackColor: terracotta,
                              inactiveTrackColor: sandstone,
                              thumbColor: terracotta,
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
                        const Icon(Icons.volume_up, size: 14, color: terracotta),
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
          color: terracotta,
        ),
        onPressed: _toggleSlider,
        splashRadius: 20,
      ),
    );
  }
}

// ---------- SCREEN 4: Now Playing / Queue ----------

class NowPlayingScreen extends StatefulWidget {
  final String monumentId;

  const NowPlayingScreen({
    super.key,
    this.monumentId = 'qutub_minar',
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final PoiService _poiService = PoiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TranslationService _translationService = TranslationService();

  bool isPlaying = false;
  bool isLoading = true;
  bool isResolvingAudio = false; // Step 7: loading state while translating/fetching
  String? errorMessage;

  Poi? currentPoi;
  List<Poi> queue = [];
  List<Poi> _allPois = [];

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  double get heading => 214.0; //why is this here? someone please fix this

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        isPlaying = false;
      });
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
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPois() async {
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

      setState(() {
        isLoading = false;
      });
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

    setState(() {
      queue = candidates;
    });

    if (autoPlayChangedItem &&
        queue.isNotEmpty &&
        queue.first.id != oldFirst) {
      _playPoi(queue.first);
    }
  }

  // Step 5: resolve the correct audio URL for the currently selected
  // language — reuse cached audio if it exists, otherwise call the
  // translation backend and cache the result locally on this Poi object.
  Future<String?> _resolveAudioUrl(Poi poi) async {
    final lang = AppSettings.selectedLanguage;

    final existingUrl = poi.audioUrls[lang];
    if (existingUrl != null && existingUrl.trim().isNotEmpty) {
      return existingUrl;
    }

    final englishScript = poi.getScript('en');
    if (englishScript.isEmpty) {
      return null;
    }

    setState(() => isResolvingAudio = true);

    try {
      final newUrl = await _translationService.getTranslatedAudioUrl(
        poiId: poi.id,
        sourceScript: englishScript,
        targetLanguage: lang,
      );
      // Cache locally too, so switching away and back doesn't re-fetch
      // within this same session.
      poi.audioUrls[lang] = newUrl;
      return newUrl;
    } catch (e) {
      debugPrint('Translation call failed: $e');
      return null;
    } finally {
      if (mounted) setState(() => isResolvingAudio = false);
    }
  }

  // Step 6: this is the trigger used by both auto-advance and manual play.
  Future<void> _playPoi(Poi poi) async {
    final audioUrl = await _resolveAudioUrl(poi);
    if (audioUrl == null || audioUrl.trim().isEmpty) return;

    try {
      await _audioPlayer.stop();
      setState(() {
        _position = Duration.zero;
        _duration = Duration.zero;
      });
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (_) {
      // Demo autoplay should not crash the UI if a POI has a bad URL.
    }
  }

  Future<void> _togglePlayback(Poi poi) async {
    if (isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    // Step 6: manual play button trigger — resolves audio for the
    // currently selected language before playing.
    final audioUrl = await _resolveAudioUrl(poi);

    if (audioUrl == null || audioUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio available in this language yet.')),
      );
      return;
    }

    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play audio: $error')),
      );
    }
  }

    Future<void> _seekBy(Duration delta) async {
    final maxMs = _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0;
    final newMs = (_position.inMilliseconds + delta.inMilliseconds).clamp(0, maxMs);
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

    // Auto-play the newly selected POI instead of waiting for another tap.
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
          child: CircularProgressIndicator(color: terracotta),
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
                const Icon(Icons.cloud_off, color: terracotta, size: 54),
                const SizedBox(height: 16),
                const Text(
                  'Could not load POIs from Firebase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: maroon,
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
                  ? const Center(child: Text('No other POIs are currently in the queue.'))
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
                              color: index == 0 ? gold.withOpacity(0.18) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: index == 0 ? terracotta : Colors.black12,
                                width: index == 0 ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: sandstone,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: maroon),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        queuedPoi.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Bearing ${bearing.toInt()}°  •  ${angle.toInt()}° away',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      if (queuedPoi.getScript('en').isNotEmpty)
                                        Text(
                                          queuedPoi.getScript('en'),
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
                                    ? _VolumeButton(audioPlayer: _audioPlayer)
                                    : const Icon(Icons.play_arrow, color: terracotta),
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
      backgroundColor: maroon,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: terracotta, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monument icon + name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.temple_hindu, color: maroon, size: 32),
              ),
              const SizedBox(width: 14),
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
                              const Text(
                                'Now approaching',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              Text(
                                poi.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: maroon,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _VolumeButton(audioPlayer: _audioPlayer),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (poi.getScript('en').isNotEmpty)
                      Text(
                        poi.getScript('en'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      )
                    else
                      const Text(
                        'Description not available yet.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.black45,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
                    // Play controls: -5s / play-pause / +5s, centered above the slider.
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_5, color: terracotta),
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
                        color: maroon,
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
                    icon: const Icon(Icons.forward_5, color: terracotta),
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
              activeTrackColor: terracotta,
              inactiveTrackColor: sandstone,
              thumbColor: terracotta,
            ),
            child: Slider(
              min: 0,
              max: _duration.inMilliseconds > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1,
              value: _position.inMilliseconds
                  .clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1)
                  .toDouble(),
              onChanged: (value) {
                setState(() => _position = Duration(milliseconds: value.toInt()));
              },
              onChangeEnd: (value) async {
                await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position),
                    style: const TextStyle(fontSize: 10, color: Colors.black45)),
                Text(_formatDuration(_duration),
                    style: const TextStyle(fontSize: 10, color: Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }             
}

// ---------- SCREEN 5: Manual POI List ----------
// (unchanged)

class ManualPoiListScreen extends StatelessWidget {
  final List<Poi> pois;
  final ValueChanged<Poi> onPoiSelected;

  const ManualPoiListScreen({
    super.key,
    required this.pois,
    required this.onPoiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maroon,
        elevation: 4,
        title: const Text('All POIs', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.black45,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search POIs',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pois.isEmpty
                  ? const Center(
                      child: Text('No POIs available.'),
                    )
                  : ListView.separated(
                      itemCount: pois.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final poi = pois[index];

                        return InkWell(
                          onTap: () {
                            onPoiSelected(poi);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.black12,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: sandstone,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.temple_hindu,
                                    color: terracotta,
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
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (poi.getScript('en').isNotEmpty)
                                        Text(
                                          poi.getScript('en'),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.play_arrow,
                                  color: terracotta,
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
}