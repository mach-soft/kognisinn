import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Nutné pro odchytávání chyb přes PlatformDispatcher
import 'package:flutter/services.dart'; // ZMĚNA: Přidáno pro možnost nastavení orientace displeje
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Integrace Firebase a Wiredash ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:wiredash/wiredash.dart';
import 'firebase_options.dart';

import 'screens/main_menu_screen.dart'; 
import 'screens/language_selection_screen.dart';
import 'bloc/settings/settings_bloc.dart';

// --- PŘEPÍNAČ VERZE ---
// Zajišťuje naprostou otevřenost. Výchozí stav (false) znamená, že se zkompiluje 
// 100% čistá aplikace, která s internetem nekomunikuje.
const bool useTelemetry = bool.fromEnvironment('USE_TELEMETRY', defaultValue: false);

void main() async {
  // 1. Inicializace základních vazeb Flutteru
  WidgetsFlutterBinding.ensureInitialized();

  // ZMĚNA: Absolutní zákaz překlápění displeje na všech obrazovkách (uzamčení na výšku)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2. Načtení lokálních uživatelských preferencí
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstRun = prefs.getBool('is_first_run') ?? true;
  final bool isCalibrated = prefs.getBool('global_is_calibrated') ?? false;
  
  // NAČTENÍ MOTIVU PŘED STARTEM UI: Zabrání probliknutí světlého režimu
  final bool initialDarkMode = prefs.getBool('is_dark_mode') ?? true;

  // 3. Telemetrie (Spustí se a do aplikace se zapojí POUZE pokud je zapnutý přepínač)
  if (useTelemetry) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // EXPLICITNÍ POVOLENÍ: Říkáme Firebase, ať pády při testování skutečně odesílá
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // 4. Inicializace lokalizačního modulu
  await EasyLocalization.ensureInitialized();

  // 5. Spuštění aplikace
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('cs'), Locale('en'), Locale('de')],
      // ZMĚNA: Cesta nyní ukazuje čistě na složku pro JSON soubory
      path: 'assets/translations', 
      fallbackLocale: const Locale('cs'), 
      child: BlocProvider(
        // PŘEDÁNÍ POČÁTEČNÍHO STAVU: SettingsBloc hned ví, jaký motiv použít
        create: (context) => SettingsBloc(isDarkModeInitial: initialDarkMode),
        child: KognixApp(isFirstRun: isFirstRun, isCalibrated: isCalibrated),
      ),
    ),
  );
}

class KognixApp extends StatelessWidget {
  final bool isFirstRun;
  final bool isCalibrated;

  const KognixApp({super.key, required this.isFirstRun, required this.isCalibrated});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        
        // Samotné jádro aplikace (čisté)
        final app = MaterialApp(
          title: 'Kognix',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: ThemeData(
            brightness: state.isDarkMode ? Brightness.dark : Brightness.light,
            useMaterial3: true,
          ),
          home: isFirstRun ? const LanguageSelectionScreen() : MainMenuScreen(isCalibrated: isCalibrated)
        );

        // Pokud je telemetrie VYPNOUTÁ (výchozí stav), vrátíme čistou aplikaci
        if (!useTelemetry) {
          return app;
        }

        // Pokud je telemetrie ZAPNUTÁ, obalíme aplikaci vrstvou pro sběr zpětné vazby
        return Wiredash(
          projectId: const String.fromEnvironment('WIREDASH_ID'),
          secret: const String.fromEnvironment('WIREDASH_SECRET'),
          child: app, 
        );
      },
    );
  }
}
