import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'firebase_options.dart';
import 'models/poi.dart';
import 'services/poi_service.dart';
import 'admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      home: kIsWeb ? const AdminDashboard() : const SplashScreen(),
    );
  }
}

// ---------- SCREEN 1: Splash ----------
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
                child: const Icon(Icons.explore, size: 80, color: terracotta),
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
                style: TextStyle(fontSize: 15, color: Colors.black54),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: const Text('ALLOW LOCATION + COMPASS'),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Language selection will be added next.'),
                      ),
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
                child: Icon(Icons.map, size: 60, color: maroon),
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
                  onTap: () => setState(() {
                    selectedMonumentId = entry.key;
                  }),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedMonumentId == entry.key
                            ? terracotta
                            : Colors.black12,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: selectedMonumentId == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NowPlayingScreen(
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

// ---------- SCREEN 4: Now Playing / Queue ----------
class NowPlayingScreen extends StatefulWidget {
  final String monumentId;

  const NowPlayingScreen({super.key, this.monumentId = 'qutub_minar'});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final PoiService _poiService = PoiService();

  bool isPlaying = false;
  bool isLoading = true;
  String? errorMessage;

  Poi? currentPoi;
  List<Poi> queue = [];

  @override
  void initState() {
    super.initState();
    _loadPois();
  }

  Future<void> _loadPois() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final pois = await _poiService.fetchPoisByMonument(widget.monumentId);

      if (!mounted) return;

      setState(() {
        currentPoi = pois.isNotEmpty ? pois.first : null;
        queue = pois.length > 1 ? pois.sublist(1) : [];
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

  void _selectPoi(Poi poi) {
    setState(() {
      final updatedPois = [
        currentPoi,
        ...queue,
      ].whereType<Poi>().where((item) => item.id != poi.id).toList();

      currentPoi = poi;
      queue = updatedPois;
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator(color: terracotta)),
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
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadPois,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroon,
                    foregroundColor: Colors.white,
                  ),
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
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No POIs were found in the Firestore collection "pois".',
              textAlign: TextAlign.center,
            ),
          ),
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
            const SizedBox(height: 24),
            const Text(
              'UP NEXT (ranked by distance × angle)',
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
                      child: Text(
                        'No other POIs are currently in the queue.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.separated(
                      itemCount: queue.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final queuedPoi = queue[index];

                        return InkWell(
                          onTap: () => _selectPoi(queuedPoi),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: sandstone,
                                  child: Text(
                                    '${index + 2}',
                                    style: const TextStyle(color: maroon),
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
                                      if (queuedPoi.scriptText.isNotEmpty)
                                        Text(
                                          queuedPoi.scriptText,
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
                                const Icon(Icons.play_arrow, color: terracotta),
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
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
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
                if (poi.scriptText.isNotEmpty)
                  Text(
                    poi.scriptText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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
            onPressed: () {
              setState(() {
                isPlaying = !isPlaying;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isPlaying
                        ? 'Playback UI enabled for ${poi.name}.'
                        : 'Playback paused.',
                  ),
                ),
              );
            },
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
                  Icon(Icons.search, color: Colors.black45),
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
                  ? const Center(child: Text('No POIs available.'))
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
                              border: Border.all(color: Colors.black12),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        poi.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (poi.scriptText.isNotEmpty)
                                        Text(
                                          poi.scriptText,
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
                                const Icon(Icons.play_arrow, color: terracotta),
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
