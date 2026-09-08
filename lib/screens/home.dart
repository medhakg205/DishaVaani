// home.dart — screen 2: pick a monument, grouped POI counts from Firestore, or active Itinerary
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/app_colors.dart';
import '../models/itinerary_stop.dart';
import '../services/itinerary.dart';
import '../services/poi.dart';
import '../services/profile_store.dart';
import '../services/recommendation_trigger.dart';
import '../services/monument_seeder.dart';
import '../widgets/dynamic_scripting_toggle.dart';
import '../widgets/itinerary_stop_card.dart';
import 'itinerary_import.dart';
import 'point_detect.dart';
import 'splash.dart';

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
  List<ItineraryStop>? _stops;

  @override
  void initState() {
    super.initState();
    _stops = widget.itineraryStops;
    _loadMonumentsAndItinerary();
  }

  Future<void> _loadMonumentsAndItinerary() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 1. If itinerary stops were not passed in constructor, try loading saved stops from Firestore
      if (_stops == null || _stops!.isEmpty) {
        final savedStops = await ItineraryService.loadStops();
        if (savedStops.isNotEmpty) {
          _stops = savedStops;
        }
      }

      // 2. Fetch all POIs to populate counts
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
        _syncSelectedMonument(poiCounts);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        monumentPoiCounts = _demoMonumentPoiCounts;
        _syncSelectedMonument(_demoMonumentPoiCounts);
        errorMessage = null;
        isLoading = false;
      });
    }
  }

  void _syncSelectedMonument([Map<String, int>? counts]) {
    final poiCounts = counts ?? monumentPoiCounts;
    if (_hasActiveItinerary) {
      // Select first available stop with a matched monumentId
      for (final stop in _stops!) {
        if (stop.monumentId != null && stop.monumentId!.isNotEmpty) {
          selectedMonumentId = stop.monumentId;
          return;
        }
      }
      selectedMonumentId = null;
    } else {
      final items = _buildDisplayItems(poiCounts);
      selectedMonumentId = _firstAvailableId(items);
    }
  }

  bool get _hasActiveItinerary => _stops != null && _stops!.isNotEmpty;

  List<_MonumentListItem> _buildDisplayItems(Map<String, int> poiCounts) {
    return poiCounts.entries
        .map((e) => _MonumentListItem(
              monumentId: e.key,
              displayName: _monumentName(e.key),
              poiCount: e.value,
              isAvailable: true,
            ))
        .toList();
  }

  String? _firstAvailableId(List<_MonumentListItem> items) {
    for (final item in items) {
      if (item.isAvailable) return item.monumentId;
    }
    return null;
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

  Future<void> _handleStopAction(
      String reason, int index, ItineraryStop stop) async {
    final profile = await ProfileStore().loadProfile();
    final visitedMonumentIds = (_stops ?? [])
        .map((s) => s.monumentId)
        .whereType<String>()
        .toList();

    // Use the stop's coordinates as the search anchor so alternatives are relevant to this stop
    double lat = stop.lat ?? 0.0;
    double lon = stop.long ?? 0.0;

    if (lat == 0.0 || lon == 0.0) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 2),
        );
        lat = pos.latitude;
        lon = pos.longitude;
      } catch (_) {
        lat = 28.6139;
        lon = 77.2090;
      }
    }

    if (!mounted) return;

    triggerRecommendation(
      context: context,
      reason: reason,
      currentStopIndex: index,
      userLat: lat,
      userLon: lon,
      userProfile: profile,
      visitedMonumentIds: visitedMonumentIds,
      onItineraryUpdated: () async {
        final reloaded = await ItineraryService.loadStops();
        if (!mounted) return;
        setState(() {
          _stops = reloaded;
          _syncSelectedMonument();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          actions: [
            IconButton(
              tooltip: 'Import / Change Itinerary',
              icon: const Icon(Icons.route, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ItineraryImportScreen(),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (val) async {
                if (val == 'seed') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seeding monuments into Firestore...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  try {
                    final res = await MonumentSeeder.seedAll();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Successfully seeded ${res['monuments']} monuments & ${res['pois']} linked POIs!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadMonumentsAndItinerary();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Seeding failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'seed',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: AppColors.maroon),
                      SizedBox(width: 8),
                      Text('Seed Monuments (Dev)'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasActiveItinerary ? Icons.map_outlined : Icons.map,
                        size: 48,
                        color: AppColors.maroon,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _hasActiveItinerary
                            ? 'ACTIVE ITINERARY PLAN'
                            : 'EXPLORE MONUMENTS',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroon,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const DynamicScriptingToggle(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _hasActiveItinerary
                        ? 'ITINERARY STOPS (${_stops!.length})'
                        : 'NEARBY MONUMENTS',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (_hasActiveItinerary)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.refresh, size: 14, color: AppColors.maroon),
                      label: const Text(
                        'Reload',
                        style: TextStyle(fontSize: 12, color: AppColors.maroon),
                      ),
                      onPressed: _loadMonumentsAndItinerary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
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
                                  'Could not load data from Firebase.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _loadMonumentsAndItinerary,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _hasActiveItinerary
                            ? _buildItineraryListView()
                            : _buildMonumentsListView(),
              ),
              const SizedBox(height: 10),
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
                  child: Text(
                    selectedMonumentId == null
                        ? 'SELECT A MONUMENT'
                        : 'START LISTENING →',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the list of Itinerary stops with Skip, Finish Early, and Detour buttons.
  Widget _buildItineraryListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: _stops!.length,
      itemBuilder: (context, index) {
        final stop = _stops![index];
        final isAvailable = stop.monumentId != null && stop.monumentId!.isNotEmpty;
        final isSelected = isAvailable && selectedMonumentId == stop.monumentId;

        return ItineraryStopCard(
          stop: stop,
          stopIndex: index,
          isSelected: isSelected,
          isAvailable: isAvailable,
          onTap: () {
            if (isAvailable) {
              setState(() => selectedMonumentId = stop.monumentId);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${stop.placeName} is not yet linked to an audio guide monument in our database.',
                  ),
                ),
              );
            }
          },
          onSkip: () => _handleStopAction('skip', index, stop),
          onFinishEarly: () => _handleStopAction('finished_early', index, stop),
          onRequestDetour: () => _handleStopAction('detour', index, stop),
        );
      },
    );
  }

  /// Fallback view when no itinerary is present.
  Widget _buildMonumentsListView() {
    final items = _buildDisplayItems(monumentPoiCounts);

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No monuments with POIs were found.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
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
              color: item.isAvailable ? Colors.white : Colors.grey.shade200,
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