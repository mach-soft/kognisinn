import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wiredash/wiredash.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../main.dart'; // Import pro přístup k přepínači useTelemetry

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  // Bezpečná funkce pro otevírání externích webových odkazů
  Future<void> _openWebLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Nelze otevřít odkaz: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF00E5FF);
    const Color warningColor = Color(0xFFFF4B4B); // Barva pro lékařské upozornění
    const Color cardBgColor = Colors.white10;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings_about_app'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F19), Color(0xFF1A1A2E)], // Jednotné temné pozadí
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HLAVIČKA (Logo a Verze) ---
                const SizedBox(height: 10),
                const Icon(Icons.info_outline_rounded, size: 70, color: accentColor),
                const SizedBox(height: 16),
                Text(
                  'menu_title'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                ),
                Text(
                  'menu_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                
                // AUTOMATICKÉ NAČTENÍ VERZE Z PUBSPEC.YAML
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Text(
                        '${'about_version'.tr()} ...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w500),
                      );
                    }
                    
                    final String version = snapshot.data!.version;
                    final String buildNumber = snapshot.data!.buildNumber;
                    
                    return Text(
                      '${'about_version'.tr()} $version ($buildNumber)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w500),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // --- SEKCE 1: OCHRANA SOUKROMÍ (Změna textu podle verze) ---
                _buildSectionHeader('about_privacy'.tr(), Icons.security_rounded, accentColor),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    // KLÍČOVÁ VÝHYBKA: Podle useTelemetry vybere správný překlad z json souborů
                    useTelemetry ? 'about_privacy_text'.tr() : 'about_privacy_text_clean'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),

                // --- SEKCE 2: MEDICAL DISCLAIMER (PŘIDÁNO) ---
                _buildSectionHeader('onboard_disclaimer_title'.tr(), Icons.health_and_safety_outlined, warningColor),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: warningColor.withAlpha(80)), // Jemný červený obrys pro zdůraznění
                  ),
                  child: Text(
                    'onboard_disclaimer_desc'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),

                // --- SEKCE 3: PODPORA VÝVOJE ---
                _buildSectionHeader('about_support_title'.tr(), Icons.coffee_rounded, accentColor),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'about_support_text'.tr(),
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFDD00), // Oficiální žlutá barva Ko-fi
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        // Nezapomeň pak případně upravit i tento odkaz
                        onPressed: () => _openWebLink('https://ko-fi.com/machsoft'), 
                        icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                        label: Text('about_btn_donate'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- SEKCE 4: TIRÁŽ A KONTAKT ---
                _buildSectionHeader('about_impressum'.tr(), Icons.business_center_rounded, accentColor),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _buildImpressumRow('about_developer'.tr(), 'Mach Soft'),
                      _buildImpressumRow('about_address'.tr(), 'Olešnice 126, 517 36, ČR'),
                      _buildImpressumRow('about_contact'.tr(), 'info@mach-soft.eu'),
                      GestureDetector(
                        onTap: () => _openWebLink('https://www.mach-soft.eu'),
                        child: _buildImpressumRow(
                          'about_website'.tr(), 
                          'www.mach-soft.eu', 
                          isValueLink: true, 
                          accentColor: accentColor
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- SEKCE 5: WIREDASH FEEDBACK ---
                if (useTelemetry) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(15),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: accentColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Wiredash.of(context).show(),
                    icon: const Icon(Icons.bug_report_rounded, color: accentColor),
                    label: Text('global_feedback_btn'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pomocný widget pro nadpisy sekcí
  Widget _buildSectionHeader(String title, IconData icon, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  // Pomocný widget pro řádky v Tiráži
  Widget _buildImpressumRow(String label, String value, {bool isValueLink = false, Color? accentColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isValueLink ? (accentColor ?? Colors.blue) : Colors.white,
                fontSize: 14,
                fontWeight: isValueLink ? FontWeight.bold : FontWeight.normal,
                decoration: isValueLink ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
