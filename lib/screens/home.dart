// home.dart — screen 2: pick a monument, grouped POI counts from Firestore, or active Itinerary
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../models/itinerary_stop.dart';
import '../services/itinerary.dart';
import '../services/poi.dart';
import '../services/profile_store.dart';
import '../services/recommendation_trigger.dart';
import '../services/monument_seeder.dart';
import '../widgets/dynamic_scripting_toggle.dart';
import '../widgets/itinerary_stop_card.dart';
import '../widgets/theme_mode_toggle.dart';
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
      if (_stops == null || _stops!.isEmpty) {
        final savedStops = await ItineraryService.loadStops();
        if (savedStops.isNotEmpty) {
          _stops = savedStops;
        }
      }

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

  String? _resolveMonumentAsset(String? monumentId) {
    final id = (monumentId ?? '').toLowerCase();
    if (id.contains('qutub')) return 'assets/images/qutub_minar_tower.jpg';
    if (id.contains('red_fort') || id.contains('red')) return 'assets/images/red_fort_lahori_gate.jpg';
    if (id.contains('humayun')) return 'assets/images/humayuns_tomb.jpg';
    if (id.contains('india_gate')) return 'assets/images/india_gate.jpg';
    if (id.contains('agrasen') || id.contains('baoli')) return 'assets/images/agrasen_ki_baoli.jpg';
    if (id.contains('jama')) return 'assets/images/jama_masjid.jpg';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, _, __) {
        final isDark = AppSettings.isDarkMode;

        final bgGradient = isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkBgTop,
                  AppColors.darkBgMid,
                  AppColors.darkBgBottom,
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.lightBgTop,
                  AppColors.lightBgMid,
                  AppColors.lightBgBottom,
                ],
              );

        final primaryText = isDark ? Colors.white : AppColors.lightTextPrimary;
        final secondaryText = isDark ? Colors.white.withOpacity(0.65) : AppColors.lightTextSecondary;

        return PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _returnToLanding();
          },
          child: Scaffold(
            backgroundColor: isDark ? AppColors.darkBgBottom : AppColors.lightBgMid,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: false,
              leading: IconButton(
                tooltip: 'Back to landing page',
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : AppColors.maroon,
                ),
                onPressed: _returnToLanding,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DishaVaani',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  Text(
                    'AI Heritage Audio Tour',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.copperGlow : AppColors.terracotta,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                const ThemeModeToggle(isCompact: true),
                IconButton(
                  tooltip: 'Import / Change Itinerary',
                  icon: Icon(
                    Icons.route_rounded,
                    color: isDark ? Colors.white : AppColors.maroon,
                    size: 22,
                  ),
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
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.white : AppColors.maroon,
                  ),
                  color: isDark ? AppColors.darkSurface : Colors.white,
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
                    PopupMenuItem(
                      value: 'seed',
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: isDark ? AppColors.copperGlow : AppColors.maroon,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Seed Monuments (Dev)',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(gradient: bgGradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Card
                      _buildHeroCard(isDark),

                      const SizedBox(height: 8),

                      // Dynamic Scripting Toggle
                      const DynamicScriptingToggle(),

                      const SizedBox(height: 10),

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                _hasActiveItinerary
                                    ? 'ITINERARY STOPS'
                                    : 'NEARBY MONUMENTS',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryText,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.copperGlow : AppColors.maroon).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_hasActiveItinerary ? _stops!.length : monumentPoiCounts.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.copperGlow : AppColors.maroon,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_hasActiveItinerary)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(50, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: isDark ? AppColors.copperGlow : AppColors.maroon,
                              ),
                              label: Text(
                                'Reload',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.copperGlow : AppColors.maroon,
                                ),
                              ),
                              onPressed: _loadMonumentsAndItinerary,
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Scrollable Stops List
                      Expanded(
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: isDark ? AppColors.copperGlow : AppColors.maroon,
                                ),
                              )
                            : errorMessage != null
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Could not load data from Firebase.',
                                          style: TextStyle(color: secondaryText),
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
                                    : _buildMonumentsListView(isDark),
                      ),

                      const SizedBox(height: 8),

                      // Bottom Floating Start Listening Action Bar
                      _buildBottomActionBar(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _resolveHeroAsset(String? monumentId) {
    final lowerId = (monumentId ?? '').toLowerCase();
    if (lowerId.contains('red_fort')) return 'assets/images/red_fort_lahori_gate.jpg';
    if (lowerId.contains('humayun')) return 'assets/images/humayuns_tomb.jpg';
    if (lowerId.contains('india_gate')) return 'assets/images/india_gate.jpg';
    if (lowerId.contains('agrasen')) return 'assets/images/agrasen_ki_baoli.jpg';
    if (lowerId.contains('jama')) return 'assets/images/jama_masjid.jpg';
    return 'assets/images/qutub_minar_tower.jpg';
  }

  /// Interactive Cinematic Hero Card featuring AI Monument Imagery & Sleek Badging
  Widget _buildHeroCard(bool isDark) {
    final imageAsset = _resolveHeroAsset(selectedMonumentId);

    return Container(
      width: double.infinity,
      height: 146,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF5A623).withValues(alpha: 0.35)
              : AppColors.maroon.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Generated Monument Imagery
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: isDark ? const Color(0xFF1E141B) : const Color(0xFFF4EDE4),
              ),
            ),

            // Deep Obsidian / Wine Gradient Scrim for effortless readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isDark
                      ? [
                          const Color(0xFF10090D).withValues(alpha: 0.94),
                          const Color(0xFF1A1118).withValues(alpha: 0.82),
                          const Color(0xFF150D14).withValues(alpha: 0.40),
                        ]
                      : [
                          const Color(0xFF221117).withValues(alpha: 0.90),
                          const Color(0xFF351A25).withValues(alpha: 0.78),
                          const Color(0xFF221117).withValues(alpha: 0.38),
                        ],
                ),
              ),
            ),

            // Foreground Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 13,
                              color: Color(0xFFFFD54F),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'AI HERITAGE AUDIO TRACK',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: Color(0xFFFFE082),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.7,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 11,
                              color: Color(0xFFFFD54F),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_hasActiveItinerary ? _stops!.length : monumentPoiCounts.length} Stops',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Title and status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasActiveItinerary
                            ? 'Curated Heritage Walk'
                            : 'Monuments of Delhi',
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.explore_rounded,
                            size: 13,
                            color: Color(0xFFFFD54F),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _hasActiveItinerary && selectedMonumentId != null
                                ? 'Next: ${_monumentName(selectedMonumentId!)}'
                                : 'Point & detect spatial compass active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
  Widget _buildMonumentsListView(bool isDark) {
    final items = _buildDisplayItems(monumentPoiCounts);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No monuments with POIs were found.',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item.isAvailable && selectedMonumentId == item.monumentId;
        final asset = _resolveMonumentAsset(item.monumentId);

        final cardBg = isDark
            ? (isSelected ? const Color(0xFF2E1F26) : const Color(0xFF221A20))
            : (isSelected ? const Color(0xFFFFF9F5) : Colors.white);

        final borderColor = isSelected
            ? (isDark ? AppColors.copperGlow : AppColors.maroon)
            : (isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: item.isAvailable
                  ? () => setState(() => selectedMonumentId = item.monumentId)
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${item.displayName} isn\'t available yet in our database.',
                          ),
                        ),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF38252C) : AppColors.sandstone,
                        ),
                        child: asset != null
                            ? Image.asset(
                                asset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.account_balance_rounded,
                                  color: isDark ? AppColors.copperGlow : AppColors.maroon,
                                ),
                              )
                            : Icon(
                                Icons.account_balance_rounded,
                                color: isDark ? AppColors.copperGlow : AppColors.maroon,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.isAvailable
                                ? '${item.poiCount} Points of Interest'
                                : 'Guide coming soon',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white.withOpacity(0.55) : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? AppColors.copperGlow : AppColors.maroon).withOpacity(0.2),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: isDark ? AppColors.copperGlow : AppColors.maroon,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Floating Bottom Action Bar
  Widget _buildBottomActionBar(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedMonumentId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.headphones_rounded,
                    size: 13,
                    color: isDark ? AppColors.copperGlow : AppColors.maroon,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Ready to tour: ${_monumentName(selectedMonumentId!)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.copperGlow : AppColors.maroon,
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: selectedMonumentId == null
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
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: selectedMonumentId != null
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF752433),
                          Color(0xFF9E2E44),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          isDark ? const Color(0xFF2C2228) : Colors.grey.shade400,
                          isDark ? const Color(0xFF221A20) : Colors.grey.shade300,
                        ],
                      ),
                boxShadow: selectedMonumentId != null
                    ? [
                        BoxShadow(
                          color: const Color(0xFF752433).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_fill_rounded,
                    color: selectedMonumentId != null
                        ? Colors.white
                        : (isDark ? Colors.white38 : Colors.grey.shade600),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedMonumentId == null
                        ? 'SELECT A MONUMENT'
                        : 'START LISTENING →',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: selectedMonumentId != null
                          ? Colors.white
                          : (isDark ? Colors.white38 : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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