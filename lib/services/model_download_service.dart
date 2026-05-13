import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../core/config/model_config.dart';

class ModelDownloadService {
  static final ModelDownloadService instance = ModelDownloadService._internal();
  ModelDownloadService._internal();

  static const String partFilename = "${ModelConfig.modelFileName}.part";

  Future<File> getModelFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/${ModelConfig.modelFileName}");
  }

  Future<File> getPartFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$partFilename");
  }

  Future<bool> isModelDownloaded() async {
    final file = await getModelFile();
    return file.existsSync() && file.lengthSync() >= ModelConfig.expectedMinModelSizeBytes;
  }

  Future<String> getModelPath() async {
    final file = await getModelFile();
    return file.path;
  }

  bool _isNetworkError(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.badResponse ||
          e.type == DioExceptionType.unknown) {
        return true;
      }
    }

    if (e is SocketException ||
        e is HttpException ||
        e is TimeoutException ||
        e is FileSystemException ||
        e is FormatException ||
        errorStr.contains("socketexception") ||
        errorStr.contains("httpexception") ||
        errorStr.contains("timeoutexception") ||
        errorStr.contains("filesystemexception") ||
        errorStr.contains("formatexception") ||
        errorStr.contains("connection closed while receiving data")) {
      return true;
    }

    return false;
  }

  String _getUserFriendlyError(dynamic e) {
    debugPrint("Raw download error: $e");
    if (_isNetworkError(e)) {
      return "There is no internet connection. Please check your Wi-Fi.";
    }
    return "Model download failed. Please try again.";
  }

  Future<bool> downloadModel({
    required Function(double progress, String downloadedSize, String totalSize) onProgress,
    required Function() onComplete,
    required Function(String error) onError,
  }) async {
    try {
      if (await isModelDownloaded()) {
        onComplete();
        return true;
      }

      final partFile = await getPartFile();
      final finalFile = await getModelFile();

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(hours: 2); // It's a large file

      String primaryUrl = ModelConfig.modelDownloadUrl;
      String fallbackUrl = ModelConfig.huggingFaceFallbackUrl;

      try {
        await _tryDownloadWithGoogleDriveBypass(dio, primaryUrl, partFile, onProgress);
      } catch (e) {
        if (_isNetworkError(e)) {
          throw e; // Do not attempt fallback if it's a network issue
        }
        if (fallbackUrl.isNotEmpty) {
          debugPrint("Primary URL failed, trying fallback URL...");
          await _tryDownload(dio, fallbackUrl, partFile, onProgress);
        } else {
          rethrow;
        }
      }

      // Validate downloaded file
      if (!partFile.existsSync()) {
        throw Exception("Download failed: File not found.");
      }

      final size = partFile.lengthSync();
      if (size < ModelConfig.expectedMinModelSizeBytes) {
        partFile.deleteSync();
        throw Exception("Download failed: File is too small. Validation failed.");
      }

      // Rename to final .gguf file
      partFile.renameSync(finalFile.path);

      onComplete();
      return true;
    } catch (e) {
      onError(_getUserFriendlyError(e));
      return false;
    }
  }

  Future<void> _tryDownloadWithGoogleDriveBypass(
      Dio dio, String url, File destFile, Function(double, String, String) onProgress) async {
    
    await _tryDownload(dio, url, destFile, onProgress);

    // If download completes but it's too small, it might be an HTML warning page
    if (destFile.existsSync() && destFile.lengthSync() < ModelConfig.expectedMinModelSizeBytes) {
      try {
        final content = await destFile.readAsString();
        final match = RegExp(r'confirm=([a-zA-Z0-9_-]+)').firstMatch(content);
        if (match != null) {
          final token = match.group(1);
          debugPrint("Found Google Drive confirm token: $token. Retrying...");
          
          destFile.deleteSync();
          
          final retryUrl = url.contains('?') ? "$url&confirm=$token" : "$url?confirm=$token";
          await _tryDownload(dio, retryUrl, destFile, onProgress);
        } else {
          destFile.deleteSync();
          throw Exception("Invalid file downloaded. No confirm token found.");
        }
      } catch (e) {
        if (destFile.existsSync()) {
          destFile.deleteSync();
        }
        throw Exception("Invalid file downloaded. Expected complete GGUF model.");
      }
    }
  }

  Future<void> _tryDownload(Dio dio, String url, File destFile, Function(double, String, String) onProgress) async {
    await dio.download(
      url,
      destFile.path,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final double progress = received / total;
          
          String totalSizeStr = "";
          if (total > 1024 * 1024 * 1024) {
            totalSizeStr = (total / (1024 * 1024 * 1024)).toStringAsFixed(2) + " GB";
          } else {
            totalSizeStr = (total / (1024 * 1024)).toStringAsFixed(1) + " MB";
          }

          String downloadedSizeStr = "";
          if (received > 1024 * 1024 * 1024) {
            downloadedSizeStr = (received / (1024 * 1024 * 1024)).toStringAsFixed(2) + " GB";
          } else {
            downloadedSizeStr = (received / (1024 * 1024)).toStringAsFixed(1) + " MB";
          }

          onProgress(progress, downloadedSizeStr, totalSizeStr);
        } else {
          final String downloadedStr = (received / (1024 * 1024)).toStringAsFixed(1) + " MB";
          onProgress(0.0, downloadedStr, "Unknown");
        }
      },
    );
  }
}
