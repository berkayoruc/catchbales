// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Catch Bales';

  @override
  String get playGame => 'PLAY GAME';

  @override
  String get arcade => 'ARCADE';

  @override
  String get jenga => 'JENGA';

  @override
  String get stats => 'STATS';

  @override
  String get settings => 'SETTINGS';

  @override
  String get restart => 'RESTART';

  @override
  String get menu => 'MENU';

  @override
  String get resume => 'RESUME';

  @override
  String get gamePaused => 'GAME PAUSED';

  @override
  String get tutorialStep1Title => '3x3 WAGON MOVEMENT';

  @override
  String get tutorialStep1Desc =>
      'Use the bottom touch pad to move the farmer across the 9 wagon cells!';

  @override
  String get tutorialStep2Title => 'ORGANIZE & SCORE';

  @override
  String get tutorialStep2Desc =>
      'Every 15 bales triggers a 7-second organize cutscene. Tap this button anytime to organize early!';

  @override
  String get tutorialStep3Title => 'LIVES & HEALTH';

  @override
  String get tutorialStep3Desc =>
      'Every missed straw bale costs 15 HP. Don\'t miss bales, protect your 4 hearts!';

  @override
  String stepProgress(int current, int total) {
    return 'STEP $current / $total';
  }

  @override
  String get buttonBack => 'BACK';

  @override
  String get buttonNext => 'NEXT';

  @override
  String get buttonStart => 'START!';

  @override
  String get buttonSkip => 'SKIP';

  @override
  String get buttonClose => 'CLOSE';

  @override
  String get buttonDone => 'DONE';

  @override
  String get buttonBalance => 'BALANCE';

  @override
  String get buttonEarlyHaul => 'EARLY HAUL';

  @override
  String get buttonHaulFull => 'HAUL (45/45)';

  @override
  String get buttonPlayAgain => 'PLAY AGAIN';

  @override
  String get buttonNextHaul => 'NEXT HAUL';

  @override
  String get buttonMainMenu => 'MAIN MENU';

  @override
  String get statsTitle => 'CAUGHT OBJECTS';

  @override
  String get totalCaught => 'TOTAL CAUGHT';

  @override
  String get wagonsHauled => 'WAGONS HAULED';

  @override
  String get headerObject => 'OBJECT / ANIMAL';

  @override
  String get headerThisGame => 'THIS GAME';

  @override
  String get headerLifetime => 'LIFETIME';

  @override
  String get stacksOnWagon => 'Stacks on Wagon';

  @override
  String get caughtBriefStun => 'Caught: Brief Stun';

  @override
  String get objectBale => 'Straw Bale';

  @override
  String get objectChicken => 'Chicken';

  @override
  String get objectRooster => 'Rooster';

  @override
  String get objectDuck => 'Duck';

  @override
  String get objectSheep => 'Sheep';

  @override
  String get objectCow => 'Cow';

  @override
  String get objectCat => 'Cat';

  @override
  String get objectDog => 'Dog';

  @override
  String get objectBird => 'Bird';

  @override
  String get incoming => 'INCOMING:';

  @override
  String incomingAlert(String objectName) {
    return '$objectName INCOMING!';
  }

  @override
  String get stunRisk => 'STUN RISK';

  @override
  String organizeApproaching(int count) {
    return 'ORGANIZE SOON! ($count Left)';
  }

  @override
  String organizeProgress(int current, int total) {
    return 'ORGANIZE: $current/$total';
  }

  @override
  String get wagonFull => 'WAGON FULL! (45/45)';

  @override
  String get gameOver => 'GAME OVER';

  @override
  String get newHighScore => 'NEW HIGH SCORE!';

  @override
  String get finalScore => 'Final Score';

  @override
  String get bestScore => 'Best Score';

  @override
  String get wagonLoad => '3x3x5 Wagon Load';

  @override
  String get missedBales => 'Missed Bales';

  @override
  String get completedWagons => 'Completed Wagons';

  @override
  String get totalObjectsCaught => 'Total Objects Caught';

  @override
  String get wagonFullDesc => 'All 3x3x5 wagon slots stacked!';

  @override
  String outOfLivesDesc(String mode) {
    return 'Out of lives! Mode: $mode';
  }

  @override
  String get sound => 'Sound';

  @override
  String get haptics => 'Haptics';
}
