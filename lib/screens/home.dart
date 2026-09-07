// home.dart — screen 2: pick a monument, grouped POI counts from Firestore
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/itinerary_stop.dart';
import '../services/poi.dart';
import 'point_detect.dart';
import 'splash.dart';
import '../widgets/dynamic_scripting_toggle.dart';


class HomeScreen extends StatefulWidget {
  final List<ItineraryStop>? itineraryStops;

  const HomeScreen({super.key, this.itineraryStops});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PoiService _poiService = PoiService();
  static const Map<String, int> _demoMonumentPoiCounts = {
    'red_fort': 8,
    'qutub_minar': 6,
    'humayuns_tomb': 5,
  };

  bool isLoading = true;
  String? errorMessage;
  Map<String, int> monumentPoiCounts = {};
  String? selectedMonumentId;

  // Builds the rows to actually show on screen. If there's an itinerary,
  // this shows ONLY the itinerary's places — matched ones as normal rows,
  // unmatched ones (no monumentId) as grey/disabled rows. With no
  // itinerary (Skip was tapped), it falls back to showing everything
  // nearby, same as before this feature existed.
  List<_MonumentListItem> _buildDisplayItems(Map<String, int> poiCounts) {
    final itinerary = widget.itineraryStops;

    if (itinerary == null || itinerary.isEmpty) {
      return poiCounts.entries
          .map((e) => _MonumentListItem(
                monumentId: e.key,
                displayName: _monumentName(e.key),
                poiCount: e.value,
                isAvailable: true,
              ))
          .toList();
    }

    return itinerary.map((stop) {
      final monumentId = stop.monumentId;
      if (monumentId != null) {
        return _MonumentListItem(
          monumentId: monumentId,
          displayName: _monumentName(monumentId),
          poiCount: poiCounts[monumentId] ?? 0,
          isAvailable: true,
        );
      }
      // No monumentId means resolveStops() couldn't find this place in
      // the monuments collection — show it, but as unavailable.
      return _MonumentListItem(
        monumentId: null,
        displayName: stop.placeName,
        poiCount: 0,
        isAvailable: false,
      );
    }).toList();
  }

  List<_MonumentListItem> get _displayItems => _buildDisplayItems(monumentPoiCounts);

  String? _firstAvailableId(List<_MonumentListItem> items) {
    for (final item in items) {
      if (item.isAvailable) return item.monumentId;
    }
    return null;
  }

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
        selectedMonumentId = _firstAvailableId(_buildDisplayItems(poiCounts));
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        // Keep the UI navigable while the backend is unavailable.
        monumentPoiCounts = _demoMonumentPoiCounts;
        selectedMonumentId = _firstAvailableId(_buildDisplayItems(_demoMonumentPoiCounts));
        errorMessage = null;
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

  void _returnToLanding() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _displayItems;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _returnToLanding();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.maroon,
          elevation: 4,
          leading: IconButton(
            tooltip: 'Back to landing page',
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _returnToLanding,
          ),
          title: const Text(
            'DishaVaani',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.map, size: 60, color: AppColors.maroon),
                ),
              ),
              const SizedBox(height: 12),
              const DynamicScriptingToggle(),
              const SizedBox(height: 12),
              const Text(
                'NEARBY MONUMENTS',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.terracotta,
                        ),
                      )
                    : errorMessage != null
                    ? Center(
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
                      )
                    : items.isEmpty
                    ? const Center(
                        child: Text(
                          'No monuments with POIs were found.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected =
                              item.isAvailable && selectedMonumentId == item.monumentId;

                          return InkWell(
                            onTap: item.isAvailable
                                ? () => setState(
                                      () => selectedMonumentId = item.monumentId,
                                    )
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${item.displayName} isn\'t available yet — '
                                          'it hasn\'t been added to our monuments database.',
                                        ),
                                      ),
                                    );
                                  },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: item.isAvailable
                                    ? Colors.white
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !item.isAvailable
                                      ? Colors.grey.shade400
                                      : isSelected
                                          ? AppColors.terracotta
                                          : Colors.black12,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: item.isAvailable
                                          ? AppColors.sandstone
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.account_balance,
                                      color: item.isAvailable
                                          ? AppColors.terracotta
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: item.isAvailable
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  if (item.isAvailable)
                                    Text(
                                      '${item.poiCount} POI${item.poiCount == 1 ? '' : 's'}',
                                      style: const TextStyle(color: Colors.black45),
                                    )
                                  else
                                    Text(
                                      'Not available',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.radio_button_checked,
                                        size: 16,
                                        color: AppColors.maroon,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon,
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
      ),
    );
  }
}

class _MonumentListItem {
  final String? monumentId;
  final String displayName;
  final int poiCount;
  final bool isAvailable;

  const _MonumentListItem({
    required this.monumentId,
    required this.displayName,
    required this.poiCount,
    required this.isAvailable,
  });
}