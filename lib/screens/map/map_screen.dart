import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<Hospital> _nearbyHospitals = const [];
  List<Hospital> _filteredHospitals = const [];

  final _latController = TextEditingController();
  final _lngController = TextEditingController();

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
    _currentPosition = Position(
      latitude: 18.5204, longitude: 73.8567, timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, altitudeAccuracy: 0,
      heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
    );
    await _loadNearby();
    setState(() => _isLoading = false);
    _getLocationInBackground();
  }

  Future<void> _getLocationInBackground() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() => _currentPosition = pos);
        _loadNearby();
      }
    } catch (_) {}
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
    setState(() => _filteredHospitals = _nearbyHospitals);
  }

  void _onHospitalTap(Hospital h) {}

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
    _latController.text = _currentPosition?.latitude.toStringAsFixed(4) ?? '18.5204';
    _lngController.text = _currentPosition?.longitude.toStringAsFixed(4) ?? '73.8567';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Coordinates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Latitude', hintText: 'e.g. 18.5204'),
            ),
            TextField(
              controller: _lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Longitude', hintText: 'e.g. 73.8567'),
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
                    latitude: lat, longitude: lng, timestamp: DateTime.now(),
                    accuracy: 0, altitude: 0, altitudeAccuracy: 0,
                    heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
                  );
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
            onPressed: () {},
            tooltip: 'Center on my location',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildMapContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Loading map...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    final center = LatLng(
      _currentPosition?.latitude ?? 18.5204,
      _currentPosition?.longitude ?? 73.8567,
    );

    return Column(
      children: [
        // Debug info
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.yellow.shade100,
          child: Text(
            'Loc: ${center.latitude.toStringAsFixed(2)}, ${center.longitude.toStringAsFixed(2)} | Hospitals: ${_filteredHospitals.length}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        // Map
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFFD6EAF8),
            child: FlutterMap(
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
                const SimpleAttributionWidget(
                  source: Text('© CARTO © OpenStreetMap contributors'),
                  backgroundColor: Colors.white70,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
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
            ),
          ),
        ),
        // Hospital List
        Expanded(
          flex: 2,
          child: ListView.builder(
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
                  title: Text(h.name),
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
          ),
        ),
      ],
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
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Hospital Finder', style: TextStyle(color: Colors.white70)),
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
