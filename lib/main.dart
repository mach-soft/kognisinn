import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/services.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Integrace Firebase a Wiredash ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:wiredash/wiredash.dart';
import 'firebase_options.dart';

// --- Centrální import sdíleného jádra (monorepo) ---
import 'package:kognisinn_core/kognisinn_core.dart';

const bool useTelemetry = bool.fromEnvironment('USE_TELEMETRY', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

  final bool isFirstRun = prefs.getBool('is_first_run') ?? true;
  final bool isCalibrated = prefs.getBool('global_is_calibrated') ?? false;
  final bool initialDarkMode = prefs.getBool('is_dark_mode') ?? true;

  // OCHRANA TELEMETRIE
  if (useTelemetry) {
    debugPrint("--- STARTUJI TELEMETRII ---");
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("--- FIREBASE INICIALIZOVÁN ---");

      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      debugPrint("--- CRASHLYTICS NASTAVEN ---");
    } catch (e) {
      debugPrint("--- KRITICKÁ CHYBA FIREBASE: $e ---");
    }
  }

  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('cs'), Locale('en'), Locale('de')],
      path: 'packages/kognisinn_core/assets/translations', 
      fallbackLocale: const Locale('cs'), 
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>(
            create: (context) => SettingsBloc(isDarkModeInitial: initialDarkMode),
          ),
          // ZDE JE KLÍČOVÁ ZMĚNA: Ve FREE verzi se zásadně nepředává žádný statsRepository!
          BlocProvider<DigitSpanBloc>(create: (context) => DigitSpanBloc()),
          BlocProvider<ECorsiBloc>(create: (context) => ECorsiBloc()),
          BlocProvider<MemoryPalaceBloc>(create: (context) => MemoryPalaceBloc()),
          BlocProvider<StroopBloc>(create: (context) => StroopBloc()),
          BlocProvider<MultiNBackBloc>(create: (context) => MultiNBackBloc()),
        ],
        child: KognisinnApp(isFirstRun: isFirstRun, isCalibrated: isCalibrated),
      ),
    ),
  );
}

class KognisinnApp extends StatelessWidget {
  final bool isFirstRun;
  final bool isCalibrated;

  const KognisinnApp({
    super.key, 
    required this.isFirstRun, 
    required this.isCalibrated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        
        final app = MaterialApp(
          title: 'Kognisinn',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: ThemeData(
            brightness: state.isDarkMode ? Brightness.dark : Brightness.light,
            useMaterial3: true,
          ),
          
          home: Builder(
            builder: (appContext) {
              if (isFirstRun) {
                return LanguageSelectionScreen(
                  onLanguageSelected: () {
                    Navigator.of(appContext).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => ThemeSelectionScreen(
                          onThemeSelected: (safeContext) {
                            Navigator.of(safeContext).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => OnboardingScreen(
                                  onFinish: (bool isGamified) {
                                    if (isGamified && !isCalibrated) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          // Zkontrolujte přesný název třídy kalibrace
                                          builder: (context) => const CalibrationScreen(), 
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => MainMenuScreen(isCalibrated: isCalibrated),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              } else {
                return MainMenuScreen(isCalibrated: isCalibrated);
              }
            },
          ),
        );

        if (!useTelemetry) {
          return app;
        }

        final wiredashId = const String.fromEnvironment('WIREDASH_ID');
        final wiredashSecret = const String.fromEnvironment('WIREDASH_SECRET');

        if (wiredashId.isEmpty || wiredashSecret.isEmpty) {
          return app; 
        }

        return Wiredash(
          projectId: wiredashId,
          secret: wiredashSecret,
          child: app, 
        );
      },
    );
  }
}
