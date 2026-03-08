import 'package:flutter/material.dart';
import '../core/theme.dart';

class EdgeCasesScreen extends StatelessWidget {
  const EdgeCasesScreen({super.key});

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
                  "Edge Cases",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0D2240)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // No Internet State
                  _edgeCaseCard(
                    title: "No Internet Connection",
                    icon: "📡",
                    iconColor: const Color(0xFFD63B3B),
                    description: "Your app works offline! All scans and summaries are saved locally and will sync when you're back online.",
                    action: "Try Again",
                    onAction: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("🔄 Attempting reconnection..."), backgroundColor: Color(0xFF00A3A3)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Empty Records State
                  _edgeCaseCard(
                    title: "No Records Yet",
                    icon: "📂",
                    iconColor: const Color(0xFFE07B39),
                    description: "Your Health Locker is empty. Start by scanning your first prescription or report!",
                    action: "Scan First Document",
                    onAction: () => Navigator.pushNamed(context, '/doc-scan'),
                  ),

                  const SizedBox(height: 16),

                  // Error State
                  _edgeCaseCard(
                    title: "Scan Failed",
                    icon: "❌",
                    iconColor: const Color(0xFFD63B3B),
                    description: "Couldn't read the document. Please ensure good lighting and try again.",
                    action: "Retry Scan",
                    onAction: () => Navigator.pushNamed(context, '/doc-scan'),
                  ),

                  const SizedBox(height: 16),

                  // Low Storage Warning
                  _edgeCaseCard(
                    title: "Low Storage",
                    icon: "💾",
                    iconColor: const Color(0xFF9BA8BB),
                    description: "Your device storage is almost full. Delete old scans or free up space to continue.",
                    action: "Manage Storage",
                    onAction: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("📱 Opening device settings..."), backgroundColor: Color(0xFF9BA8BB)),
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

  Widget _edgeCaseCard({
    required String title,
    required String icon,
    required Color iconColor,
    required String description,
    required String action,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8DDE6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(icon, style: TextStyle(fontSize: 20, color: iconColor))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5A6880), height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3A3),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
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