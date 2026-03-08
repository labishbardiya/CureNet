import 'package:flutter/material.dart';
import '../core/theme.dart';

class HealthLockerScreen extends StatelessWidget {
  const HealthLockerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFD8DDE6))),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text("←", style: TextStyle(fontSize: 26, color: Color(0xFF0D2240))),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Health Locker",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0D2240)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Security Badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00A3A3), Color(0xFF1A3A5C)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Text("🛡️", style: TextStyle(fontSize: 16))),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your Data is Secure",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              Text(
                                "Zero-Knowledge Proofs • DPDP Compliant",
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Locker Cards
                  _lockerCard("Prescriptions", "5 documents", "💊", const Color(0xFFE07B39), () {}),
                  _lockerCard("Lab Reports", "3 documents", "🧪", const Color(0xFF00A3A3), () {}),
                  _lockerCard("Imaging", "2 documents", "🩻", const Color(0xFF6B4E9B), () {}),
                  _lockerCard("Discharge Summaries", "1 document", "🏥", const Color(0xFF22A36A), () {}),

                  const SizedBox(height: 32),

                  // Add Document Button
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/doc-scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A3A3),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("📷 ", style: TextStyle(fontSize: 20)),
                        Text(
                          "Add New Document",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        height: 78,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFD8DDE6))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem("🏠", "Home", false, () => Navigator.pushReplacementNamed(context, '/home')),
            _navItem("🤖", "ABHAy", false, () => Navigator.pushReplacementNamed(context, '/chat')),
            _scanButton(context),
            _navItem("📋", "Records", false, () => Navigator.pushReplacementNamed(context, '/records')),
            _navItem("📲", "Share", false, () => Navigator.pushReplacementNamed(context, '/qr-share')),
          ],
        ),
      ),
    );
  }

  Widget _lockerCard(String title, String count, String icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8DDE6)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(icon, style: TextStyle(fontSize: 24, color: color))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(
                    count,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9BA8BB)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF00A3A3)),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String icon, String label, bool active, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: TextStyle(fontSize: 22, color: active ? const Color(0xFF00A3A3) : const Color(0xFF9BA8BB))),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? const Color(0xFF00A3A3) : const Color(0xFF9BA8BB))),
        ],
      ),
    );
  }

  Widget _scanButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/doc-scan'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00A3A3), Color(0xFF00C4C4)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("📷", style: TextStyle(fontSize: 20, color: Colors.white)),
                  Text("SCAN", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}