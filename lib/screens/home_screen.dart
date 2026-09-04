// home_screen.dart — screen 2: pick a monument, grouped POI counts from Firestore
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/poi_service.dart';
import 'point_detect_screen.dart';

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
        backgroundColor: AppColors.maroon,
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
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Icon(Icons.map, size: 60, color: AppColors.maroon)),
            ),
            const SizedBox(height: 20),
            const Text('NEARBY MONUMENTS', style: TextStyle(fontSize: 12, color: Colors.black54, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.terracotta)))
            else if (errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load monuments from Firebase.', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(onPressed: _loadMonuments, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else if (monumentPoiCounts.isEmpty)
              const Expanded(child: Center(child: Text('No monuments with POIs were found.', textAlign: TextAlign.center)))
            else
              ...monumentPoiCounts.entries.map(
                (entry) => InkWell(
                  onTap: () => setState(() => selectedMonumentId = entry.key),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedMonumentId == entry.key ? AppColors.terracotta : Colors.black12,
                        width: selectedMonumentId == entry.key ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: AppColors.sandstone, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.account_balance, color: AppColors.terracotta),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_monumentName(entry.key), style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text('${entry.value} POI${entry.value == 1 ? '' : 's'}', style: const TextStyle(color: Colors.black45)),
                        if (selectedMonumentId == entry.key)
                          const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check, color: AppColors.terracotta)),
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
                  backgroundColor: AppColors.maroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: selectedMonumentId == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PointDetectScreen(monumentId: selectedMonumentId!)),
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