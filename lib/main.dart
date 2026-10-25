import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'controllers/rive_game_controller.dart';
import 'controllers/game_controller.dart';
import 'l10n/app_localizations.dart';
import 'views/splash_screen.dart';
import 'utils/farm_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to Mobile Portrait Mode & Full-Screen Immersive Mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Transparent system overlays when swiped in
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final riveController = RiveGameController();
  final gameController = GameController(riveBridge: riveController);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: riveController),
        ChangeNotifierProvider.value(value: gameController),
      ],
      child: const FarmBaleGameApp(),
    ),
  );
}

class FarmBaleGameApp extends StatelessWidget {
  final Widget? home;

  const FarmBaleGameApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catch Bales 3D',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: FarmTheme.fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: FarmTheme.goldenStraw,
          brightness: Brightness.dark,
          primary: FarmTheme.goldenStraw,
          secondary: FarmTheme.sunWarmYellow,
        ),
      ),
      home: home ?? const SplashScreen(),
    );
  }
}
