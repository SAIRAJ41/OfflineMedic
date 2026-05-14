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
  CancelToken? _cancelToken;

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

  void cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel("Download cancelled.");
    }
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
    
    if (e is DioException && e.type == DioExceptionType.cancel) {
      return "Download cancelled.";
    }
    
    if (_isNetworkError(e)) {
      if (e is DioException && (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout)) {
        return "Download timed out. Please try again with a stable Wi-Fi connection.";
      }
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

      _cancelToken = CancelToken();

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: ModelConfig.connectTimeoutSeconds);
      dio.options.sendTimeout = const Duration(seconds: ModelConfig.sendTimeoutSeconds);
      dio.options.receiveTimeout = const Duration(minutes: ModelConfig.receiveTimeoutMinutes);

      String url = ModelConfig.modelDownloadUrl;
      
      int existingLength = 0;
      if (partFile.existsSync()) {
        existingLength = partFile.lengthSync();
      }

      try {
        await _tryDownload(dio, url, partFile, existingLength, onProgress);
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) {
          // User cancellation. Keep the .part file.
          onError(_getUserFriendlyError(e));
          return false;
        } else if (_isNetworkError(e)) {
          // Network failure. Keep the .part file.
          onError(_getUserFriendlyError(e));
          return false;
        } else {
          onError(_getUserFriendlyError(e));
          return false;
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
      
      // Additional safety check for oversized/corrupted files
      if (size > ModelConfig.expectedMinModelSizeBytes + (500 * 1024 * 1024)) {
        partFile.deleteSync();
        throw Exception("Download failed: File is larger than expected.");
      }

      // Rename to final .gguf file
      if (finalFile.existsSync()) {
         finalFile.deleteSync();
      }
      partFile.renameSync(finalFile.path);

      onComplete();
      return true;
    } catch (e) {
      onError(_getUserFriendlyError(e));
      return false;
    }
  }

  Future<void> _tryDownload(
    Dio dio, 
    String url, 
    File destFile, 
    int existingLength, 
    Function(double, String, String) onProgress
  ) async {
    Options options = Options(
      responseType: ResponseType.stream,
    );

    if (existingLength > 0) {
      options.headers = {
        'Range': 'bytes=$existingLength-',
      };
      debugPrint("Resuming download from bytes=$existingLength-");
    } else {
      debugPrint("Starting fresh download");
    }

    Response<ResponseBody> response = await dio.get<ResponseBody>(
      url,
      options: options,
      cancelToken: _cancelToken,
    );

    int contentLength = -1;
    final contentLengthHeaders = response.headers.value('content-length');
    if (contentLengthHeaders != null) {
      contentLength = int.tryParse(contentLengthHeaders) ?? -1;
    }

    bool append = false;

    if (response.statusCode == 206) {
      debugPrint("Server supports resume (HTTP 206). Appending.");
      append = true;
    } else if (response.statusCode == 200) {
      if (existingLength > 0) {
        debugPrint("Server does not support resume (HTTP 200). Deleting .part and restarting fresh.");
        if (destFile.existsSync()) {
          destFile.deleteSync();
        }
        existingLength = 0;
      } else {
        debugPrint("HTTP 200. Normal download.");
      }
      append = false;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: Response(
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final fileMode = append ? FileMode.append : FileMode.write;
    final sink = destFile.openWrite(mode: fileMode);

    int receivedBytes = existingLength;
    int totalBytes = existingLength + contentLength;

    // Handle case where total length is unknown
    if (contentLength == -1) {
       totalBytes = -1;
    } else if (response.statusCode == 200 && existingLength == 0) {
       totalBytes = contentLength;
    }

    try {
      await for (final chunk in response.data!.stream) {
        if (_cancelToken?.isCancelled ?? false) {
          throw DioException(
            requestOptions: response.requestOptions,
            type: DioExceptionType.cancel,
            error: "Download cancelled.",
          );
        }
        
        sink.add(chunk);
        receivedBytes += chunk.length;

        _reportProgress(receivedBytes, totalBytes, onProgress);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  void _reportProgress(int received, int total, Function(double, String, String) onProgress) {
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
      String downloadedSizeStr = "";
      if (received > 1024 * 1024 * 1024) {
        downloadedSizeStr = (received / (1024 * 1024 * 1024)).toStringAsFixed(2) + " GB";
      } else {
        downloadedSizeStr = (received / (1024 * 1024)).toStringAsFixed(1) + " MB";
      }
      onProgress(0.0, downloadedSizeStr, "Unknown");
    }
  }
}
