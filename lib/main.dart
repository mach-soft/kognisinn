import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_menu_screen.dart'; 
import 'screens/language_selection_screen.dart';
import 'bloc/settings/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstRun = prefs.getBool('is_first_run') ?? true;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('cs'), Locale('en'), Locale('de')],
      path: 'assets/translations/langs.csv', 
      assetLoader: CsvAssetLoader(), 
      fallbackLocale: const Locale('cs'), 
      child: BlocProvider(
        create: (context) => SettingsBloc(),
        child: KognixApp(isFirstRun: isFirstRun),
      ),
    ),
  );
}

class KognixApp extends StatelessWidget {
  final bool isFirstRun;
  const KognixApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return MaterialApp(
          title: 'Kognix',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: ThemeData(
            brightness: state.isDarkMode ? Brightness.dark : Brightness.light,
            useMaterial3: true,
          ),
          home: isFirstRun ? const LanguageSelectionScreen() : const MainMenuScreen()
        );
      },
    );
  }
}
