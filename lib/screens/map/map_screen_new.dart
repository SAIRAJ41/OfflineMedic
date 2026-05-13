import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/hospital.dart';
import '../../services/hospital_service.dart';
import '../setup/setup_screen.dart';

class MapScreenNew extends StatefulWidget {
  const MapScreenNew({super.key});

  @override
  State<MapScreenNew> createState() => _MapScreenNewState();
}

class _MapScreenNewState extends State<MapScreenNew> {
  final MapController _mapController = MapController();

  Position? _currentPosition;
  bool _isLoading = true;
  List<Hospital> _allHospitals = const [];
  List<Hospital> _filteredHospitals = const [];

  // Filter states
  String _selectedType = '';
  String _selectedSpecialization = '';
  double _minRating = 0;
  String _searchQuery = '';
  String _sortBy = 'distance'; // distance, rating, name

  // Filter options
  Set<String> _hospitalTypes = {};
  Set<String> _specializations = {};

  final _searchController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  /// Shown after tapping "my location": ring on map + brighter markers within [_nearbyHighlightKm].
  bool _showNearbyRadiusRing = false;
  static const double _nearbyHighlightKm = 28.0;
  static const double _zoomAutoLocate = 15.2;
  static const double _zoomMyLocationButton = 17.2;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Set default location to Pune, India
    _currentPosition = Position(
      latitude: 18.5204,
      longitude: 73.8567,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    try {
      await _loadHospitals();
    } catch (_) {
      // Asset missing / parse error — still show map shell
    }
    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_updateUserLocation(
            showUserFeedback: false,
            tightFocus: false,
          ));
        }
      });
    }
  }

  void _centerMapOnUser(LatLng target, {double zoom = _zoomAutoLocate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(target, zoom);
    });
  }

  /// Requests permission if needed, reads GPS, updates marker + list sort, pans map.
  /// [tightFocus]: stronger zoom + nearby hospital highlight ring (my-location button).
  Future<bool> _updateUserLocation({
    required bool showUserFeedback,
    bool tightFocus = false,
  }) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (showUserFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is off. Allow it to center the map on you.',
              ),
            ),
          );
        }
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        if (showUserFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location is blocked for this app. Open Settings to allow.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: Geolocator.openAppSettings,
              ),
            ),
          );
        }
        return false;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showUserFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Turn on device location (GPS) to see where you are.',
              ),
              action: SnackBarAction(
                label: 'Location',
                onPressed: Geolocator.openLocationSettings,
              ),
            ),
          );
        }
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return false;
      setState(() {
        _currentPosition = pos;
        if (tightFocus) _showNearbyRadiusRing = true;
      });
      _applyFilters();
      _centerMapOnUser(
        LatLng(pos.latitude, pos.longitude),
        zoom: tightFocus ? _zoomMyLocationButton : _zoomAutoLocate,
      );
      if (tightFocus && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Zoomed to you. Hospitals within ~28 km are highlighted on the map; list is sorted by distance (India-wide data).',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return true;
    } catch (e) {
      if (showUserFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _loadHospitals() async {
    final raw = await HospitalService.loadHospitals();
    _allHospitals = HospitalService.filterIndiaBounds(raw);
    _hospitalTypes = HospitalService.getHospitalTypes(_allHospitals);
    _specializations = HospitalService.getSpecializations(_allHospitals);

    _applyFilters();
  }

  void _applyFilters() {
    List<Hospital> result = List.from(_allHospitals);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result = HospitalService.search(result, _searchQuery);
    }

    // Apply type filter
    if (_selectedType.isNotEmpty) {
      result = HospitalService.filterByType(result, _selectedType);
    }

    // Apply specialization filter
    if (_selectedSpecialization.isNotEmpty) {
      result = HospitalService.filterBySpecialization(
        result,
        _selectedSpecialization,
      );
    }

    // Apply rating filter
    if (_minRating > 0) {
      result = HospitalService.filterByRating(result, _minRating);
    }

    // Apply sorting
    if (_currentPosition != null) {
      HospitalService.sortByDistance(
        result,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );
    }

    if (_sortBy == 'rating') {
      HospitalService.sortByRating(result);
    }

    setState(() => _filteredHospitals = result);
  }

  Color _getMarkerColor(Hospital hospital) {
    if (hospital.type?.toLowerCase() == 'government') {
      return Colors.red;
    } else if (hospital.type?.toLowerCase() == 'private') {
      return Colors.blue;
    }
    return Colors.orange; // NGO or other
  }

  IconData _getMarkerIcon(Hospital hospital) {
    if (hospital.emergencyServices.contains('Trauma Center')) {
      return Icons.emergency;
    } else if (hospital.emergencyServices.contains('24/7')) {
      return Icons.schedule;
    }
    return Icons.local_hospital;
  }

  bool _isHospitalNearbyHighlight(Hospital h) {
    final u = _currentPosition;
    if (u == null || !_showNearbyRadiusRing) return false;
    return HospitalService.isWithinKm(
      h,
      userLat: u.latitude,
      userLng: u.longitude,
      maxKm: _nearbyHighlightKm,
    );
  }

  /// Draw farther hospitals first so nearby markers paint on top in clusters.
  List<Hospital> _hospitalsOrderedForMapMarkers() {
    if (!_showNearbyRadiusRing || _currentPosition == null) {
      return _filteredHospitals;
    }
    final u = _currentPosition!;
    final nearby = <Hospital>[];
    final rest = <Hospital>[];
    for (final h in _filteredHospitals) {
      if (HospitalService.isWithinKm(
        h,
        userLat: u.latitude,
        userLng: u.longitude,
        maxKm: _nearbyHighlightKm,
      )) {
        nearby.add(h);
      } else {
        rest.add(h);
      }
    }
    return [...rest, ...nearby];
  }

  Marker _buildHospitalMarker(Hospital h) {
    final highlight = _isHospitalNearbyHighlight(h);
    final size = highlight ? 46.0 : 34.0;
    final iconSz = highlight ? 22.0 : 18.0;
    final base = _getMarkerColor(h);
    return Marker(
      point: LatLng(h.latitude, h.longitude),
      width: highlight ? 52 : 40,
      height: highlight ? 52 : 40,
      child: GestureDetector(
        onTap: () => _showHospitalDetails(h),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (highlight)
              Container(
                width: size + 12,
                height: size + 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.28),
                  border: Border.all(color: Colors.amber.shade800, width: 2),
                ),
              ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: base,
                border: Border.all(
                  color: highlight ? Colors.amber.shade700 : Colors.white,
                  width: highlight ? 3 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (highlight ? Colors.amber : base)
                        .withValues(alpha: highlight ? 0.55 : 0.42),
                    blurRadius: highlight ? 14 : 6,
                    spreadRadius: highlight ? 1 : 0,
                  ),
                ],
              ),
              child: Icon(
                _getMarkerIcon(h),
                color: Colors.white,
                size: iconSz,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHospitalDetails(Hospital hospital) {
    final distance = _currentPosition == null
        ? 0.0
        : HospitalService.distanceKm(
            lat1: _currentPosition!.latitude,
            lon1: _currentPosition!.longitude,
            lat2: hospital.latitude,
            lon2: hospital.longitude,
          );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hospital Name
              Text(
                hospital.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Rating and Type
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${hospital.rating}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getMarkerColor(hospital).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hospital.type ?? 'Other',
                      style: TextStyle(
                        color: _getMarkerColor(hospital),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Distance
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Distance',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          distance < 1
                              ? '${(distance * 1000).toStringAsFixed(0)} m'
                              : '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location Details
              if (hospital.city != null || hospital.state != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${hospital.city ?? ''}, ${hospital.state ?? ''}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),

              // Specializations
              if (hospital.specializations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Specializations',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hospital.specializations
                            .map(
                              (spec) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  spec,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),

              // Emergency Services
              if (hospital.emergencyServices.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Services',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hospital.emergencyServices
                            .map(
                              (service) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      service,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),

              // Beds Info
              if (hospital.totalBeds > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bed Availability',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Beds',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${hospital.totalBeds}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Available',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${hospital.availableBeds}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Occupancy',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${hospital.occupancyRate}%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Operating Hours
              if (hospital.operatingHours != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Operating Hours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hospital.operatingHours ?? 'Not available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _callHospital(hospital.phone),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openDirections(hospital),
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDirections(Hospital h) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${h.latitude},${h.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callHospital(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showCoordinateInput() {
    _latController.text =
        _currentPosition?.latitude.toStringAsFixed(4) ?? '18.5204';
    _lngController.text =
        _currentPosition?.longitude.toStringAsFixed(4) ?? '73.8567';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Coordinates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g. 18.5204',
              ),
            ),
            TextField(
              controller: _lngController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g. 73.8567',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(_latController.text.trim());
              final lng = double.tryParse(_lngController.text.trim());
              if (lat != null && lng != null) {
                setState(() {
                  _currentPosition = Position(
                    latitude: lat,
                    longitude: lng,
                    timestamp: DateTime.now(),
                    accuracy: 0,
                    altitude: 0,
                    altitudeAccuracy: 0,
                    heading: 0,
                    headingAccuracy: 0,
                    speed: 0,
                    speedAccuracy: 0,
                  );
                });
                _applyFilters();
                _centerMapOnUser(LatLng(lat, lng), zoom: _zoomMyLocationButton);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Hospital Type Filter
              const Text(
                'Hospital Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', ..._hospitalTypes].map((type) {
                  final isSelected = type == 'All'
                      ? _selectedType.isEmpty
                      : _selectedType == type;
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type == 'All' ? '' : type;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Specialization Filter
              const Text(
                'Specialization',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', ..._specializations.take(10)].map((spec) {
                  final isSelected = spec == 'All'
                      ? _selectedSpecialization.isEmpty
                      : _selectedSpecialization == spec;
                  return FilterChip(
                    label: Text(spec),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSpecialization = spec == 'All' ? '' : spec;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Rating Filter
              const Text(
                'Minimum Rating',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _minRating,
                min: 0,
                max: 5,
                divisions: 5,
                label: _minRating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _minRating = value);
                },
              ),
              const SizedBox(height: 16),

              // Sorting
              const Text(
                'Sort By',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Distance'),
                      value: 'distance',
                      groupValue: _sortBy,
                      onChanged: (value) {
                        setState(() => _sortBy = value ?? 'distance');
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Rating'),
                      value: 'rating',
                      groupValue: _sortBy,
                      onChanged: (value) {
                        setState(() => _sortBy = value ?? 'distance');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Apply Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = '';
                          _selectedSpecialization = '';
                          _minRating = 0;
                          _sortBy = 'distance';
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        this.setState(() {
                          _selectedType = _selectedType;
                          _selectedSpecialization = _selectedSpecialization;
                          _minRating = _minRating;
                          _sortBy = _sortBy;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Hospital Finder',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'setup') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SetupScreen(),
                  ),
                );
              } else if (value == 'input') {
                Navigator.of(context).pushNamed('/input');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'setup',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.download_outlined),
                  title: Text('Download AI model'),
                  subtitle: Text('Optional — for triage'),
                ),
              ),
              const PopupMenuItem(
                value: 'input',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.medical_services_outlined),
                  title: Text('Triage input'),
                  subtitle: Text('Needs downloaded model'),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterSheet,
            tooltip: 'Filters',
          ),
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            onPressed: _showCoordinateInput,
            tooltip: 'Enter coordinates manually',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              unawaited(
                _updateUserLocation(
                  showUserFeedback: true,
                  tightFocus: true,
                ),
              );
            },
            tooltip: 'Center on my location',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final center = LatLng(
      _currentPosition?.latitude ?? 18.5204,
      _currentPosition?.longitude ?? 73.8567,
    );

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search hospitals...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),

        // Active Filters Display
        if (_selectedType.isNotEmpty ||
            _selectedSpecialization.isNotEmpty ||
            _minRating > 0 ||
            _showNearbyRadiusRing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_showNearbyRadiusRing)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        avatar: Icon(Icons.near_me, size: 18, color: Colors.teal[800]),
                        label: Text('Nearby (~${_nearbyHighlightKm.round()} km)'),
                        onDeleted: () {
                          setState(() => _showNearbyRadiusRing = false);
                        },
                      ),
                    ),
                  if (_selectedType.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Type: $_selectedType'),
                        onDeleted: () {
                          setState(() => _selectedType = '');
                          _applyFilters();
                        },
                      ),
                    ),
                  if (_selectedSpecialization.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Spec: $_selectedSpecialization'),
                        onDeleted: () {
                          setState(() => _selectedSpecialization = '');
                          _applyFilters();
                        },
                      ),
                    ),
                  if (_minRating > 0)
                    Chip(
                      label: Text('Rating: ≥${_minRating.toStringAsFixed(1)}'),
                      onDeleted: () {
                        setState(() => _minRating = 0);
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),
          ),

        // Map
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFFD6EAF8),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12.0,
                minZoom: 3.5,
                maxZoom: 20,
                keepAlive: true,
                backgroundColor: const Color(0xFFD6EAF8),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.offlinemedic.app',
                  maxNativeZoom: 20,
                  keepBuffer: 2,
                ),
                if (_currentPosition != null && _showNearbyRadiusRing)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        radius: _nearbyHighlightKm * 1000,
                        useRadiusInMeter: true,
                        color: const Color(0xFF2196F3).withValues(alpha: 0.11),
                        borderStrokeWidth: 2,
                        borderColor: const Color(0xFF0D47A1).withValues(alpha: 0.42),
                      ),
                    ],
                  ),
                const SimpleAttributionWidget(
                  source: Text('© OpenStreetMap contributors'),
                  backgroundColor: Colors.white70,
                ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 68,
                    size: const Size(40, 40),
                    markers: [
                      Marker(
                        point: center,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade700,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.55),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      ..._hospitalsOrderedForMapMarkers().map(_buildHospitalMarker),
                    ],
                    polygonOptions: const PolygonOptions(
                      borderColor: Colors.blueGrey,
                      borderStrokeWidth: 2,
                      color: Colors.black12,
                    ),
                    centerMarkerOnClick: true,
                    showPolygon: false,
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.blue,
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

        // Hospital List
        Expanded(
          flex: 2,
          child: _filteredHospitals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hospitals found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredHospitals.length,
                  itemBuilder: (context, index) {
                    final h = _filteredHospitals[index];
                    final nearbyList = _isHospitalNearbyHighlight(h);
                    final distance = _currentPosition == null
                        ? 0.0
                        : HospitalService.distanceKm(
                            lat1: _currentPosition!.latitude,
                            lon1: _currentPosition!.longitude,
                            lat2: h.latitude,
                            lon2: h.longitude,
                          );

                    return GestureDetector(
                      onTap: () => _showHospitalDetails(h),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: nearbyList ? 4 : 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: nearbyList
                              ? BorderSide(
                                  color: Colors.amber.shade800,
                                  width: 2,
                                )
                              : BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Hospital Icon
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getMarkerColor(h).withValues(alpha: 0.2),
                                ),
                                child: Icon(
                                  _getMarkerIcon(h),
                                  color: _getMarkerColor(h),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Hospital Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${h.rating}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          h.type ?? 'Other',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      distance < 1
                                          ? '${(distance * 1000).toStringAsFixed(0)} m away'
                                          : '${distance.toStringAsFixed(1)} km away',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Action Buttons
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _callHospital(h.phone),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green.shade100,
                                      ),
                                      child: Icon(
                                        Icons.call,
                                        color: Colors.green[700],
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _openDirections(h),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue.shade100,
                                      ),
                                      child: Icon(
                                        Icons.directions,
                                        color: Colors.blue[700],
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }
}
