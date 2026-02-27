/// Hardcoded Filipino UI strings for the Sakasama MVP.
///
/// These will be replaced with proper ARB-based i18n in a later phase.
/// For now, all user-facing text is centralized here.
class AppStrings {
  AppStrings._();

  // ── App ─────────────────────────────────────────────────────────────────
  static const String appName = 'Sakasama';
  static const String appTagline = 'Ang iyong kasama sa pagsasaka';

  // ── Onboarding ──────────────────────────────────────────────────────────
  static const String getStarted = 'Magsimula';
  static const String selectLanguage = 'Pumili ng Wika';
  static const String filipino = 'Filipino';
  static const String cebuano = 'Cebuano';
  static const String english = 'English';
  static const String next = 'Susunod';
  static const String back = 'Bumalik';
  static const String setupFarm = 'I-setup ang Bukid';
  static const String farmerName = 'Pangalan ng Magsasaka';
  static const String farmName = 'Pangalan ng Bukid';
  static const String location = 'Lokasyon (Probinsiya/Munisipalidad)';
  static const String cropType = 'Uri ng Pananim';
  static const String complete = 'Kumpleto';
  static const String permissionsTitle = 'Mga Kailangan na Pahintulot';
  static const String cameraPermission = 'Camera';
  static const String cameraPermissionDesc =
      'Para sa pag-scan ng mga resibo at label';
  static const String micPermission = 'Mikropono';
  static const String micPermissionDesc = 'Para sa voice assistant na si Saka';
  static const String storagePermission = 'Storage';
  static const String storagePermissionDesc = 'Para sa pag-save ng mga ulat';
  static const String allowAll = 'Payagan Lahat';

  // ── Dashboard ───────────────────────────────────────────────────────────
  static const String goodMorning = 'Magandang umaga';
  static const String goodAfternoon = 'Magandang hapon';
  static const String goodEvening = 'Magandang gabi';
  static const String daysLogged = 'Araw na Naka-log';
  static const String of90Days = 'sa 90 Araw';
  static const String scanReceipt = 'I-Scan ang Resibo';
  static const String logActivity = 'Mag-log ng Aktibidad';
  static const String askSaka = 'Tanungin si Saka';
  static const String exportReport = 'I-export ang Ulat';

  // ── Bottom Navigation ───────────────────────────────────────────────────
  static const String navHome = 'Home';
  static const String navJournal = 'Journal';
  static const String navSaka = 'Saka';
  static const String navExport = 'Export';

  // ── Farm Journal ────────────────────────────────────────────────────────
  static const String farmJournal = 'Farm Journal';
  static const String addEntry = 'Add';
  static const String emptyJournalTitle = 'Wala pang entry';
  static const String emptyJournalMessage =
      'Magsimula ng pag-log ng iyong mga aktibidad sa bukid!';
  static const String startLogging = 'Magsimulang Mag-log';
  static const String date = 'Petsa';
  static const String activityType = 'Uri ng Aktibidad';
  static const String productUsed = 'Produktong Ginamit';
  static const String quantity = 'Dami';
  static const String unit = 'Yunit';
  static const String notes = 'Mga Tala (opsyonal)';
  static const String addPhoto = 'Magdagdag ng Larawan';
  static const String save = 'I-save';

  // ── Activity Types ──────────────────────────────────────────────────────
  static const String fertilization = 'Paglalagay ng Pataba';
  static const String irrigation = 'Pagdilig';
  static const String pestControl = 'Kontrol sa Peste';
  static const String harvest = 'Pag-ani';
  static const String planting = 'Pagtatanim';
  static const String pruning = 'Pagpuputol';
  static const String soilPrep = 'Paghahanda ng Lupa';
  static const String other = 'Iba pa';

  // ── OCR Scan ────────────────────────────────────────────────────────────
  static const String scanTitle = 'I-Scan ang Resibo';
  static const String scanInstruction = 'Itutok ang camera sa resibo o label';
  static const String processing = 'Kinukuha ang impormasyon...';
  static const String reviewTitle = 'Suriin ang mga Nakuha';
  static const String confirmAndSave = 'Kumpirmahin at I-save';
  static const String retake = 'Ulitin';
  static const String detected = 'Nakita';
  static const String uncertain = 'Hindi sigurado';
  static const String productName = 'Pangalan ng Produkto';
  static const String price = 'Presyo';
  static const String supplier = 'Supplier';

  // ── Voice Assistant ─────────────────────────────────────────────────────
  static const String voiceAssistantTitle = 'Tanungin si Saka';
  static const String tapToSpeak = 'Pindutin para magsalita';
  static const String listening = 'Nakikinig...';
  static const String thinking = 'Nag-iisip...';
  static const String speaking = 'Nagsasalita...';
  static const String sampleQuestion1 = 'Ano ang PhilGAP?';
  static const String sampleQuestion2 = 'Paano mag-apply?';
  static const String sampleQuestion3 = 'Anong mga kailangan?';
  static const String sampleQuestion4 = 'Gaano katagal ang proseso?';

  // ── Compliance Forms ────────────────────────────────────────────────────
  static const String complianceForms = 'Mga Form ng Compliance';
  static const String statusComplete = 'Kumpleto';
  static const String statusIncomplete = 'Hindi pa kumpleto';
  static const String formFarmJournal = 'Farm Journal';
  static const String formPestMonitoring = 'Pest Monitoring Log';
  static const String formHarvestRecord = 'Harvest Record';
  static const String formInputInventory = 'Input Inventory';
  static const String formWaterSource = 'Water Source Record';

  // ── Audit Export ────────────────────────────────────────────────────────
  static const String exportTitle = 'I-export ang Ulat';
  static const String totalEntries = 'Kabuuang Entry';
  static const String dateRange = 'Saklaw ng Petsa';
  static const String completionRate = 'Porsyento ng Pagkakumpleto';
  static const String formatPdf = 'PDF';
  static const String formatCsv = 'CSV';
  static const String generateAndShare = 'I-generate at I-share';

  // ── Settings ────────────────────────────────────────────────────────────
  static const String settings = 'Mga Setting';
  static const String language = 'Wika';
  static const String editFarmProfile = 'I-edit ang Farm Profile';
  static const String aboutAndHelp = 'Tungkol at Tulong';
  static const String dataBackup = 'Backup ng Data';
  static const String version = 'Bersyon';

  // ── Common ──────────────────────────────────────────────────────────────
  static const String cancel = 'Kanselahin';
  static const String delete = 'Burahin';
  static const String confirm = 'Kumpirmahin';
  static const String retry = 'Subukang Muli';
  static const String ok = 'OK';
  static const String tagline = 'Kasama mo sa pagsasaka';

  // ── Auth ────────────────────────────────────────────────────────────────
  static const String loginTitle = 'Mag-login';
  static const String registerTitle = 'Gumawa ng Account';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Kumpirmahin ang Password';
  static const String signIn = 'Mag-login';
  static const String register = 'Mag-register';
  static const String noAccount = 'Wala ka pang account?';
  static const String createAccount = 'Gumawa ng Account';
  static const String hasAccount = 'May account ka na?';
  static const String logout = 'Mag-logout';
}
