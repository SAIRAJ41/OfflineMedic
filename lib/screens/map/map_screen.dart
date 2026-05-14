import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/hospital.dart';
import '../../services/hospital_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  String _loadingMessage = 'Getting location...';
  bool _isUsingDemoLocation = false;
  bool _locationDenied = false;
  // ignore: unused_field
  bool _gpsFailed = false;
  bool _mapTakingLonger = false;
  List<Hospital> _nearbyHospitals = const [];
  List<Hospital> _filteredHospitals = const [];

  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  // Demo fallback: Pune coordinates
  static const _demoLatitude = 18.5204;
  static const _demoLongitude = 73.8567;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Getting location...';
      _locationDenied = false;
      _gpsFailed = false;
      _isUsingDemoLocation = false;
      _mapTakingLonger = false;
    });

    // Try to get real GPS location
    final position = await _tryGetGPS();

    if (position != null) {
      _currentPosition = position;
      _isUsingDemoLocation = false;
      debugPrint('Map: Using real GPS: ${position.latitude}, ${position.longitude}');
    } else {
      // Don't auto-fallback to Pune. Let user decide.
      _currentPosition = null;
      _isUsingDemoLocation = false;
      _gpsFailed = true;
      debugPrint('Map: GPS failed or denied, waiting for user action');
    }

    setState(() {
      _loadingMessage = 'Loading nearby hospitals...';
    });

    // Always try to load hospital data from local DB
    await _loadNearby();

    setState(() {
      _loadingMessage = 'Loading map...';
      _isLoading = false;
    });

    _checkConnectivityForMap();
  }

  Future<void> _checkConnectivityForMap() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (mounted) setState(() => _mapTakingLonger = true);
      } else {
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted) setState(() => _mapTakingLonger = true);
        });
      }
    } catch (e) {
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) setState(() => _mapTakingLonger = true);
      });
    }
  }

  Future<Position?> _tryGetGPS() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Map: Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Map: Location permission denied');
        _locationDenied = true;
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('GPS is taking longer than expected.');
      });

      return pos;
    } catch (e) {
      debugPrint('Map: GPS error: $e');
      return null;
    }
  }

  Future<void> _useDemoLocation() async {
    setState(() {
      _currentPosition = Position(
        latitude: _demoLatitude,
        longitude: _demoLongitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _isUsingDemoLocation = true;
      _gpsFailed = false;
      _locationDenied = false;
    });
    await _loadNearby();
  }

  Future<void> _loadNearby() async {
    final current = _currentPosition;
    if (current == null) return;

    final hospitals = await HospitalService.loadHospitals();
    hospitals.sort((a, b) {
      final da = HospitalService.distanceKm(
        lat1: current.latitude, lon1: current.longitude,
        lat2: a.latitude, lon2: a.longitude,
      );
      final db = HospitalService.distanceKm(
        lat1: current.latitude, lon1: current.longitude,
        lat2: b.latitude, lon2: b.longitude,
      );
      return da.compareTo(db);
    });
    _nearbyHospitals = hospitals.take(50).toList(growable: false);
    _filteredHospitals = _nearbyHospitals;
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
    _latController.text = _currentPosition?.latitude.toStringAsFixed(4) ??
        _demoLatitude.toStringAsFixed(4);
    _lngController.text = _currentPosition?.longitude.toStringAsFixed(4) ??
        _demoLongitude.toStringAsFixed(4);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Coordinates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _latController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                  labelText: 'Latitude', hintText: 'e.g. 18.5204'),
            ),
            TextField(
              controller: _lngController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                  labelText: 'Longitude', hintText: 'e.g. 73.8567'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                  _isUsingDemoLocation = false;
                  _gpsFailed = false;
                  _locationDenied = false;
                });
                _loadNearby();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _drawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nearby Hospitals',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            onPressed: _showCoordinateInput,
            tooltip: 'Enter coordinates manually',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _init();
            },
            tooltip: 'Retry GPS location',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildMapContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              _loadingMessage,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    // Show message if GPS failed or denied, before user chooses demo
    if (_currentPosition == null) {
      return _buildLocationPrompt();
    }

    return Column(
      children: [
        // Location info bar
        Container(
          padding: const EdgeInsets.all(8),
          color: _isUsingDemoLocation ? Colors.orange.shade100 : Colors.green.shade100,
          child: Row(
            children: [
              Icon(
                _isUsingDemoLocation ? Icons.location_off : Icons.location_on,
                color: _isUsingDemoLocation ? Colors.orange : Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isUsingDemoLocation
                      ? 'Demo location: Pune (${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)})'
                      : 'GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isUsingDemoLocation ? Colors.orange.shade800 : Colors.green.shade800,
                  ),
                ),
              ),
              if (_isUsingDemoLocation)
                TextButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _init();
                  },
                  child: const Text('Retry GPS'),
                ),
            ],
          ),
        ),
        // Map (may fail to load tiles without internet, but hospitals list still works)
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Container(
                color: const Color(0xFFD6EAF8),
                child: _buildMapWidget(),
              ),
              if (_mapTakingLonger)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.orange.shade100.withOpacity(0.9),
                    child: Text(
                      'Map is taking longer to load. You can still view nearby hospitals below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Hospital List
        Expanded(
          flex: 2,
          child: _buildHospitalList(),
        ),
      ],
    );
  }

  Widget _buildMapWidget() {
    final center = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    try {
      return FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.offline_medic',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 40,
                height: 40,
                child: Icon(
                  _isUsingDemoLocation ? Icons.location_off : Icons.my_location,
                  color: _isUsingDemoLocation ? Colors.orange : Colors.blue,
                  size: 30,
                ),
              ),
              ..._filteredHospitals.take(20).map((h) {
                return Marker(
                  point: LatLng(h.latitude, h.longitude),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _onHospitalTap(h),
                    child: const Icon(
                      Icons.local_hospital,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      );
    } catch (e) {
      debugPrint('Map widget error: $e');
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Map tiles unavailable (offline mode)',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              'Showing ${_filteredHospitals.length} nearby hospitals below',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHospitalList() {
    if (_filteredHospitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_hospital, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No hospitals found nearby',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hospital data may need to be downloaded',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredHospitals.length,
      itemBuilder: (context, index) {
        final h = _filteredHospitals[index];
        final dKm = _currentPosition == null
            ? 0
            : HospitalService.distanceKm(
                lat1: _currentPosition!.latitude,
                lon1: _currentPosition!.longitude,
                lat2: h.latitude,
                lon2: h.longitude,
              );
        final distanceText = dKm < 1
            ? '${(dKm * 1000).toStringAsFixed(0)} m'
            : '${dKm.toStringAsFixed(1)} km';

        return Card(
          child: ListTile(
            leading: const Icon(Icons.local_hospital, color: Colors.red),
            title: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(distanceText),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.directions, color: Colors.green),
                  onPressed: () => _openDirections(h),
                ),
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.blue),
                  onPressed: () => _callHospital(h.phone),
                ),
              ],
            ),
            onTap: () => _onHospitalTap(h),
          ),
        );
      },
    );
  }

  Widget _buildLocationPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _locationDenied ? Icons.location_disabled : Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _locationDenied
                  ? 'Location permission required'
                  : 'Location unavailable',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _locationDenied
                  ? 'Please enable location permission to show nearby hospitals.'
                  : 'Location is taking longer than expected. You can retry or use the demo location (Pune) to preview the app.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_locationDenied) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003F87),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (!_locationDenied) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _init();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003F87),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _useDemoLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Use Demo Location: Pune'),
            ),
          ],
        ),
      ),
    );
  }

  void _onHospitalTap(Hospital h) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    h.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (h.type != null) ...[
              const SizedBox(height: 8),
              Text('Type: ${h.type}'),
            ],
            if (h.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Phone: ${h.phone}'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openDirections(h);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _callHospital(h.phone);
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade500],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_hospital, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  'OfflineMedic',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Hospital Finder',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_document),
            title: const Text('Input Triage'),
            onTap: () => Navigator.pushReplacementNamed(context, '/input'),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.map, color: Colors.blue),
            title: const Text(
              'Hospital Map',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            tileColor: Colors.blue.shade50,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}