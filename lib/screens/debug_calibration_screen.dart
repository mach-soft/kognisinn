import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_menu_screen.dart'; // Uprav cestu k hlavnímu menu podle své struktury

class DebugCalibrationScreen extends StatefulWidget {
  const DebugCalibrationScreen({super.key});

  @override
  State<DebugCalibrationScreen> createState() => _DebugCalibrationScreenState();
}

class _DebugCalibrationScreenState extends State<DebugCalibrationScreen> {
  // Realistické výchozí hodnoty pro jednotlivé hry
  double _stroopTimeMs = 1200; // Čas reakce ve Stroopu (např. 1200 ms)
  double _digitSpanScore = 7;  // Kapacita (např. 7 čísel)
  double _eCorsiScore = 6;     // Kapacita (např. 6 bloků)
  double _palaceScore = 10;    // Počet asociací
  double _dnbSuccessRate = 85; // Úspěšnost v procentech (např. 85 %)

  Future<void> _saveAndBypass() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Zápis exaktních klíčů z CalibrationBloc se správnými datovými typy
    await prefs.setDouble('calib_stroop', _stroopTimeMs);
    await prefs.setInt('calib_digit_span', _digitSpanScore.toInt());
    await prefs.setInt('calib_ecorsi', _eCorsiScore.toInt());
    await prefs.setInt('calib_palace', _palaceScore.toInt());
    await prefs.setDouble('calib_dnb', _dnbSuccessRate);

    // 2. Odemčení aplikace (obejití prvního spuštění a kalibrace)
    await prefs.setBool('is_first_run', false);
    await prefs.setBool('global_is_calibrated', true);

    // 3. Násilné přesměrování do hlavního menu
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen(isCalibrated: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: const Text('DEBUG: Simulace kalibrace', style: TextStyle(color: Colors.redAccent)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nastav si libovolné startovací hrubé skóre a přeskoč úvodní testy.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            
            // Stroop se měří v milisekundách (obvykle 500 - 3000 ms)
            _buildSlider('Stroop (Průměrný čas v ms)', _stroopTimeMs, 500, 3000, (v) => setState(() => _stroopTimeMs = v), accentColor),
            
            // Digit Span měří kapacitu (obvykle 4 - 15)
            _buildSlider('Digit Span (Kapacita)', _digitSpanScore, 0, 15, (v) => setState(() => _digitSpanScore = v), accentColor),
            
            // eCorsi měří kapacitu (obvykle 4 - 15)
            _buildSlider('eCorsi (Kapacita)', _eCorsiScore, 0, 15, (v) => setState(() => _eCorsiScore = v), accentColor),
            
            // Memory Palace (např. 0 - 30 slov)
            _buildSlider('Memory Palace (Skóre)', _palaceScore, 0, 30, (v) => setState(() => _palaceScore = v), accentColor),
            
            // DNB Úspěšnost (0 - 100 %)
            _buildSlider('Dual N-Back (Úspěšnost %)', _dnbSuccessRate, 0, 100, (v) => setState(() => _dnbSuccessRate = v), accentColor),

            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveAndBypass,
              icon: const Icon(Icons.fast_forward_rounded),
              label: const Text('ULOŽIT A PŘESKOČIT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${value.toInt()}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: color,
            inactiveColor: Colors.white24,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
