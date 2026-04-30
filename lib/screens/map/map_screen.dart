import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// HEADER
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Nearby Hospitals",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: Column(
        children: [

          /// 🗺 MAP PLACEHOLDER
          Container(
            height: 220,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "Map loading...",
                style: TextStyle(color: Colors.grey),
              ),
            ),

            /// TODO (TEAMMATE - MAP INTEGRATION):
            /// - Integrate Google Maps / OpenStreetMap
            /// - Show user location (GPS)
            /// - Plot nearby hospitals
            /// - Enable tap → directions
          ),

          /// LIST TITLE
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Nearby Facilities",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// 🏥 HOSPITAL LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [

                _hospitalItem("Dhangaon PHC", "2.3 km"),
                _hospitalItem("Pune Civil Hospital", "18 km"),
                _hospitalItem("Dr. Rathi Clinic", "4.1 km"),

                /// TODO (TEAMMATE - DATA SOURCE):
                /// Replace static list with:
                /// - GPS-based nearest hospitals
                /// - Offline DB or API
                /// - Sort by distance
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hospitalItem(String name, String distance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [

          const Icon(Icons.local_hospital, color: Colors.red),

          const SizedBox(width: 10),

          /// NAME
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          /// DISTANCE
          Text(
            distance,
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(width: 8),

          /// CALL BUTTON
          GestureDetector(
            onTap: () {

              /// TODO (TEAMMATE - CALL HOSPITAL):
              /// launchUrl(Uri.parse("tel:<hospital_number>"))

            },
            child: const Icon(Icons.call, color: Colors.blue),
          ),

          const SizedBox(width: 6),

          /// NAVIGATION ICON
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}