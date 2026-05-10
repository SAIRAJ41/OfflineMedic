// lib/services/database_service.dart
// Central SQLite database for OfflineMedic.
// Manages: cases, emergency_cards, emergency_numbers, medicine_brands,
//          hospitals, and RAG knowledge — all offline.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/case_history.dart';
import '../models/triage_result.dart';
import '../models/hospital.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  /// True after a successful [initialize] call.
  bool get isReady => _db != null;

  // ════════════════════════════════════════════════════════════
  //  INITIALISE
  // ════════════════════════════════════════════════════════════

  Future<bool> initialize() async {
    try {
      final dbPath = p.join(await getDatabasesPath(), 'offlinemedic.db');

      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: _createTables,
      );

      await _seedIfFirstLaunch();

      print('✅ DatabaseService ready');
      return true;
    } catch (e) {
      print('❌ DatabaseService init failed: $e');
      return false; // app continues without DB
    }
  }

  // ════════════════════════════════════════════════════════════
  //  CREATE TABLES
  // ════════════════════════════════════════════════════════════

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cases (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        input_text      TEXT    NOT NULL,
        input_type      TEXT    DEFAULT 'text',
        image_path      TEXT,
        triage_level    TEXT    NOT NULL,
        condition       TEXT,
        confidence      TEXT,
        do_now          TEXT,
        do_not          TEXT,
        red_flags       TEXT,
        call_now        INTEGER DEFAULT 0,
        emergency_number TEXT   DEFAULT '108',
        raw_response    TEXT,
        notes           TEXT,
        created_at      TEXT    DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE emergency_cards (
        id          TEXT PRIMARY KEY,
        title       TEXT NOT NULL,
        icon        TEXT,
        do_now      TEXT,
        do_not      TEXT,
        red_flags   TEXT,
        call_number TEXT DEFAULT 'local_emergency',
        version     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE emergency_numbers (
        country    TEXT PRIMARY KEY,
        code       TEXT,
        ambulance  TEXT,
        police     TEXT,
        fire       TEXT,
        general    TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE medicine_brands (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        brand_name   TEXT NOT NULL,
        generic_name TEXT,
        common_use   TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE hospitals (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT NOT NULL,
        type      TEXT,
        city      TEXT,
        state     TEXT,
        country   TEXT DEFAULT 'IN',
        latitude  REAL,
        longitude REAL,
        phone     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE knowledge (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        condition TEXT NOT NULL,
        keywords  TEXT NOT NULL,
        facts     TEXT NOT NULL
      )
    ''');
  }

  // ════════════════════════════════════════════════════════════
  //  SEED DATA (first launch only)
  // ════════════════════════════════════════════════════════════

  Future<void> _seedIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('db_seeded') == true) return;

    print('📦 First launch — seeding database...');

    bool allSucceeded = true;

    try {
      await _seedEmergencyCards();
    } catch (e) {
      allSucceeded = false;
      print('⚠️ Cards: $e');
    }

    try {
      await _seedEmergencyNumbers();
    } catch (e) {
      allSucceeded = false;
      print('⚠️ Numbers: $e');
    }

    try {
      await _seedMedicineBrands();
    } catch (e) {
      allSucceeded = false;
      print('⚠️ Medicines: $e');
    }

    try {
      await _seedHospitals();
    } catch (e) {
      allSucceeded = false;
      print('⚠️ Hospitals: $e');
    }

    try {
      await _seedRagKnowledge();
    } catch (e) {
      allSucceeded = false;
      print('⚠️ RAG: $e');
    }

    if (allSucceeded) {
      await prefs.setBool('db_seeded', true);
      print('✅ All data seeded successfully');
    } else {
      print('⚠️ Some seeds failed — will retry next launch');
    }
  }

  Future<void> _seedEmergencyCards() async {
    final raw = await rootBundle.loadString('data/emergency_cards.json');
    final Map<String, dynamic> decoded = jsonDecode(raw);
    final List cards = decoded['cards'] ?? [];

    final batch = _db!.batch();
    for (final card in cards) {
      batch.insert('emergency_cards', {
        'id': card['id'],
        'title': card['title'],
        'icon': card['icon'],
        'do_now': jsonEncode(card['do_now']),
        'do_not': jsonEncode(card['do_not']),
        'red_flags': jsonEncode(card['red_flags']),
        'call_number': card['call_number'],
        'version': card['version'],
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    print('  ✅ ${cards.length} emergency cards seeded');
  }

  Future<void> _seedEmergencyNumbers() async {
    final raw = await rootBundle.loadString('data/emergency_numbers.json');
    final Map<String, dynamic> decoded = jsonDecode(raw);
    final List countries = decoded['countries'] ?? [];

    final batch = _db!.batch();
    for (final c in countries) {
      batch.insert('emergency_numbers', {
        'country': c['country'],
        'code': c['code'],
        'ambulance': c['ambulance'],
        'police': c['police'],
        'fire': c['fire'],
        'general': c['general'],
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    print('  ✅ ${countries.length} emergency numbers seeded');
  }

  Future<void> _seedMedicineBrands() async {
    final raw = await rootBundle.loadString('data/medicine_brands.json');
    final Map<String, dynamic> decoded = jsonDecode(raw);
    final List brands = decoded['brands'] ?? [];

    final batch = _db!.batch();
    for (final b in brands) {
      batch.insert('medicine_brands', {
        'brand_name': b['brand_name'],
        'generic_name': b['generic_name'],
        'common_use': b['common_use'],
      });
    }
    await batch.commit(noResult: true);
    print('  ✅ ${brands.length} medicine brands seeded');
  }

  Future<void> _seedHospitals() async {
    final raw = await rootBundle.loadString(
      'data/Hospitals_data/hopitals_coordinates.json',
    );
    final dynamic decoded = jsonDecode(raw);

    final List items = decoded is List
        ? decoded
        : decoded is Map && decoded['hospitals'] is List
            ? decoded['hospitals'] as List
            : [];

    final batch = _db!.batch();
    for (final it in items) {
      if (it is! Map) continue;

      final name = (it['name'] ??
              it['hospital_name'] ??
              it['hospital'] ??
              it['facility'] ??
              '')
          .toString()
          .trim();

      final lat = _parseDouble(
          it['lat'] ?? it['latitude'] ?? it['Lat'] ?? it['Latitude']);
      final lon = _parseDouble(
          it['lon'] ?? it['lng'] ?? it['longitude'] ?? it['Lon'] ?? it['Longitude']);

      if (name.isEmpty || lat == null || lon == null) continue;

      batch.insert('hospitals', {
        'name': name,
        'type': (it['type'] ?? it['facility_type'] ?? '').toString().trim(),
        'city': (it['city'] ?? it['district'] ?? '').toString().trim(),
        'state': (it['state'] ?? '').toString().trim(),
        'country': 'IN',
        'latitude': lat,
        'longitude': lon,
        'phone': (it['phone'] ?? it['contact'] ?? it['number'] ?? '')
            .toString()
            .trim(),
      });
    }
    await batch.commit(noResult: true);
    print('  ✅ Hospitals seeded');
  }

  Future<void> _seedRagKnowledge() async {
    // Seed a base set of medical knowledge entries for RAG retrieval.
    // These cover the most common conditions the app handles.
    final knowledgeEntries = [
      {
        'condition': 'Heart Attack',
        'keywords': 'chest pain,heart,cardiac,breathless,sweating,arm pain',
        'facts':
            'A heart attack occurs when blood flow to part of the heart muscle is blocked. '
                'Symptoms include chest pain or pressure, pain radiating to left arm or jaw, '
                'shortness of breath, cold sweat, nausea. This is a life-threatening emergency. '
                'Call 108 immediately. Give aspirin only if not allergic and advised by protocol.',
      },
      {
        'condition': 'Snake Bite',
        'keywords': 'snake,bite,venom,fang,swelling',
        'facts':
            'Keep the patient calm and still. Immobilize the bitten limb below heart level. '
                'Do NOT apply a tourniquet, cut the wound, or attempt to suck venom. '
                'Remove rings and tight items near bite. Get to hospital for antivenom. '
                'Note the snake appearance if safe. Time of bite is critical information.',
      },
      {
        'condition': 'Severe Bleeding',
        'keywords': 'bleeding,blood,wound,cut,hemorrhage,laceration',
        'facts':
            'Apply firm direct pressure with a clean cloth. Do not remove the first cloth if soaked. '
                'Elevate the injured area above heart level if possible. '
                'If bleeding spurts or does not stop, this is arterial bleeding — call emergency. '
                'Do not probe or remove embedded objects.',
      },
      {
        'condition': 'Burns',
        'keywords': 'burn,scald,fire,hot,blister',
        'facts':
            'Cool the burn under running water for at least 20 minutes. '
                'Do NOT apply ice, butter, toothpaste, or oils. Do not burst blisters. '
                'Cover loosely with clean cling film. Burns on face, hands, feet, genitals or '
                'larger than the palm are serious — seek medical help immediately.',
      },
      {
        'condition': 'Fever in Children',
        'keywords': 'fever,child,baby,temperature,hot,paracetamol,calpol',
        'facts':
            'Fever above 100.4°F (38°C) in children. Give age-appropriate paracetamol. '
                'Keep the child hydrated. Do not over-wrap. Tepid sponging can help. '
                'Seek urgent help if: fever above 104°F, child under 3 months, rash appears, '
                'child is unusually drowsy, or seizure occurs.',
      },
      {
        'condition': 'Choking',
        'keywords': 'choke,choking,airway,blocked,cannot breathe,gagging',
        'facts':
            'If the person cannot cough, speak, or breathe: give 5 back blows between shoulder blades. '
                'If still choking, give 5 abdominal thrusts (Heimlich maneuver). '
                'For infants under 1 year: 5 back blows + 5 chest thrusts. '
                'Call emergency if obstruction does not clear.',
      },
      {
        'condition': 'Seizure',
        'keywords': 'seizure,convulsion,fit,epilepsy,shaking',
        'facts':
            'Clear the area of hard objects. Protect the head with soft material. '
                'Do NOT restrain the person or put anything in their mouth. '
                'Time the seizure. Turn on side after movements stop. '
                'Call emergency if seizure lasts more than 5 minutes or person does not wake.',
      },
      {
        'condition': 'Dehydration',
        'keywords': 'dehydration,diarrhea,vomiting,ors,dry mouth,thirst',
        'facts':
            'Give small frequent sips of ORS (Oral Rehydration Solution) or clean water. '
                'Signs: dry mouth, sunken eyes, reduced urine, dizziness. '
                'For children: continue breastfeeding, give ORS after each loose stool. '
                'Severe dehydration (confusion, no urine, cold hands) needs hospital IV fluids.',
      },
      {
        'condition': 'Drug Interaction',
        'keywords': 'medicine,drug,tablet,interaction,paracetamol,ibuprofen,aspirin',
        'facts':
            'Common dangerous combinations: Blood thinners (warfarin/ecosprin) + aspirin/ibuprofen '
                'increases bleeding risk. Metformin + alcohol can cause lactic acidosis. '
                'Always check if patient is on blood pressure or diabetes medication before '
                'giving any new medicine. When in doubt, do not give additional medication.',
      },
      {
        'condition': 'Allergic Reaction',
        'keywords': 'allergy,allergic,rash,hives,swelling,anaphylaxis,epipen',
        'facts':
            'Mild allergy: antihistamine (cetirizine). Severe anaphylaxis: use EpiPen if available. '
                'Signs of anaphylaxis: throat swelling, difficulty breathing, widespread rash, '
                'dizziness, collapse. Lay person flat, raise legs. Call 108 immediately. '
                'Do not give food or drink during severe reaction.',
      },
    ];

    final batch = _db!.batch();
    for (final entry in knowledgeEntries) {
      batch.insert('knowledge', entry,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    print('  ✅ ${knowledgeEntries.length} RAG knowledge entries seeded');
  }

  // ════════════════════════════════════════════════════════════
  //  CASE HISTORY
  // ════════════════════════════════════════════════════════════

  /// Saves a triage result. Returns true on success, false on failure.
  Future<bool> saveCase(
    TriageResult result,
    String inputText,
    String inputType, {
    String? imagePath,
    String? rawResponse,
  }) async {
    if (_db == null) return false;
    try {
      final caseEntry = CaseHistory(
        inputText: inputText,
        inputType: inputType,
        imagePath: imagePath,
        result: result,
        rawResponse: rawResponse,
      );
      await _db!.insert('cases', caseEntry.toMap());
      return true;
    } catch (e) {
      print('❌ saveCase failed: $e');
      return false;
    }
  }

  /// Returns recent cases, newest first.
  Future<List<CaseHistory>> getCases({int limit = 10, String? triageLevel}) async {
    if (_db == null) return [];
    try {
      String? where;
      List<dynamic>? whereArgs;
      if (triageLevel != null) {
        where = 'triage_level = ?';
        whereArgs = [triageLevel];
      }
      final rows = await _db!.query(
        'cases',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return rows.map((r) => CaseHistory.fromMap(r)).toList();
    } catch (e) {
      print('❌ getCases failed: $e');
      return [];
    }
  }

  /// Returns cases created today.
  Future<List<CaseHistory>> getCasesToday() async {
    if (_db == null) return [];
    try {
      final rows = await _db!.query(
        'cases',
        where: "date(created_at) = date('now')",
        orderBy: 'created_at DESC',
      );
      return rows.map((r) => CaseHistory.fromMap(r)).toList();
    } catch (e) {
      print('❌ getCasesToday failed: $e');
      return [];
    }
  }

  /// Dashboard summary: total, urgent, moderate, mild counts.
  Future<Map<String, int>> getDashboardSummary() async {
    final defaults = {'total': 0, 'urgent': 0, 'moderate': 0, 'mild': 0};
    if (_db == null) return defaults;
    try {
      final total =
          Sqflite.firstIntValue(await _db!.rawQuery('SELECT COUNT(*) FROM cases')) ?? 0;
      final urgent = Sqflite.firstIntValue(await _db!.rawQuery(
              "SELECT COUNT(*) FROM cases WHERE triage_level = 'URGENT'")) ??
          0;
      final moderate = Sqflite.firstIntValue(await _db!.rawQuery(
              "SELECT COUNT(*) FROM cases WHERE triage_level = 'MODERATE'")) ??
          0;
      final mild = Sqflite.firstIntValue(await _db!.rawQuery(
              "SELECT COUNT(*) FROM cases WHERE triage_level = 'MILD'")) ??
          0;
      return {'total': total, 'urgent': urgent, 'moderate': moderate, 'mild': mild};
    } catch (e) {
      print('❌ getDashboardSummary failed: $e');
      return defaults;
    }
  }

  /// Returns case counts for the last 7 days (for bar chart).
  /// Returns a list of 7 doubles, index 0 = 6 days ago, index 6 = today.
  Future<List<double>> getWeeklyCounts() async {
    if (_db == null) return List.filled(7, 0);
    try {
      final rows = await _db!.rawQuery('''
        SELECT date(created_at) AS day, COUNT(*) AS count
        FROM cases
        WHERE created_at >= date('now', '-6 days')
        GROUP BY date(created_at)
        ORDER BY day ASC
      ''');

      // Build a map of day → count
      final Map<String, int> dayMap = {};
      for (final row in rows) {
        dayMap[row['day'] as String] = row['count'] as int;
      }

      // Fill 7 days (today - 6 ... today)
      final now = DateTime.now();
      final result = <double>[];
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final key =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        result.add((dayMap[key] ?? 0).toDouble());
      }
      return result;
    } catch (e) {
      print('❌ getWeeklyCounts failed: $e');
      return List.filled(7, 0);
    }
  }

  /// Add follow-up notes to a case.
  Future<bool> addCaseNotes(int caseId, String notes) async {
    if (_db == null) return false;
    try {
      await _db!.update('cases', {'notes': notes},
          where: 'id = ?', whereArgs: [caseId]);
      return true;
    } catch (e) {
      print('❌ addCaseNotes failed: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  EMERGENCY CARDS
  // ════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getEmergencyCards() async {
    if (_db == null) return [];
    try {
      return await _db!.query('emergency_cards');
    } catch (e) {
      print('❌ getEmergencyCards failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getEmergencyCard(String id) async {
    if (_db == null) return null;
    try {
      final rows =
          await _db!.query('emergency_cards', where: 'id = ?', whereArgs: [id]);
      return rows.isNotEmpty ? rows.first : null;
    } catch (e) {
      print('❌ getEmergencyCard failed: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  EMERGENCY NUMBERS
  // ════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getEmergencyNumber(String countryCode) async {
    if (_db == null) return null;
    try {
      final rows = await _db!.query('emergency_numbers',
          where: 'code = ?', whereArgs: [countryCode]);
      return rows.isNotEmpty ? rows.first : null;
    } catch (e) {
      print('❌ getEmergencyNumber failed: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  MEDICINE BRANDS
  // ════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> searchMedicine(String query) async {
    if (_db == null) return [];
    try {
      return await _db!.query(
        'medicine_brands',
        where: 'brand_name LIKE ? OR generic_name LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: 20,
      );
    } catch (e) {
      print('❌ searchMedicine failed: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  //  HOSPITALS
  // ════════════════════════════════════════════════════════════

  Future<List<Hospital>> getHospitals() async {
    if (_db == null) return [];
    try {
      final rows = await _db!.query('hospitals');
      return rows.map((r) => Hospital.fromMap(r)).toList();
    } catch (e) {
      print('❌ getHospitals failed: $e');
      return [];
    }
  }

  /// Returns hospitals sorted by distance from [lat],[lon].
  Future<List<Hospital>> getNearestHospitals(
    double lat,
    double lon, {
    int limit = 10,
  }) async {
    if (_db == null) return [];
    try {
      final rows = await _db!.query('hospitals');
      final hospitals = rows.map((r) => Hospital.fromMap(r)).toList();

      // Sort by haversine distance
      hospitals.sort((a, b) {
        final dA = _haversineKm(lat, lon, a.latitude, a.longitude);
        final dB = _haversineKm(lat, lon, b.latitude, b.longitude);
        return dA.compareTo(dB);
      });

      return hospitals.take(limit).toList();
    } catch (e) {
      print('❌ getNearestHospitals failed: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  //  RAG KNOWLEDGE (used by RagService)
  // ════════════════════════════════════════════════════════════

  /// Returns all knowledge rows. Used by RagService for keyword search.
  Future<List<Map<String, dynamic>>> getKnowledge() async {
    if (_db == null) return [];
    try {
      return await _db!.query('knowledge');
    } catch (e) {
      print('❌ getKnowledge failed: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
}
