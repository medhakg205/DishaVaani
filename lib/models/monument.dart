enum SiteType { government, private }

class Monument {
  final String id;
  final String name;
  final String description;
  final double lat;
  final double long;
  final List<String> categories;
  final SiteType siteType;
  final String? ownerContact;

  Monument({
    required this.id,
    required this.name,
    required this.description,
    required this.lat,
    required this.long,
    required this.categories,
    this.siteType = SiteType.government,
    this.ownerContact,
  });

  factory Monument.fromFirestore(Map<String, dynamic> data, String id) {
    return Monument(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      long: (data['long'] as num?)?.toDouble() ?? 0.0,
      categories: List<String>.from(data['categories'] ?? []),
      siteType: (data['siteType'] == 'private') ? SiteType.private : SiteType.government,
      ownerContact: data['ownerContact'] as String?,
    );
  }
}