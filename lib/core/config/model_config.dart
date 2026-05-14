class ModelConfig {
  static const String modelFileName = "offlinemedic_model.gguf";

  static const String modelDownloadUrl = String.fromEnvironment(
    "MODEL_DOWNLOAD_URL",
    defaultValue: "https://huggingface.co/Green123476/offlinemedic-gemma4-gguf/resolve/main/offlinemedic-q4_k_m.gguf",
  );

  static const int expectedMinModelSizeBytes = 2400000000;

  static const int connectTimeoutSeconds = 60;
  static const int sendTimeoutSeconds = 60;
  static const int receiveTimeoutMinutes = 10;
}
