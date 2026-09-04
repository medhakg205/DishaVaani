// manual_poi_list_screen.dart — screen 5: searchable flat list of POIs
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../models/poi.dart';

class ManualPoiListScreen extends StatefulWidget {
  final List<Poi> pois;
  final ValueChanged<Poi> onPoiSelected;

  const ManualPoiListScreen({super.key, required this.pois, required this.onPoiSelected});

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

  List<Poi> get _filteredPois {
    if (_searchQuery.trim().isEmpty) return widget.pois;
    final query = _searchQuery.trim().toLowerCase();
    return widget.pois.where((poi) {
      final nameMatch = poi.name.toLowerCase().contains(query);
      final descriptionMatch = poi.getScript('en').toLowerCase().contains(query);
      return nameMatch || descriptionMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPois = _filteredPois;

    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.maroon, elevation: 4, title: const Text('All POIs', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black45),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search POIs',
                        border: InputBorder.none,
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, color: Colors.black45, size: 18),
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
            const SizedBox(height: 16),
            Expanded(
              child: filteredPois.isEmpty
                  ? Center(child: Text(_searchQuery.isEmpty ? 'No POIs available.' : 'No POIs match "$_searchQuery".', textAlign: TextAlign.center))
                  : ListView.separated(
                      itemCount: filteredPois.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final poi = filteredPois[index];

                        return InkWell(
                          onTap: () {
                            widget.onPoiSelected(poi);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(color: AppColors.sandstone, borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.temple_hindu, color: AppColors.terracotta),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(poi.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (poi.getScript(AppSettings.selectedLanguage).isNotEmpty)
                                        Text(
                                          poi.getScript(AppSettings.selectedLanguage),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.play_arrow, color: AppColors.terracotta),
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