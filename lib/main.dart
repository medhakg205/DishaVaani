import 'package:flutter/material.dart';
import 'models/poi.dart';

void main() => runApp(const DishaVaaniApp());

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
      theme: ThemeData(
        fontFamily: 'Georgia',
        scaffoldBackgroundColor: sandstone,
        colorScheme: ColorScheme.fromSeed(seedColor: maroon),
      ),
      home: const SplashScreen(),
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
              const Text('DISHAVAANI',
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.bold, color: maroon, letterSpacing: 3)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()));
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
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
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sites = [
      {'name': 'Qutub Minar Complex', 'dist': '1.2 km'},
      {'name': 'Hauz Khas Fort', 'dist': '4.8 km'},
    ];

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
            const Text('NEARBY MONUMENTS',
                style: TextStyle(fontSize: 12, color: Colors.black54, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            ...sites.map((site) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black12),
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
                        child: const Icon(Icons.account_balance, color: terracotta),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(site['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Text(site['dist']!, style: const TextStyle(color: Colors.black45)),
                    ],
                  ),
                )),
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
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NowPlayingScreen()));
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
  const NowPlayingScreen({super.key});
  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool isPlaying = false;

  final Poi currentPoi = Poi(
    id: '1',
    name: 'West Wall Carving',
    lat: 28.658,
    long: 77.2446,
    bearingTolerance: 20,
    audioUrl: 'poi_westwall.mp3',
    scriptText: 'Placeholder for West Wall',
  );

  final List<Poi> queue = [
    Poi(id: '2', name: 'Ancient Temple', lat: 28.659, long: 77.245, bearingTolerance: 20, audioUrl: '', scriptText: ''),
    Poi(id: '3', name: 'Watch Tower', lat: 28.660, long: 77.246, bearingTolerance: 20, audioUrl: '', scriptText: ''),
    Poi(id: '4', name: 'Old Stepwell', lat: 28.661, long: 77.247, bearingTolerance: 20, audioUrl: '', scriptText: ''),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maroon,
        title: const Text('DishaVaani', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManualPoiListScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: terracotta, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
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
                        const Text('Now approaching',
                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(currentPoi.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: maroon)),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: 0.4,
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
                    onPressed: () => setState(() => isPlaying = !isPlaying),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('UP NEXT (ranked by distance × angle)',
                style: TextStyle(fontSize: 12, color: Colors.black54, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: queue.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final poi = queue[index];
                  return Container(
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
                          child: Text('${index + 2}', style: const TextStyle(color: maroon)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(poi.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
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

// ---------- SCREEN 5: Manual POI List ----------
class ManualPoiListScreen extends StatelessWidget {
  const ManualPoiListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pois = [
      'West Wall Carving',
      'Ancient Temple',
      'Watch Tower',
      'Old Stepwell',
    ];

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
              child: ListView.separated(
                itemCount: pois.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => Container(
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
                        child: const Icon(Icons.temple_hindu, color: terracotta),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(pois[index],
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}