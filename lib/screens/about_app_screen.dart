import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  // --- FUNKCE PRO OTEVŘENÍ KO-FI V PROHLÍŽEČI ---
  Future<void> _launchKofi() async {
    // ZDE SI PAK UPRAVÍŠ ODKAZ NA SVŮJ REÁLNÝ PROFIL
    final Uri url = Uri.parse('https://ko-fi.com/machsoft'); 
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Nepodařilo se otevřít odkaz $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color cardBg = isDark ? Colors.white.withAlpha(15) : accentColor.withAlpha(10);
    final Color borderColor = isDark ? Colors.white12 : accentColor.withAlpha(30);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    
    // Barva specifická pro sekci podpory (Ko-fi korálová)
    const Color kofiColor = Color(0xFFFF5E5B);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter, 
            colors: isDark 
              ? [const Color(0xFF0B0F19), const Color(0xFF1A1A2E)] 
              : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)]
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: textColor),
                title: Text(
                  'settings_about_app'.tr(), 
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 16)
                ),
                centerTitle: true,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Hlavička aplikace
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(20),
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor.withAlpha(50), width: 2)
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                'assets/logo.png', 
                                width: 70, 
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return SizedBox(width: 70, height: 70, child: Icon(Icons.broken_image_rounded, color: accentColor, size: 40,));
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Kognix', 
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 4)
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${'about_version'.tr()} 1.0', 
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- SEKCE PODPORY (KO-FI) ---
                    _sectionTitle('about_support_title'.tr(), kofiColor),
                    _card(
                      isDark ? kofiColor.withAlpha(15) : kofiColor.withAlpha(10), 
                      isDark ? kofiColor.withAlpha(30) : kofiColor.withAlpha(40), 
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.favorite_rounded, color: kofiColor, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'about_support_text'.tr(),
                                    style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kofiColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.coffee_rounded, size: 20),
                                label: Text('about_btn_donate'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.2)),
                                onPressed: _launchKofi,
                              ),
                            )
                          ],
                        ),
                      )
                    ),
                    
                    const SizedBox(height: 32),

                    // Ochrana osobních údajů (Privacy)
                    _sectionTitle('about_privacy'.tr(), accentColor),
                    _card(cardBg, borderColor, Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_rounded, color: accentColor, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'about_privacy_text'.tr(),
                              style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    )),
                    
                    const SizedBox(height: 32),

                    // Tiráž (Impressum)
                    _sectionTitle('about_impressum'.tr(), accentColor),
                    _card(cardBg, borderColor, Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _infoRow('about_developer'.tr(), 'Mach Soft', isDark, accentColor),
                          const Divider(height: 24, color: Colors.white12),
                          _infoRow('about_address'.tr(), 'Olešnice 126\n517 36 Olešnice\nČeská republika', isDark, accentColor),
                          const Divider(height: 24, color: Colors.white12),
                          _infoRow('about_contact'.tr(), 'info@mach-soft.eu', isDark, accentColor),
                          const Divider(height: 24, color: Colors.white12),
                          _infoRow('about_website'.tr(), 'mach-soft.eu/kognix', isDark, accentColor),
                        ],
                      ),
                    )),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(text.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 2)),
  );

  Widget _card(Color bg, Color border, Widget child) => Container(
    decoration: BoxDecoration(
      color: bg, 
      borderRadius: BorderRadius.circular(24), 
      border: Border.all(color: border, width: 1.5)
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _infoRow(String label, String value, bool isDark, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        ),
      ],
    );
  }
}
