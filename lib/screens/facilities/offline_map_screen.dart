import 'package:flutter/material.dart';

class OfflineMapScreen extends StatelessWidget {
  const OfflineMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [

            /// 🔵 HEADER + BACK BUTTON
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1F4A75),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Nearby Facilities",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "OFFLINE",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            /// BODY
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    /// 🔝 TOP CONTENT (MAP + INFO)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        const SizedBox(height: 10),

                        const Text(
                          "Offline map + cached data",
                          style: TextStyle(color: Colors.white54),
                        ),

                        const SizedBox(height: 18),

                        /// 🗺 MAP CARD
                        Container(
                          width: double.infinity,
                          height: 130,
                          decoration: BoxDecoration(
                            color: const Color(0xFF112240),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Center(
                            child: Text(
                              "Offline Map Loading...",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),

                          // TODO (TEAMMATE - MAP INTEGRATION):
                          // 1. Replace this container with actual map widget
                          // 2. Use OpenStreetMap / Mapbox / offline tiles
                          // 3. Load cached map tiles for offline usage
                          // 4. Center map on user's GPS location
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          "Nearest facilities",
                          style: TextStyle(color: Colors.white70),
                        ),

                        const SizedBox(height: 10),

                        /// LIST (STATIC NOW → DYNAMIC LATER)
                        const _FacilityItem(
                          name: "Dhangaon PHC",
                          distance: "2.3 km",
                        ),
                        const _FacilityItem(
                          name: "Pune Civil Hospital",
                          distance: "18 km",
                        ),
                        const _FacilityItem(
                          name: "Dr. Rathi Clinic",
                          distance: "4.1 km",
                        ),

                        // TODO (TEAMMATE - DATA INTEGRATION):
                        // Replace static list with:
                        // - GPS-based nearest hospitals
                        // - Offline cached DB (SQLite / JSON)
                        // - Sort by distance dynamically
                      ],
                    ),

                    /// 🔻 PUSH CONTENT DOWN (FOR BALANCE LIKE SKELETON)
                    const Spacer(),

                    /// 🔽 FUTURE ACTION AREA (OPTIONAL EXTENSION)
                    // TODO (TEAMMATE - OPTIONAL):
                    // Add:
                    // - "Navigate" button (open maps intent)
                    // - "Call hospital" primary CTA
                    // - Directions preview
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 FACILITY ITEM
class _FacilityItem extends StatelessWidget {
  final String name;
  final String distance;

  const _FacilityItem({
    required this.name,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            distance,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 12),

          GestureDetector(
            onTap: () {
              // TODO (TEAMMATE - CALL INTEGRATION):
              // Use url_launcher:
              // launchUrl(Uri.parse("tel:<hospital_number>"))
            },
            child: const Icon(Icons.call, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}