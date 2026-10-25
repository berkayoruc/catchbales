// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Catch Bales 3D';

  @override
  String get playGame => 'OYNA';

  @override
  String get arcade => 'ARCADE';

  @override
  String get jenga => 'JENGA';

  @override
  String get stats => 'İSTATİSTİKLER';

  @override
  String get settings => 'AYARLAR';

  @override
  String get restart => 'YENİDEN BAŞLAT';

  @override
  String get menu => 'MENÜ';

  @override
  String get resume => 'DEVAM ET';

  @override
  String get gamePaused => 'OYUN DURAKLATILDI';

  @override
  String get tutorialStep1Title => '3x3 RÖMORK HAREKETİ';

  @override
  String get tutorialStep1Desc =>
      'Alt kısımdaki joystick pedine dokunarak çiftçiyi römorkun 9 hücresi arasında hareket ettir!';

  @override
  String get tutorialStep2Title => 'DÜZENLEME & SKOR';

  @override
  String get tutorialStep2Desc =>
      'Her 15 balyada bir 7 saniyelik düzenleme başlar. İstersen bu butona dokunarak istediğin an römorku düzenleyebilirsin!';

  @override
  String get tutorialStep3Title => 'CANLAR & SAĞLIK';

  @override
  String get tutorialStep3Desc =>
      'Kaçan her saman balyası 15 HP götürür. Balyaları kaçırma, 4 kalbini koru!';

  @override
  String stepProgress(int current, int total) {
    return 'ADIM $current / $total';
  }

  @override
  String get buttonBack => 'ÖNCEKİ';

  @override
  String get buttonNext => 'SONRAKİ';

  @override
  String get buttonStart => 'BAŞLA!';

  @override
  String get buttonSkip => 'GEÇ';

  @override
  String get buttonClose => 'KAPAT';

  @override
  String get buttonDone => 'TAMAM';

  @override
  String get buttonBalance => 'DENGELE';

  @override
  String get buttonEarlyHaul => 'ERKEN SEVK';

  @override
  String get buttonHaulFull => 'SEVK (45/45)';

  @override
  String get buttonPlayAgain => 'TEKRAR OYNA';

  @override
  String get buttonNextHaul => 'SONRAKİ SEVKİYAT';

  @override
  String get buttonMainMenu => 'ANA MENÜ';

  @override
  String get statsTitle => 'YAKALANAN OBJELER';

  @override
  String get totalCaught => 'TOPLAM YAKALANAN';

  @override
  String get wagonsHauled => 'SEVK EDİLEN RÖMORK';

  @override
  String get headerObject => 'OBJE / HAYVAN';

  @override
  String get headerThisGame => 'BU OYUN';

  @override
  String get headerLifetime => 'TOPLAM';

  @override
  String get stacksOnWagon => 'Römorka İstiflenir';

  @override
  String get caughtBriefStun => 'Tutulursa: Kısa Stun';

  @override
  String get objectBale => 'Saman Balyası';

  @override
  String get objectChicken => 'Tavuk';

  @override
  String get objectRooster => 'Horoz';

  @override
  String get objectDuck => 'Ördek';

  @override
  String get objectSheep => 'Koyun';

  @override
  String get objectCow => 'İnek';

  @override
  String get objectCat => 'Kedi';

  @override
  String get objectDog => 'Köpek';

  @override
  String get objectBird => 'Kuş';

  @override
  String get incoming => 'GELEN:';

  @override
  String incomingAlert(String objectName) {
    return '$objectName GELİYOR!';
  }

  @override
  String get stunRisk => 'STUN RİSKİ';

  @override
  String organizeApproaching(int count) {
    return 'DÜZENLEME YAKIN! (Son $count Balya)';
  }

  @override
  String organizeProgress(int current, int total) {
    return 'DÜZENLEME: $current/$total';
  }

  @override
  String get wagonFull => 'RÖMORK DOLDU! (45/45)';

  @override
  String get gameOver => 'OYUN BİTTİ';

  @override
  String get newHighScore => 'YENİ REKOR!';

  @override
  String get finalScore => 'Skor';

  @override
  String get bestScore => 'En İyi Skor';

  @override
  String get wagonLoad => '3x3x5 Römork Yükü';

  @override
  String get missedBales => 'Kaçan Balyalar';

  @override
  String get completedWagons => 'Tamamlanan Römorklar';

  @override
  String get totalObjectsCaught => 'Toplam Yakalanan Obje';

  @override
  String get wagonFullDesc => 'Tüm 3x3x5 yuvalar istiflendi!';

  @override
  String outOfLivesDesc(String mode) {
    return 'Canlar bitti! Mod: $mode';
  }

  @override
  String get sound => 'Ses';

  @override
  String get haptics => 'Titreşim';
}
