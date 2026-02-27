/// Centralized asset path constants for easy reference across the app.
class AssetPaths {
  AssetPaths._();

  // ── Images ──────────────────────────────────────────────────────────────
  static const String imagesDir = 'assets/images';
  static const String logo = '$imagesDir/sakasama_logo.png';
  static const String logoWhite = '$imagesDir/sakasama_logo_white.png';
  static const String onboardingFarm = '$imagesDir/onboarding_farm.png';
  static const String onboardingScan = '$imagesDir/onboarding_scan.png';
  static const String onboardingVoice = '$imagesDir/onboarding_voice.png';
  static const String philgapBadge = '$imagesDir/philgap_badge.png';

  // ── Data ────────────────────────────────────────────────────────────────
  static const String dataDir = 'assets/data';
  static const String philgapFaq = '$dataDir/philgap_faq.json';
  static const String philgapManualChunks =
      '$dataDir/philgap_manual_chunks.json';
  static const String activityTypes = '$dataDir/activity_types.json';
  static const String restrictedInputs = '$dataDir/restricted_inputs.json';
}
