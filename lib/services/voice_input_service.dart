// lib/services/voice_input_service.dart
// Records voice → saves as WAV → transcribes with Whisper offline

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

class VoiceInputService {
  VoiceInputService._internal();
  static final VoiceInputService instance = VoiceInputService._internal();

  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

  // ── Call once at startup ─────────────────────────────────────
  /// Only requests mic permission. Whisper (~150MB) downloads on first real
  /// [stopAndTranscribe] — never block [runApp] or you get a long blank screen.
  Future<void> initialize() async {
    try {
      await Permission.microphone.request();
      print('✅ VoiceInputService ready (Whisper loads on first use)');
    } catch (e) {
      print('VoiceInputService init: $e');
    }
  }

  // ── Start recording ──────────────────────────────────────────
  Future<void> startRecording() async {
    // Check permission
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    if (_isRecording) return;

    final dir = await getApplicationDocumentsDirectory();
    _recordingPath = '${dir.path}/voice_input.wav';

    // Delete previous recording if exists
    final file = File(_recordingPath!);
    if (await file.exists()) await file.delete();

    // Start recording as WAV — Whisper needs 16kHz mono WAV
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000, // ← must be 16kHz for Whisper
        numChannels: 1, // ← mono
        bitRate: 256000,
      ),
      path: _recordingPath!,
    );

    _isRecording = true;
    print('🎤 Recording started...');
  }

  // ── Stop recording and transcribe ───────────────────────────
  // Returns the transcribed text string
  Future<String> stopAndTranscribe() async {
    if (!_isRecording) return '';

    // Stop recording
    await _recorder.stop();
    _isRecording = false;
    print('⏹ Recording stopped, transcribing...');

    final audioFile = File(_recordingPath!);
    if (!await audioFile.exists()) {
      print('❌ Audio file not found');
      return '';
    }

    try {
      // Transcribe with Whisper — fully offline
      const whisper = Whisper(
        model: WhisperModel.base,
        downloadHost:
            "https://huggingface.co/ggerganov/whisper.cpp/resolve/main",
      );

      final result = await whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: _recordingPath!,
          language: 'auto', // auto-detect Hindi, English, etc.
          isTranslate: false, // set true to force translate to English
        ),
      );

      final text = result.text.trim();
      print('✅ Transcribed: $text');
      return text;
    } catch (e) {
      print('❌ Transcription failed: $e');
      return '';
    }
  }

  bool get isRecording => _isRecording;

  void dispose() {
    _recorder.dispose();
  }
}
