import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/itinerary_stop.dart';

class ItineraryStopCard extends StatelessWidget {
  final ItineraryStop stop;
  final int stopIndex;
  final VoidCallback onSkip;
  final VoidCallback onFinishEarly;
  final VoidCallback onRequestDetour;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isAvailable;

  const ItineraryStopCard({
    super.key,
    required this.stop,
    required this.stopIndex,
    required this.onSkip,
    required this.onFinishEarly,
    required this.onRequestDetour,
    this.onTap,
    this.isSelected = false,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppColors.terracotta
              : (isAvailable ? Colors.black12 : Colors.grey.shade300),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isAvailable ? Colors.white : Colors.grey.shade100,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stop Name & Time Range
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 20,
                          color: isAvailable ? AppColors.terracotta : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stop.placeName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isAvailable
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (stop.startTime.isNotEmpty && stop.endTime.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${stop.startTime} - ${stop.endTime}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.radio_button_checked,
                      size: 18,
                      color: AppColors.maroon,
                    ),
                  ],
                ],
              ),
              if (!isAvailable)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 28),
                  child: Text(
                    'Monument audio guide not available yet',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 4),

              // Action Trigger Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 1. SKIP BUTTON
                  TextButton.icon(
                    onPressed: onSkip,
                    icon: const Icon(
                      Icons.skip_next,
                      size: 18,
                      color: Colors.orange,
                    ),
                    label: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),

                  // 2. FINISH EARLY BUTTON
                  TextButton.icon(
                    onPressed: onFinishEarly,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.green,
                    ),
                    label: const Text(
                      'Finish Early',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),

                  // 3. DETOUR BUTTON
                  IconButton(
                    tooltip: 'Find Nearby Detour',
                    icon: const Icon(
                      Icons.explore_outlined,
                      color: Colors.indigo,
                    ),
                    onPressed: onRequestDetour,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}