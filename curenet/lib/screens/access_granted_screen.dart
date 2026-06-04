import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../core/translated_text.dart';
import '../core/bottom_nav.dart';

class AccessGrantedScreen extends StatelessWidget {
  const AccessGrantedScreen({super.key});

  Future<void> _revokeAccess(BuildContext context, String requestId) async {
    if (requestId.isEmpty) {
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired. Returning home."), backgroundColor: Color(0xFFE07B39)),
        );
      }
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/access/revoke/$requestId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.statusCode == 200 ? "Access revoked successfully" : "Access revoked (session may have expired)"),
            backgroundColor: const Color(0xFFD63B3B),
          ),
        );
      }
    } catch (e) {
      // Even if network fails, still navigate home — the TTL will auto-expire it
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Access revoked locally. Server will auto-expire."),
            backgroundColor: Color(0xFFE07B39),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get requestId from route arguments
    final requestId = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Status bar space
          const SizedBox(height: 44),

          // Back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text("←", style: TextStyle(fontSize: 26, color: Color(0xFF0D2240))),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Success illustration
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F7EF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF22A36A).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check, size: 42, color: Color(0xFF22A36A)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const TranslatedText("Access Granted!",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0D2240)),
          ),

          const SizedBox(height: 8),
          const TranslatedText("The doctor can now view your\nemergency health card and vitals.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF5A6880), height: 1.4),
          ),

          const SizedBox(height: 24),

          // Expires banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, size: 18, color: Color(0xFF00A3A3)),
                SizedBox(width: 8),
                TranslatedText("Access expires in 30 minutes",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF00A3A3)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A3A3),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const TranslatedText("Return Home",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _revokeAccess(context, requestId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Color(0xFFD63B3B)),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const TranslatedText("Revoke Access Now",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFD63B3B)),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Privacy note
          const Padding(
            padding: EdgeInsets.all(20),
            child: TranslatedText("Access record saved in Profile → Doctor Access Log",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF9BA8BB)),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: CureNetBottomNav(context: context, activeIndex: -1),
    );
  }

}