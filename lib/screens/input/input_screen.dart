// lib/screens/input/input_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/triage_result.dart';
import '../../services/gemma_service.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController controller = TextEditingController();

  bool isLoading = false;
  bool isListening = false;

  TriageResult? result;

  int selectedInput = 2;

  File? selectedImage;

  String selectedImageName = "No image selected";

  String voiceText = "Tap microphone to speak";

  // ------------------------------------------------------------
  // Analyze symptoms
  // ------------------------------------------------------------

  Future<void> assess() async {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final res = await GemmaService().assess(
        controller.text,
      );

      setState(() {
        result = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  // ------------------------------------------------------------
  // Pick image
  // ------------------------------------------------------------

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null) return;

    setState(() {
      selectedImage = File(picked.path);
      selectedImageName = picked.name;
    });
  }

  @override
  void dispose() {
    controller.dispose();

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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------

                Row(
                  children: [

                    IconButton(
                      icon: const Icon(Icons.menu),

                      onPressed: () {
                        Scaffold.of(context)
                            .openDrawer();
                      },
                    ),

                    const Expanded(
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.medical_services,
                            color: Colors.blue,
                          ),

                          SizedBox(width: 8),

                          Text(
                            "Medical Assistant",

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,

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
                // INPUT OPTIONS
                // ------------------------------------------------

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [

                    _inputCard(
                      0,
                      Icons.upload_file,
                      "Upload",
                      "Upload image",
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

                if (selectedInput == 2)
                  _inputBox(),

                // ------------------------------------------------
                // VOICE INPUT
                // ------------------------------------------------

                if (selectedInput == 1)
                  Container(
                    width: double.infinity,

                    padding:
                        const EdgeInsets.all(24),

                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            const Color(0xFFC2C6D4),
                      ),

                      borderRadius:
                          BorderRadius.circular(14),
                    ),

                    child: Column(
                      children: [

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isListening =
                                  !isListening;
                            });
                          },

                          child: CircleAvatar(
                            radius: 36,

                            backgroundColor:
                                isListening
                                    ? Colors.red
                                    : const Color(
                                        0xFF003F87,
                                      ),

                            child: Icon(
                              Icons.mic,

                              color: Colors.white,

                              size: 30,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          isListening
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

                // ------------------------------------------------
                // IMAGE INPUT
                // ------------------------------------------------

                if (selectedInput == 0)
                  GestureDetector(
                    onTap: pickImage,

                    child: Container(
                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(24),

                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              const Color(0xFFC2C6D4),
                        ),

                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      child: Column(
                        children: [

                          if (selectedImage != null)
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),

                              child: Image.file(
                                selectedImage!,

                                height: 140,

                                width:
                                    double.infinity,

                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            const Icon(
                              Icons
                                  .add_photo_alternate,

                              size: 48,

                              color:
                                  Color(0xFF003F87),
                            ),

                          const SizedBox(height: 12),

                          const Text(
                            "Tap to upload image",

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            selectedImageName,

                            style: const TextStyle(
                              color: Colors.grey,

                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // ANALYZE BUTTON
                // ------------------------------------------------

                GestureDetector(
                  onTap:
                      isLoading ? null : assess,

                  child: Container(
                    height: 72,

                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF003F87),

                      borderRadius:
                          BorderRadius.circular(14),
                    ),

                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Analyze Now",

                              style: TextStyle(
                                color: Colors.white,

                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // RESULT
                // ------------------------------------------------

                if (result != null &&
                    !isLoading) ...[
                  _resultCard(),

                  const SizedBox(height: 24),

                  if (result!.callNow)
                    Container(
                      height: 72,

                      width: double.infinity,

                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFB6152E),

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),

                      child: const Center(
                        child: Text(
                          "CALL EMERGENCY",

                          style: TextStyle(
                            color: Colors.white,

                            fontWeight:
                                FontWeight.bold,
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
  // Input box
  // ------------------------------------------------------------

  Widget _inputBox() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC2C6D4),
        ),

        borderRadius:
            BorderRadius.circular(14),
      ),

      child: TextField(
        controller: controller,

        maxLines: 6,

        decoration: const InputDecoration(
          hintText: "Enter symptoms...",

          border: InputBorder.none,

          contentPadding:
              EdgeInsets.all(18),
        ),
      ),
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

        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

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

            onTap: () =>
                Navigator.pushReplacementNamed(
              context,
              '/input',
            ),
          ),

          ListTile(
            title:
                const Text("Dashboard"),

            onTap: () =>
                Navigator.pushReplacementNamed(
              context,
              '/dashboard',
            ),
          ),

          ListTile(
            title: const Text("Map"),

            onTap: () =>
                Navigator.pushReplacementNamed(
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
    final isActive =
        selectedInput == index;

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
              color: isActive
                  ? const Color(0xFF003F87)
                  : const Color(0xFFF1F5F9),

              borderRadius:
                  BorderRadius.circular(12),

              border: Border.all(
                color:
                    const Color(0xFFE5E7EB),
              ),
            ),

            child: Icon(
              icon,

              size: 28,

              color: isActive
                  ? Colors.white
                  : Colors.blue,
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