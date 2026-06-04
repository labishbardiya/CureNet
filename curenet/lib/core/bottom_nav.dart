import 'package:flutter/material.dart';
import '../core/translated_text.dart';

/// Shared bottom navigation bar used across all CureNet screens.
///
/// [activeIndex] highlights the current tab:
///   0 = Home, 1 = ABHAy, 2 = Scan, 3 = Records, 4 = Share
///   Use -1 for screens that are not part of the main 5 tabs.
class CureNetBottomNav extends StatelessWidget {
  const CureNetBottomNav({
    super.key,
    required this.context,
    required this.activeIndex,
  });

  final BuildContext context;
  final int activeIndex;

  @override
  Widget build(BuildContext _) {
    return Container(
      height: 78,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD8DDE6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomNavItem(Icons.home, "Home", activeIndex == 0, onTap: () {
            if (activeIndex != 0) Navigator.pushReplacementNamed(context, '/home');
          }),
          _bottomNavItem(Icons.smart_toy, "ABHAy", activeIndex == 1, onTap: () {
            if (activeIndex != 1) Navigator.pushReplacementNamed(context, '/chat');
          }),
          _scanButton(context),
          _bottomNavItem(Icons.list_alt, "Records", activeIndex == 3, onTap: () {
            if (activeIndex != 3) Navigator.pushReplacementNamed(context, '/records');
          }),
          _bottomNavItem(Icons.share, "Share", activeIndex == 4, onTap: () {
            if (activeIndex != 4) Navigator.pushReplacementNamed(context, '/qr-share');
          }),
        ],
      ),
    );
  }

  Widget _bottomNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE8F7F7) : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(child: Icon(icon, size: 22, color: isActive ? const Color(0xFF00A3A3) : const Color(0xFF9BA8BB))),
          ),
          TranslatedText(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? const Color(0xFF00A3A3) : const Color(0xFF9BA8BB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (ModalRoute.of(context)?.settings.name != '/doc-scan') {
          Navigator.pushNamed(context, '/doc-scan');
        }
      },
      child: Transform.translate(
        offset: const Offset(0, -24),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00A3A3), Color(0xFF00C4C4)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A3A3).withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.camera_alt, size: 28, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
