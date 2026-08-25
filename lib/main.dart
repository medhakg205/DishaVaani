import 'demo/demo_controller.dart';
import 'demo/demo_panel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/poi.dart';
import 'services/poi_service.dart';
import 'package:geolocator/geolocator.dart';
import 'sensor_service.dart';
import 'dart:async';
import 'matching_engine.dart';

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
  String selectedLanguage = 'English';

  final List<Map<String, dynamic>> languages = [
    {'name': 'English', 'native': 'English', 'enabled': true},
    {'name': 'Hindi', 'native': 'हिन्दी', 'enabled': false},
    {'name': 'Tamil', 'native': 'தமிழ்', 'enabled': false},
    {'name': 'Telugu', 'native': 'తెలుగు', 'enabled': false},
    {'name': 'Kannada', 'native': 'ಕನ್ನಡ', 'enabled': false},
    {'name': 'Malayalam', 'native': 'മലയാളം', 'enabled': false},
    {'name': 'Marathi', 'native': 'मराठी', 'enabled': false},
    {'name': 'Bengali', 'native': 'বাংলা', 'enabled': false},
    {'name': 'Gujarati', 'native': 'ગુજરાતી', 'enabled': false},
    {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'enabled': false},
  ];

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
                  final bool isEnabled = lang['enabled'] as bool;
                  final bool isSelected = selectedLanguage == lang['name'];

                  return Opacity(
                    opacity: isEnabled ? 1.0 : 0.5,
                    child: InkWell(
                      onTap: isEnabled
                          ? () => setState(() => selectedLanguage = lang['name'])
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${lang['name']} narration coming soon via Bhashini.'),
                                ),
                              );
                            },
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
                            if (!isEnabled)
                              const Text('Coming soon',
                                  style: TextStyle(fontSize: 11, color: Colors.black38)),
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.check_circle, color: terracotta),
                              ),
                          ],
                        ),
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
                onPressed: () => Navigator.pop(context),
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
  bool useDemoMode = false;

  final SensorService _sensorService = SensorService();
  StreamSubscription<SensorReading>? _sensorSub;
  final PoiService _poiService = PoiService();
  final DemoController demoController = DemoController();
  List<Poi> _monumentPois = [];

  double get effectiveHeading => useDemoMode ? demoController.heading : heading;

  @override
  void initState() {
    super.initState();
    _loadPois();
    _startSensors();
    demoController.addListener(() => setState(() {}));
  }

  Future<void> _loadPois() async {
    try {
      final pois = await _poiService.fetchPoisByMonument(widget.monumentId);
      if (!mounted) return;
      setState(() {
        _monumentPois = pois;
      });
    } catch (error) {
      // We'll handle error display later — for now just keep the list empty.
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

  @override
  void dispose() {
    _sensorSub?.cancel();
    _sensorService.dispose();
    demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maroon,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        title: const Text('DishaVaani', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(useDemoMode ? Icons.sensors : Icons.tune, color: Colors.white),
            tooltip: useDemoMode ? 'Switch to real sensors' : 'Switch to demo mode',
            onPressed: () => setState(() => useDemoMode = !useDemoMode),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (useDemoMode) DemoPanel(controller: demoController),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.black87,
              child: Column(
                children: [
                  Text(
                    'HEADING ${effectiveHeading.toInt()}°',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    useDemoMode
                        ? 'DEMO MODE'
                        : (lat != null && long != null
                            ? 'LAT ${lat!.toStringAsFixed(5)}, LONG ${long!.toStringAsFixed(5)}'
                            : 'Waiting for GPS...'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: sandstone,
                child: Center(
                  child: Transform.rotate(
                    angle: effectiveHeading * 3.141592653589793 / 180,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: terracotta, width: 3),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.explore, color: terracotta, size: 36),
                            SizedBox(height: 6),
                            Text(
                              'HOLD\nSTEADY',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, color: maroon),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: maroon,
                    side: const BorderSide(color: maroon),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NowPlayingScreen(
                          monumentId: widget.monumentId,
                          demoController: useDemoMode ? demoController : null,
                        ),
                      ),
                    );
                  },
                  child: const Text('MANUAL LIST'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- SCREEN 4: Now Playing / Queue ----------

class NowPlayingScreen extends StatefulWidget {
  final String monumentId;
  final DemoController? demoController;

  const NowPlayingScreen({
    super.key,
    this.monumentId = 'qutub_minar',
    this.demoController,
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final PoiService _poiService = PoiService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isPlaying = false;
  bool isLoading = true;
  String? errorMessage;

  Poi? currentPoi;
  List<Poi> queue = [];
  List<Poi> _allPois = [];

  double get heading => widget.demoController?.heading ?? 214.0;

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

    widget.demoController?.addListener(_onDemoChanged);
    _loadPois();
  }

  void _onDemoChanged() {
    if (!mounted || _allPois.isEmpty) return;
    _rerankQueue(autoPlayChangedItem: true);
  }

  @override
  void dispose() {
    widget.demoController?.removeListener(_onDemoChanged);
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

  // Demo ranking:
  // Every POI gets a stable virtual bearing. As the heading slider moves,
  // the angular distance changes, so the queue visibly re-orders live.
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

    // During Auto Play, automatically play the new best POI whenever
    // the slider rotation causes the first queue item to change.
    if (autoPlayChangedItem &&
        widget.demoController?.autoPlay == true &&
        queue.isNotEmpty &&
        queue.first.id != oldFirst) {
      _playPoi(queue.first);
    }
  }

  Future<void> _playPoi(Poi poi) async {
    final audioUrl = poi.getAudioUrl('en').trim();
    if (audioUrl.isEmpty) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (_) {
      // Demo autoplay should not crash the UI if a POI has a bad URL.
    }
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
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(audioUrl));
      }
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

  Future<void> _selectPoi(Poi poi) async {
    await _audioPlayer.stop();
    if (!mounted) return;

    setState(() {
      currentPoi = poi;
      isPlaying = false;
    });

    _rerankQueue();
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
            if (widget.demoController != null) DemoPanel(controller: widget.demoController!),
            if (widget.demoController != null)
              AnimatedBuilder(
                animation: widget.demoController!,
                builder: (context, _) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: maroon,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'DEMO LIVE  •  HEADING ${heading.toInt()}°  •  '
                      '${queue.length} POIs queued',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
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
                                Icon(
                                  index == 0 ? Icons.volume_up : Icons.play_arrow,
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
      child: Row(
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
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: isPlaying ? 0.4 : 0,
                  backgroundColor: sandstone,
                  color: terracotta,
                  minHeight: 4,
                ),
              ],
            ),
          ),
          IconButton(
            iconSize: 40,
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: terracotta,
            ),
            onPressed: () => _togglePlayback(poi),
          ),
        ],
      ),
    );
  }
}

// ---------- SCREEN 5: Manual POI List ----------

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