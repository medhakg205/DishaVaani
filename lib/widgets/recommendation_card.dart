import 'package:flutter/material.dart';
import '../models/monument.dart';

class RecommendationCard extends StatelessWidget {
  final Monument monument;
  final double distanceMeters;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RecommendationCard({
    super.key,
    required this.monument,
    required this.distanceMeters,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monument.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(distanceMeters / 1000).toStringAsFixed(1)} km away',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 6),
            Text(
              monument.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (monument.siteType == SiteType.private) ...[
              const SizedBox(height: 4),
              const Text(
                'Private heritage site',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onReject,
                  child: const Text('Not now'),
                ),
                ElevatedButton(
                  onPressed: onAccept,
                  child: const Text('Add to trip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}