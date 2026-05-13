class Hospital {
  final int? id;
  final String name;
  final String? type; // Government, Private, NGO, etc.
  final String? city;
  final String? state;
  final String country;
  final double latitude;
  final double longitude;
  final String phone;
  final List<String>
  specializations; // e.g., ['Cardiology', 'Trauma', 'Pediatrics']
  final double rating; // 1-5 stars
  final int availableBeds;
  final List<String>
  emergencyServices; // e.g., ['24/7', 'Trauma Center', 'ICU']
  final String? operatingHours;
  final String? imageUrl;
  final int totalBeds;
  final String? website;
  final int occupancyRate; // 0-100 percentage

  const Hospital({
    this.id,
    required this.name,
    this.type,
    this.city,
    this.state,
    this.country = 'IN',
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.specializations = const [],
    this.rating = 3.5,
    this.availableBeds = 0,
    this.emergencyServices = const [],
    this.operatingHours,
    this.imageUrl,
    this.totalBeds = 0,
    this.website,
    this.occupancyRate = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'city': city,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'specializations': specializations,
      'rating': rating,
      'availableBeds': availableBeds,
      'emergencyServices': emergencyServices,
      'operatingHours': operatingHours,
      'imageUrl': imageUrl,
      'totalBeds': totalBeds,
      'website': website,
      'occupancyRate': occupancyRate,
    };
  }

  factory Hospital.fromMap(Map<String, dynamic> map) {
    return Hospital(
      id: map['id'] as int?,
      name: (map['name'] ?? '').toString(),
      type: map['type']?.toString(),
      city: map['city']?.toString(),
      state: map['state']?.toString(),
      country: (map['country'] ?? 'IN').toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      phone: (map['phone'] ?? '').toString(),
      specializations:
          (map['specializations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rating: (map['rating'] as num?)?.toDouble() ?? 3.5,
      availableBeds: (map['availableBeds'] as num?)?.toInt() ?? 0,
      emergencyServices:
          (map['emergencyServices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      operatingHours: map['operatingHours']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      totalBeds: (map['totalBeds'] as num?)?.toInt() ?? 0,
      website: map['website']?.toString(),
      occupancyRate: (map['occupancyRate'] as num?)?.toInt() ?? 0,
    );
  }
}
