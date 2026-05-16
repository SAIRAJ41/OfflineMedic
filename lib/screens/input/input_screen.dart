import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/triage_result.dart';
import '../../services/gemma_service.dart';
import '../../services/database_service.dart';
import '../../services/voice_input_service.dart';
import '../../services/model_download_service.dart';
import '../../services/demo_triage_service.dart';
import '../triage/triage_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController controller = TextEditingController();

  bool isLoading = false;
  bool isListening = false;
  bool isTranscribing = false;

  TriageResult? result;

  int selectedInput = 2;

  File? selectedImage;

  String selectedImageName = "No image selected";

  String voiceText = "Tap microphone to speak";

  // -- Model state --
  bool _modelReady = false;
  bool _modelLoading = false;
  bool _modelMissing = false;
  bool _modelFileInvalid = false;
  String? _modelError;

  // -- Elapsed loading timer --
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (mounted) setState(() {});
    });
    _initializeModel();
  }

  /// Auto-initialize the AI model when InputScreen opens.
  Future<void> _initializeModel() async {
    // Reset state
    if (mounted) {
      setState(() {
        _modelMissing = false;
        _modelFileInvalid = false;
        _modelError = null;
        _modelReady = false;
      });
    }

    // Check if model file exists
    final modelFile = await ModelDownloadService.instance.getModelFile();
    if (!modelFile.existsSync()) {
      debugPrint('InputScreen: Model file missing');
      if (mounted) setState(() => _modelMissing = true);
      return;
    }

    // Already loaded?
    if (GemmaService.instance.isLoaded) {
      debugPrint('InputScreen: Model already loaded');
      if (mounted) setState(() => _modelReady = true);
      return;
    }

    // Start loading with elapsed timer
    if (mounted) setState(() => _modelLoading = true);
    _startLoadingTimer();
    debugPrint('InputScreen: Starting model initialization...');
    final success = await GemmaService.instance.initialize();
    debugPrint('InputScreen: Model initialization result = $success');
    _stopLoadingTimer();

    if (mounted) {
      setState(() {
        _modelLoading = false;
        _modelReady = success;
        if (!success) {
          _modelError = GemmaService.instance.loadError;
          _modelFileInvalid = GemmaService.instance.fileInvalid;
        }
      });
    }
  }

  void _startLoadingTimer() {
    _elapsedSeconds = 0;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      } else {
        _elapsedTimer?.cancel();
      }
    });
  }

  void _stopLoadingTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  String _formatElapsed(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ------------------------------------------------------------
  // Voice recording / transcription
  // ------------------------------------------------------------

  Future<void> _handleMicTap() async {
    if (isTranscribing) return;

    if (!isListening) {
      // Start recording
      try {
        await VoiceInputService.instance.startRecording();
        setState(() {
          isListening = true;
          voiceText = "Listening...";
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start recording: $e')),
          );
        }
      }
    } else {
      // Stop recording and transcribe
      setState(() {
        isListening = false;
        isTranscribing = true;
        voiceText = "Transcribing...";
      });

      try {
        final transcribedText =
            await VoiceInputService.instance.stopAndTranscribe();
        if (mounted) {
          setState(() {
            isTranscribing = false;
            if (transcribedText.isNotEmpty) {
              controller.text = transcribedText;
              voiceText = "Transcribed: ${transcribedText.length > 50 ? '${transcribedText.substring(0, 50)}...' : transcribedText}";
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice input ready. Press Analyze Now.')),
              );
            } else {
              voiceText = "No speech detected. Try again.";
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice input failed. Please try again.')),
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isTranscribing = false;
            voiceText = "Transcription failed. Try again.";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice input failed: $e')),
          );
        }
      }
    }
  }

  // ------------------------------------------------------------
  // Analyze symptoms
  // ------------------------------------------------------------

  Future<void> assess() async {
    // -- Input validation --
    final inputText = controller.text.trim();

    if (inputText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedImage != null
                  ? 'Please describe the symptoms in text to analyze.'
                  : 'Please describe the symptoms in more detail.',
            ),
          ),
        );
      }
      return;
    }

    if (inputText.length < 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please describe the symptoms in more detail.')),
        );
      }
      return;
    }

    final demoResult = DemoTriageService.getDemoTriageResult(inputText);
    if (demoResult != null) {
      debugPrint('InputScreen: Demo result matched. Skipping GemmaService.');

      if (mounted) {
        setState(() {
          isLoading = true;
          result = demoResult;
        });
      }

      try {
        final inputType = selectedInput == 0
            ? 'image'
            : selectedInput == 1
                ? 'voice'
                : 'text';

        await DatabaseService.instance.saveCase(
          demoResult,
          inputText,
          inputType,
          imagePath: selectedImage?.path,
        );

        debugPrint('InputScreen: Demo case saved to database');
      } catch (e) {
        debugPrint('InputScreen: Demo DB save error: $e');
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TriageScreen(result: demoResult),
          ),
        );
      }

      return;
    }

    // -- Model readiness --
    if (_modelMissing) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI model is not installed. Please download the model first.')),
        );
      }
      return;
    }

    // If not ready, try loading once
    if (!_modelReady) {
      if (mounted) setState(() => isLoading = true);
      await _initializeModel();
      if (!_modelReady) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _modelError ?? 'AI model could not start on this device. Try restarting the app.',
              ),
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
      _startLoadingTimer();
    }

    debugPrint('=== INPUT SCREEN: Starting assessment ===');
    debugPrint('User input: $inputText');

    try {
      debugPrint('Calling GemmaService.instance.assess()...');
      final res = await GemmaService.instance.assess(inputText);
      _stopLoadingTimer();
      
      if (res.confidence == 'low' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI response is taking too long. Showing safe guidance.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      debugPrint('GemmaService returned: ${res.triageLevel} - ${res.condition}');

      if (mounted) {
        setState(() {
          result = res;
        });
      }

      // Auto-save case to SQLite — never let DB error block the result
      try {
        final inputType = selectedInput == 0
            ? 'image'
            : selectedInput == 1
                ? 'voice'
                : 'text';
        await DatabaseService.instance.saveCase(
          res,
          inputText,
          inputType,
          imagePath: selectedImage?.path,
        );
        debugPrint('Case saved to database');
      } catch (e) {
        debugPrint('DB save error (non-fatal): $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case not saved to history')),
          );
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TriageScreen(result: res),
          ),
        );
      }
    } catch (e) {
      _stopLoadingTimer();
      debugPrint('Assessment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: Unable to generate a structured response. Please try again.',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // Pick image - DISABLED for demo
  // ------------------------------------------------------------

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        selectedImageName = pickedFile.name;
        selectedInput = 0; // Focus on image
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _stopLoadingTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _drawer(context),
      body: SafeArea(
        child: Builder(
          builder: (context) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------

                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    const Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Medical Assistant",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // INPUT OPTIONS - Hide image for demo
                // ------------------------------------------------

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _inputCard(
                      0,
                      Icons.upload_file,
                      "Upload",
                      "Select image",
                    ),
                    _inputCard(
                      1,
                      Icons.mic,
                      "Speak",
                      "Tap to record",
                    ),
                    _inputCard(
                      2,
                      Icons.keyboard,
                      "Type",
                      "Enter symptoms",
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // TYPE INPUT
                // ------------------------------------------------

                if (selectedInput == 2) _inputBox(),

                // ------------------------------------------------
                // IMAGE INPUT
                // ------------------------------------------------

                if (selectedInput == 0) _imageBox(),

                // ------------------------------------------------
                // VOICE INPUT
                // ------------------------------------------------

                if (selectedInput == 1)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFC2C6D4),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: isTranscribing ? null : _handleMicTap,
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: isTranscribing
                                ? Colors.grey
                                : isListening
                                    ? Colors.red
                                    : const Color(0xFF003F87),
                            child: isTranscribing
                                ? const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isTranscribing
                              ? "Transcribing..."
                              : isListening
                                  ? "Listening..."
                                  : voiceText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // MODEL STATUS INDICATOR
                // ------------------------------------------------

                if (_modelLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFB0C4DE)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF003F87),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Loading AI model...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF003F87),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Elapsed: ${_formatElapsed(_elapsedSeconds)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _elapsedSeconds < 60
                                ? 'Large offline model is being loaded on your phone. Please wait.'
                                : _elapsedSeconds < 180
                                    ? 'Still loading... large models can take longer on some phones.'
                                    : 'Model loading is taking longer than expected. You can keep waiting or restart the app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: _elapsedSeconds >= 180
                                  ? Colors.orange.shade800
                                  : Colors.grey.shade600,
                            ),
                          ),
                          if (_elapsedSeconds >= 180) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // Keep waiting — do nothing
                                  },
                                  child: const Text('Keep Waiting'),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: () {
                                    _stopLoadingTimer();
                                    GemmaService.instance.dispose();
                                    _initializeModel();
                                  },
                                  child: const Text('Retry Loading'),
                                ),
                              ],
                            ),
                          ],
                          if (_elapsedSeconds < 60)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'This may take 1–3 minutes on first load.',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                if (_modelMissing && !_modelLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'AI model is not installed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                    ),
                  ),

                if (_modelFileInvalid && !_modelLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _modelError ?? 'AI model file looks incomplete. Please download it again from setup.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),

                if (_modelError != null && !_modelLoading && !_modelFileInvalid && !_modelMissing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _modelError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),

                // ------------------------------------------------
                // ANALYZE BUTTON
                // ------------------------------------------------

                GestureDetector(
                  onTap: _getButtonOnTap(),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: _getButtonColor(),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _getButtonChild(),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // RESULT
                // ------------------------------------------------

                if (result != null && !isLoading) ...[
                  _resultCard(),
                  const SizedBox(height: 24),
                  if (result!.callNow)
                    Container(
                      height: 72,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB6152E),
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "CALL EMERGENCY",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Analyze button helpers
  // ------------------------------------------------------------

  bool _isDemoInput() {
    return DemoTriageService.getDemoTriageResult(controller.text.trim()) != null;
  }

  VoidCallback? _getButtonOnTap() {
    if (isLoading) return null;

    final isDemo = _isDemoInput();

    // Demo predefined cases must work even if model is loading/missing/not ready.
    if (isDemo) return assess;

    if (_modelLoading) return null;

    if (_modelMissing || _modelFileInvalid) {
      return () => Navigator.pushNamed(context, '/setup');
    }

    if (_modelError != null && !_modelFileInvalid) return null;
    if (!_modelReady) return null;

    return assess;
  }

  Color _getButtonColor() {
    if (isLoading) return Colors.grey.shade400;

    if (_isDemoInput()) return const Color(0xFF003F87);

    if (_modelMissing || _modelFileInvalid) return Colors.grey.shade600;
    if (_modelLoading) return Colors.grey.shade400;
    if (_modelError != null) return Colors.grey.shade400;

    return const Color(0xFF003F87);
  }

  Widget _getButtonChild() {
    if (_isDemoInput() && !isLoading) {
      return const Text(
        "Analyze Now",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }
    if (_modelMissing) {
      return const Text(
        "Open Setup",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }
    if (_modelFileInvalid && !_modelLoading) {
      return const Text(
        "Open Setup",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }
    if (_modelLoading) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            "Loading AI Model...",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            "Analyzing... ${_formatElapsed(_elapsedSeconds)}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
    return const Text(
      "Analyze Now",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  // ------------------------------------------------------------
  // Input box
  // ------------------------------------------------------------

  Widget _inputBox() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC2C6D4),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: "Enter symptoms...",
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(18),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Image box
  // ------------------------------------------------------------

  Widget _imageBox() {
    return Column(
      children: [
        GestureDetector(
          onTap: pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: const Color(0xFFC2C6D4)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(selectedImage!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Tap to select image",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
        ),
        if (selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              selectedImageName,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Describe the symptoms...",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // Result card
  // ------------------------------------------------------------

  Widget _resultCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result!.triageLevel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(result!.condition),
          const SizedBox(height: 16),
          const Text(
            "Do Now:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...result!.doNow.map(
            (e) => Text("• $e"),
          ),
          const SizedBox(height: 16),
          const Text(
            "Do NOT:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...result!.doNot.map(
            (e) => Text("• $e"),
          ),
          const SizedBox(height: 16),
          const Text(
            "Red Flags:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...result!.redFlags.map(
            (e) => Text("⚠ $e"),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Drawer
  // ------------------------------------------------------------

  static Widget _drawer(
    BuildContext context,
  ) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              "OfflineMedic",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          ListTile(
            title: const Text("Input"),
            onTap: () => Navigator.pushReplacementNamed(
              context,
              '/input',
            ),
          ),
          ListTile(
            title: const Text("Dashboard"),
            onTap: () => Navigator.pushReplacementNamed(
              context,
              '/dashboard',
            ),
          ),
          ListTile(
            title: const Text("Map"),
            onTap: () => Navigator.pushReplacementNamed(
              context,
              '/map',
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Input mode card
  // ------------------------------------------------------------

  Widget _inputCard(
    int index,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isActive = selectedInput == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedInput = index;

          if (index != 1) {
            isListening = false;
          }
        });
      },
      child: Column(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color:
                  isActive ? const Color(0xFF003F87) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isActive ? Colors.white : Colors.blue,
            ),
          ),
          const SizedBox(height: 6),
          Text(title),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}