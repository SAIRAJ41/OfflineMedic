class Hospital {
  final int? id;
  final String name;
  final String? type;
  final String? city;
  final String? state;
  final String country;
  final double latitude;
  final double longitude;
  final String phone;

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
    );
  }
}
