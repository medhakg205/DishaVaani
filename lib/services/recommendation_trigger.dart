import 'package:flutter/material.dart';
import '../models/interest_profile.dart';
import '../models/monument.dart';
import '../services/monument.dart'; // Your MonumentService
import '../services/recommendation_engine.dart';
import '../services/real_itinerary_update_port.dart';
import '../widgets/recommendation_card.dart';

void triggerRecommendation({
  required BuildContext context,
  required String reason, // 'skip', 'finished_early', or 'detour'
  required int currentStopIndex,
  required double userLat,
  required double userLon,
  required InterestProfile userProfile,
  required List<String> visitedMonumentIds,
  required VoidCallback onItineraryUpdated,
}) async {
  // Show loading indicator
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Finding personalized nearby alternatives...'), duration: Duration(seconds: 1)),
  );

  final monumentService = MonumentService();
  final allMonuments = await monumentService.getAllMonuments();

  if (allMonuments.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No monuments found in database. Please seed monuments first.')),
      );
    }
    return;
  }

  // Identify current monument being acted upon
  final currentMonumentId = (currentStopIndex >= 0 && currentStopIndex < visitedMonumentIds.length)
      ? visitedMonumentIds[currentStopIndex]
      : null;

  // 1. Filter out visited/already-planned monuments
  var candidates = allMonuments
      .where((m) => !visitedMonumentIds.contains(m.id))
      .toList();

  // If all monuments in database are already in the itinerary, fallback to any other monument
  if (candidates.isEmpty) {
    candidates = allMonuments.where((m) => m.id != currentMonumentId).toList();
  }

  // If only 1 monument exists in the entire database, allow it
  if (candidates.isEmpty) {
    candidates = allMonuments;
  }

  // 2. Progressive radius search: 15km -> 35km -> 150km
  var recommendations = RecommendationEngine.rank(
    candidates: candidates,
    profile: userProfile,
    currentLat: userLat,
    currentLon: userLon,
    maxRadiusMeters: 15000,
  );

  if (recommendations.isEmpty) {
    recommendations = RecommendationEngine.rank(
      candidates: candidates,
      profile: userProfile,
      currentLat: userLat,
      currentLon: userLon,
      maxRadiusMeters: 35000,
    );
  }

  if (recommendations.isEmpty) {
    recommendations = RecommendationEngine.rank(
      candidates: candidates,
      profile: userProfile,
      currentLat: userLat,
      currentLon: userLon,
      maxRadiusMeters: 150000,
    );
  }

  if (recommendations.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No suitable alternative monuments found nearby.')),
      );
    }
    return;
  }

  // 3. Grab top pick
  final topPick = recommendations.first;

  // 4. Present Modal Sheet
  if (context.mounted) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reason == 'skip'
                    ? 'Alternative for your skipped stop'
                    : reason == 'finished_early'
                        ? 'Next nearby spot for your remaining time'
                        : 'Suggested Detour Spot',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              RecommendationCard(
                monument: topPick.monument,
                distanceMeters: topPick.distanceMeters,
                interestScore: topPick.interestScore,
                overallScore: topPick.score,
                actionLabel: reason == 'skip' ? 'Replace stop' : 'Add to trip',
                onAccept: () async {
                  // Write new stop to Firestore
                  final updatePort = RealItineraryUpdatePort();
                  if (reason == 'skip') {
                    await updatePort.replaceStop(
                      index: currentStopIndex,
                      monument: topPick.monument,
                    );
                  } else {
                    await updatePort.insertStopAfter(
                      afterIndex: currentStopIndex,
                      monument: topPick.monument,
                    );
                  }

                  if (modalContext.mounted) {
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added ${topPick.monument.name} to your itinerary!')),
                    );
                    onItineraryUpdated(); // Re-query active itinerary screen
                  }
                },
                onReject: () {
                  Navigator.pop(modalContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}