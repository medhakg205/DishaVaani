// manual_poi_list.dart — screen 5: searchable flat list of POIs
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../models/poi.dart';
import '../widgets/theme_mode_toggle.dart';

class ManualPoiListScreen extends StatefulWidget {
  final List<Poi> pois;
  final ValueChanged<Poi> onPoiSelected;

  const ManualPoiListScreen({
    super.key,
    required this.pois,
    required this.onPoiSelected,
  });

  @override
  State<ManualPoiListScreen> createState() => _ManualPoiListScreenState();
}

class _ManualPoiListScreenState extends State<ManualPoiListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String? _resolvePoiAsset(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('iron pillar')) return 'assets/images/qutub_iron_pillar.jpg';
    if (lower.contains('alai darwaza')) return 'assets/images/qutub_alai_darwaza.jpg';
    if (lower.contains('quwwat')) return 'assets/images/quwwat_ul_islam.jpg';
    if (lower.contains('qutub') || lower.contains('minar')) return 'assets/images/qutub_minar_tower.jpg';
    if (lower.contains('lahori') || lower.contains('red fort')) return 'assets/images/red_fort_lahori_gate.jpg';
    if (lower.contains('humayun')) return 'assets/images/humayuns_tomb.jpg';
    if (lower.contains('india gate')) return 'assets/images/india_gate.jpg';
    if (lower.contains('agrasen') || lower.contains('baoli')) return 'assets/images/agrasen_ki_baoli.jpg';
    if (lower.contains('jama')) return 'assets/images/jama_masjid.jpg';
    return null;
  }

  List<Poi> get _filteredPois {
    if (_searchQuery.trim().isEmpty) return widget.pois;
    final query = _searchQuery.trim().toLowerCase();
    return widget.pois.where((poi) {
      final nameMatch = poi.name.toLowerCase().contains(query);
      final descriptionMatch = poi
          .getScript('en')
          .toLowerCase()
          .contains(query);
      return nameMatch || descriptionMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPois = _filteredPois;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, _, child) {
        final isDark = AppSettings.isDarkMode;

        return Scaffold(
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark ? Colors.white70 : AppColors.maroon,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Points of Interest',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              fontFamily: 'Georgia',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const ThemeModeToggle(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface.withOpacity(0.6)
                            : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.copperGlow.withOpacity(0.3)
                              : AppColors.terracotta.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : AppColors.terracotta.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: isDark ? AppColors.copperGlow : AppColors.maroon,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                fontSize: 14,
                              ),
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search points of interest...',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                suffixIcon: _searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: isDark ? Colors.white54 : Colors.black45,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredPois.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No POIs available.'
                                  : 'No POIs match "$_searchQuery".',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filteredPois.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final poi = filteredPois[index];
                              final assetPath = _resolvePoiAsset(poi.name);

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    widget.onPoiSelected(poi);
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface.withOpacity(0.85)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.08)
                                            : AppColors.lightBorder,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDark
                                              ? Colors.black.withOpacity(0.3)
                                              : Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF38252C)
                                                  : AppColors.sandstone,
                                            ),
                                            child: assetPath != null
                                                ? Image.asset(
                                                    assetPath,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) => Icon(
                                                      Icons.temple_hindu_rounded,
                                                      color: isDark
                                                          ? AppColors.copperGlow
                                                          : AppColors.terracotta,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.temple_hindu_rounded,
                                                    color: isDark
                                                        ? AppColors.copperGlow
                                                        : AppColors.terracotta,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                poi.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  fontFamily: 'Georgia',
                                                  color: isDark
                                                      ? Colors.white
                                                      : AppColors.lightTextPrimary,
                                                ),
                                              ),
                                              if (poi
                                                  .getScript(
                                                    AppSettings.selectedLanguage,
                                                  )
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Text(
                                                  poi.getScript(
                                                    AppSettings.selectedLanguage,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark
                                                        ? Colors.white60
                                                        : Colors.black54,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.copperGlow.withOpacity(0.15)
                                                : AppColors.terracotta.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            color: isDark
                                                ? AppColors.copperGlow
                                                : AppColors.terracotta,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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
