import 'dart:io';

bool _containsAny(String text, List<String> keywords) {
  return keywords.any((keyword) => text.contains(keyword));
}

void main() {
  final input = "patient got an heart attack";
  final text = input.toLowerCase().trim();
  
  bool matched = _containsAny(text, [
      'heart attack',
      'heartattack',
      'chest pain',
      'chest pressure',
      'chest tightness',
      'cardiac',
      'left arm pain',
      'pain in left arm',
      'jaw pain',
      'shortness of breath',
      'breathlessness',
    ]);
    
  print("Matched heart attack? $matched");
}
