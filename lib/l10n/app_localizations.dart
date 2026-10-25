import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Catch Bales'**
  String get appTitle;

  /// No description provided for @playGame.
  ///
  /// In en, this message translates to:
  /// **'PLAY GAME'**
  String get playGame;

  /// No description provided for @arcade.
  ///
  /// In en, this message translates to:
  /// **'ARCADE'**
  String get arcade;

  /// No description provided for @jenga.
  ///
  /// In en, this message translates to:
  /// **'JENGA'**
  String get jenga;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'STATS'**
  String get stats;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'RESTART'**
  String get restart;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'MENU'**
  String get menu;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get resume;

  /// No description provided for @gamePaused.
  ///
  /// In en, this message translates to:
  /// **'GAME PAUSED'**
  String get gamePaused;

  /// No description provided for @tutorialStep1Title.
  ///
  /// In en, this message translates to:
  /// **'3x3 WAGON MOVEMENT'**
  String get tutorialStep1Title;

  /// No description provided for @tutorialStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Use the bottom touch pad to move the farmer across the 9 wagon cells!'**
  String get tutorialStep1Desc;

  /// No description provided for @tutorialStep2Title.
  ///
  /// In en, this message translates to:
  /// **'ORGANIZE & SCORE'**
  String get tutorialStep2Title;

  /// No description provided for @tutorialStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Every 15 bales triggers a 7-second organize cutscene. Tap this button anytime to organize early!'**
  String get tutorialStep2Desc;

  /// No description provided for @tutorialStep3Title.
  ///
  /// In en, this message translates to:
  /// **'LIVES & HEALTH'**
  String get tutorialStep3Title;

  /// No description provided for @tutorialStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Every missed straw bale costs 15 HP. Don\'t miss bales, protect your 4 hearts!'**
  String get tutorialStep3Desc;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'STEP {current} / {total}'**
  String stepProgress(int current, int total);

  /// No description provided for @buttonBack.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get buttonBack;

  /// No description provided for @buttonNext.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get buttonNext;

  /// No description provided for @buttonStart.
  ///
  /// In en, this message translates to:
  /// **'START!'**
  String get buttonStart;

  /// No description provided for @buttonSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get buttonSkip;

  /// No description provided for @buttonClose.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get buttonClose;

  /// No description provided for @buttonDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get buttonDone;

  /// No description provided for @buttonBalance.
  ///
  /// In en, this message translates to:
  /// **'BALANCE'**
  String get buttonBalance;

  /// No description provided for @buttonEarlyHaul.
  ///
  /// In en, this message translates to:
  /// **'EARLY HAUL'**
  String get buttonEarlyHaul;

  /// No description provided for @buttonHaulFull.
  ///
  /// In en, this message translates to:
  /// **'HAUL (45/45)'**
  String get buttonHaulFull;

  /// No description provided for @buttonPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'PLAY AGAIN'**
  String get buttonPlayAgain;

  /// No description provided for @buttonNextHaul.
  ///
  /// In en, this message translates to:
  /// **'NEXT HAUL'**
  String get buttonNextHaul;

  /// No description provided for @buttonMainMenu.
  ///
  /// In en, this message translates to:
  /// **'MAIN MENU'**
  String get buttonMainMenu;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'CAUGHT OBJECTS'**
  String get statsTitle;

  /// No description provided for @totalCaught.
  ///
  /// In en, this message translates to:
  /// **'TOTAL CAUGHT'**
  String get totalCaught;

  /// No description provided for @wagonsHauled.
  ///
  /// In en, this message translates to:
  /// **'WAGONS HAULED'**
  String get wagonsHauled;

  /// No description provided for @headerObject.
  ///
  /// In en, this message translates to:
  /// **'OBJECT / ANIMAL'**
  String get headerObject;

  /// No description provided for @headerThisGame.
  ///
  /// In en, this message translates to:
  /// **'THIS GAME'**
  String get headerThisGame;

  /// No description provided for @headerLifetime.
  ///
  /// In en, this message translates to:
  /// **'LIFETIME'**
  String get headerLifetime;

  /// No description provided for @stacksOnWagon.
  ///
  /// In en, this message translates to:
  /// **'Stacks on Wagon'**
  String get stacksOnWagon;

  /// No description provided for @caughtBriefStun.
  ///
  /// In en, this message translates to:
  /// **'Caught: Brief Stun'**
  String get caughtBriefStun;

  /// No description provided for @objectBale.
  ///
  /// In en, this message translates to:
  /// **'Straw Bale'**
  String get objectBale;

  /// No description provided for @objectChicken.
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get objectChicken;

  /// No description provided for @objectRooster.
  ///
  /// In en, this message translates to:
  /// **'Rooster'**
  String get objectRooster;

  /// No description provided for @objectDuck.
  ///
  /// In en, this message translates to:
  /// **'Duck'**
  String get objectDuck;

  /// No description provided for @objectSheep.
  ///
  /// In en, this message translates to:
  /// **'Sheep'**
  String get objectSheep;

  /// No description provided for @objectCow.
  ///
  /// In en, this message translates to:
  /// **'Cow'**
  String get objectCow;

  /// No description provided for @objectCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get objectCat;

  /// No description provided for @objectDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get objectDog;

  /// No description provided for @objectBird.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get objectBird;

  /// No description provided for @incoming.
  ///
  /// In en, this message translates to:
  /// **'INCOMING:'**
  String get incoming;

  /// No description provided for @incomingAlert.
  ///
  /// In en, this message translates to:
  /// **'{objectName} INCOMING!'**
  String incomingAlert(String objectName);

  /// No description provided for @stunRisk.
  ///
  /// In en, this message translates to:
  /// **'STUN RISK'**
  String get stunRisk;

  /// No description provided for @organizeApproaching.
  ///
  /// In en, this message translates to:
  /// **'ORGANIZE SOON! ({count} Left)'**
  String organizeApproaching(int count);

  /// No description provided for @organizeProgress.
  ///
  /// In en, this message translates to:
  /// **'ORGANIZE: {current}/{total}'**
  String organizeProgress(int current, int total);

  /// No description provided for @wagonFull.
  ///
  /// In en, this message translates to:
  /// **'WAGON FULL! (45/45)'**
  String get wagonFull;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'GAME OVER'**
  String get gameOver;

  /// No description provided for @newHighScore.
  ///
  /// In en, this message translates to:
  /// **'NEW HIGH SCORE!'**
  String get newHighScore;

  /// No description provided for @finalScore.
  ///
  /// In en, this message translates to:
  /// **'Final Score'**
  String get finalScore;

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best Score'**
  String get bestScore;

  /// No description provided for @wagonLoad.
  ///
  /// In en, this message translates to:
  /// **'3x3x5 Wagon Load'**
  String get wagonLoad;

  /// No description provided for @missedBales.
  ///
  /// In en, this message translates to:
  /// **'Missed Bales'**
  String get missedBales;

  /// No description provided for @completedWagons.
  ///
  /// In en, this message translates to:
  /// **'Completed Wagons'**
  String get completedWagons;

  /// No description provided for @totalObjectsCaught.
  ///
  /// In en, this message translates to:
  /// **'Total Objects Caught'**
  String get totalObjectsCaught;

  /// No description provided for @wagonFullDesc.
  ///
  /// In en, this message translates to:
  /// **'All 3x3x5 wagon slots stacked!'**
  String get wagonFullDesc;

  /// No description provided for @outOfLivesDesc.
  ///
  /// In en, this message translates to:
  /// **'Out of lives! Mode: {mode}'**
  String outOfLivesDesc(String mode);

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
