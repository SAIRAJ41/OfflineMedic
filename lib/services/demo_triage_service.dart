import '../models/triage_result.dart';

/// Predefined demo cases for OfflineMedic hackathon demo.
///
/// These return instantly without hitting the AI model, making the demo
/// smooth and reliable. The model integration remains intact for all
/// other inputs — these cases just short-circuit before generate() is called.
///
/// Trigger phrases (case-insensitive):
///   Case 1 — Heart Attack : "heart attack", "chest pain", "chest pressure"
///   Case 2 — Snake Bite   : "snake bite", "snake", "bitten by snake", "venom"
///   Case 3 — High Fever   : "high fever", "fever child", "baby fever", "fever baby"
///   Case 4 — Common Cold  : "cold", "cough", "runny nose", "sore throat"
class DemoTriageService {
  DemoTriageService._();

  /// Returns a predefined [TriageResult] if [userInput] matches a demo case.
  /// Returns null for all other inputs (model inference will run instead).
  static TriageResult? getDemoTriageResult(String userInput) {
    final input = userInput.toLowerCase().trim();

    if (_matchesHeartAttack(input)) return _heartAttackCase();
    if (_matchesSnakeBite(input)) return _snakeBiteCase();
    if (_matchesHighFever(input)) return _highFeverCase();
    if (_matchesCommonCold(input)) return _commonColdCase();

    return null; // No demo match → model inference runs
  }

  // ─── Matchers ────────────────────────────────────────────────────────────

  static bool _matchesHeartAttack(String input) {
    return input.contains('heart attack') ||
        input.contains('chest pain') ||
        input.contains('chest pressure') ||
        input.contains('left arm pain') ||
        input.contains('jaw pain') ||
        input.contains('cardiac');
  }

  static bool _matchesSnakeBite(String input) {
    return input.contains('snake bite') ||
        input.contains('snakebite') ||
        input.contains('snake') ||
        input.contains('bitten by snake') ||
        input.contains('venom');
  }

  static bool _matchesHighFever(String input) {
    return (input.contains('fever') &&
            (input.contains('child') ||
                input.contains('baby') ||
                input.contains('kid') ||
                input.contains('infant') ||
                input.contains('high'))) ||
        input == 'fever';
  }

  static bool _matchesCommonCold(String input) {
    return input.contains('cold') ||
        input.contains('cough') ||
        input.contains('runny nose') ||
        input.contains('sore throat') ||
        input.contains('sneezing');
  }

  // ─── Case 1: Heart Attack ─────────────────────────────────────────────────

  static TriageResult _heartAttackCase() {
    return TriageResult(
      triageLevel: 'URGENT',
      condition: 'Possible Heart Attack (Cardiac Emergency)',
      confidence: 'high',
      doNow: [
        'Call 108 emergency services immediately — do not wait.',
        'Have the person sit or lie down in a comfortable position and keep them calm.',
        'Loosen any tight clothing around the neck and chest.',
      ],
      doNot: [
        'Do not let the person walk or exert themselves in any way.',
        'Do not give food, water, or any medication unless prescribed.',
        'Do not leave the person alone at any point.',
      ],
      redFlags: [
        'Crushing or squeezing chest pain lasting more than a few minutes',
        'Pain spreading to left arm, jaw, neck, or back',
        'Sudden sweating, nausea, or shortness of breath',
      ],
      callNow: true,
      emergencyNumber: '108',
      dispatcherScript:
          'I have a medical emergency. The patient has chest pain and shortness of breath — possible heart attack. Please send an ambulance immediately.',
      outputLanguage: 'en',
      disclaimer:
          'This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.',
      rawResponse: 'demo_case:heart_attack',
    );
  }

  // ─── Case 2: Snake Bite ───────────────────────────────────────────────────

  static TriageResult _snakeBiteCase() {
    return TriageResult(
      triageLevel: 'URGENT',
      condition: 'Possible Venomous Snake Bite',
      confidence: 'high',
      doNow: [
        'Call 108 immediately and get to the nearest hospital as fast as possible.',
        'Keep the person completely still — movement spreads venom faster through the bloodstream.',
        'Keep the bitten limb below heart level and remove any rings, watches, or tight clothing near the bite.',
      ],
      doNot: [
        'Do not cut, squeeze, or try to suck out the venom — this causes more harm.',
        'Do not apply a tight tourniquet or ice pack.',
        'Do not give alcohol, aspirin, or any painkiller not prescribed by a doctor.',
      ],
      redFlags: [
        'Rapid swelling, bruising, or darkening at the bite site',
        'Difficulty breathing, swallowing, or speaking',
        'Dizziness, drooping eyelids, muscle weakness, or loss of consciousness',
      ],
      callNow: true,
      emergencyNumber: '108',
      dispatcherScript:
          'I have a medical emergency. The patient has been bitten by a snake. We need anti-venom and an ambulance immediately.',
      outputLanguage: 'en',
      disclaimer:
          'This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.',
      rawResponse: 'demo_case:snake_bite',
    );
  }

  // ─── Case 3: High Fever (Child) ───────────────────────────────────────────

  static TriageResult _highFeverCase() {
    return TriageResult(
      triageLevel: 'YELLOW',
      condition: 'High Fever — Possible Infection',
      confidence: 'high',
      doNow: [
        'Keep the child hydrated — give small sips of water, ORS, or diluted juice frequently.',
        'Use a damp cloth on the forehead and body to help bring the temperature down gently.',
        'Measure temperature every 30 minutes and note any changes.',
      ],
      doNot: [
        'Do not give aspirin to a child — it can cause a serious condition called Reye\'s syndrome.',
        'Do not use ice packs or very cold water baths to cool the child rapidly.',
        'Do not overdress or bundle the child — let body heat escape.',
      ],
      redFlags: [
        'Fever above 104°F (40°C) or any fever in an infant under 3 months',
        'Seizures, stiff neck, sensitivity to light, or a rash that doesn\'t fade under pressure',
        'Child becomes unresponsive, limp, or has difficulty breathing',
      ],
      callNow: false,
      emergencyNumber: '108',
      dispatcherScript:
          'I have a medical emergency. The child has a very high fever and is unresponsive. Please send help immediately.',
      outputLanguage: 'en',
      disclaimer:
          'This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.',
      rawResponse: 'demo_case:high_fever',
    );
  }

  // ─── Case 4: Common Cold ──────────────────────────────────────────────────

  static TriageResult _commonColdCase() {
    return TriageResult(
      triageLevel: 'GREEN',
      condition: 'Common Cold / Mild Viral Infection',
      confidence: 'high',
      doNow: [
        'Rest as much as possible and drink plenty of warm fluids like water, soup, or herbal tea.',
        'Gargle with warm salt water to ease sore throat.',
        'Monitor temperature and symptoms — most colds resolve in 5–7 days.',
      ],
      doNot: [
        'Do not take antibiotics — colds are caused by viruses and antibiotics have no effect.',
        'Do not ignore worsening symptoms like high fever, chest pain, or difficulty breathing.',
        'Do not share utensils, towels, or come in close contact with vulnerable people.',
      ],
      redFlags: [
        'Fever above 103°F (39.4°C) lasting more than 3 days',
        'Chest pain, shortness of breath, or wheezing',
        'Severe headache, ear pain, or symptoms that worsen after initially improving',
      ],
      callNow: false,
      emergencyNumber: '108',
      dispatcherScript: '',
      outputLanguage: 'en',
      disclaimer:
          'This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.',
      rawResponse: 'demo_case:common_cold',
    );
  }
}