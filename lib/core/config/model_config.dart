class ModelConfig {
  static const String modelFileName = "offlinemedic_model.gguf";

  static const String modelDownloadUrl = String.fromEnvironment(
    "MODEL_DOWNLOAD_URL",
    defaultValue: "https://drive.google.com/uc?export=download&id=1s0I-GxSD9U-8aig9O7O08deExQCP9-Gr",
  );

  static const String huggingFaceFallbackUrl = String.fromEnvironment(
    "HF_MODEL_URL",
    defaultValue: "",
  );

  static const int expectedMinModelSizeBytes = 2400000000;
}
