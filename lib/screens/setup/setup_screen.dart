import 'package:flutter/material.dart';
import '../../services/model_download_service.dart';
import '../input/input_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String downloadedStr = "";
  String totalStr = "";
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _checkExistingModel();
  }

  void _checkExistingModel() async {
    final exists = await ModelDownloadService.instance.isModelDownloaded();
    if (exists && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InputScreen()),
      );
    }
  }

  void _startDownload() async {
    setState(() {
      isDownloading = true;
      errorMessage = "";
      downloadProgress = 0.0;
      downloadedStr = "";
      totalStr = "";
    });

    final success = await ModelDownloadService.instance.downloadModel(
      onProgress: (progress, downloaded, total) {
        if (mounted) {
          setState(() {
            downloadProgress = progress;
            downloadedStr = downloaded;
            totalStr = total;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          // Upon complete, model is validated and saved. Wait for app restart or push input screen.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const InputScreen()),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            isDownloading = false;
            errorMessage = error;
          });
        }
      },
    );

    if (success) {
      // Handled by onComplete callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Required Setup'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.download_rounded,
                size: 80,
                color: Color(0xFF003F87),
              ),
              const SizedBox(height: 24),
              const Text(
                "Download AI Model",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "OfflineMedic needs to download the medical AI model to work completely offline.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("⚠️ Important Information", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("• Model size is 2.49 GB"),
                    Text("• A stable Wi-Fi connection is highly recommended"),
                    Text("• Please ensure you have at least 4 GB of free storage"),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (errorMessage.isNotEmpty) ...[
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],
              if (isDownloading) ...[
                LinearProgressIndicator(
                  value: downloadProgress,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade300,
                  color: const Color(0xFF003F87),
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 16),
                Text(
                  "${(downloadProgress * 100).toStringAsFixed(1)}% Downloaded",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (downloadedStr.isNotEmpty && totalStr.isNotEmpty)
                  Text(
                    "$downloadedStr / $totalStr",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                const SizedBox(height: 20),
                const Text(
                  "Downloading... Please keep the app open.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _startDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003F87),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    errorMessage.isNotEmpty ? "Retry Download" : "Start Download",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
