import 'package:flutter/material.dart';
import '../core/theme.dart';

class RegisterOptionsScreen extends StatefulWidget {
  const RegisterOptionsScreen({super.key});

  @override
  State<RegisterOptionsScreen> createState() => _RegisterOptionsScreenState();
}

class _RegisterOptionsScreenState extends State<RegisterOptionsScreen> {
  String selectedMethod = ''; // 'mobile', 'email', 'aadhaar'

  void selectMethod(String method) {
    setState(() => selectedMethod = method);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header – exact v5
            Container(
              padding: const EdgeInsets.fromLTRB(18, 44, 18, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFD8DDE6))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('←', style: TextStyle(fontSize: 26, color: Color(0xFF0D2240))),
                  ),
                  const Spacer(),
                  const Text(
                    'Create ABHA',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0D2240)),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose how to create\nyour ABHA',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF0D2240)),
                    ),
                    const SizedBox(height: 24),

                    // Mobile Option Card
                    GestureDetector(
                      onTap: () => selectMethod('mobile'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'mobile' ? const Color(0xFFE8F7F7) : Colors.white,
                          border: Border.all(
                            color: selectedMethod == 'mobile' ? const Color(0xFF00A3A3) : const Color(0xFFD8DDE6),
                            width: selectedMethod == 'mobile' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F7F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.phone_android, size: 24, color: Color(0xFF00A3A3)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mobile Number',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D2240)),
                                  ),
                                  Text(
                                    'Use your Indian mobile number to create ABHA',
                                    style: TextStyle(fontSize: 14, color: Color(0xFF9BA8BB)),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedMethod == 'mobile')
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF00A3A3)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email Option Card
                    GestureDetector(
                      onTap: () => selectMethod('email'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'email' ? const Color(0xFFE8F7F7) : Colors.white,
                          border: Border.all(
                            color: selectedMethod == 'email' ? const Color(0xFF00A3A3) : const Color(0xFFD8DDE6),
                            width: selectedMethod == 'email' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F7F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.email_outlined, size: 24, color: Color(0xFF00A3A3)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email Address',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D2240)),
                                  ),
                                  Text(
                                    'Use your email to create ABHA',
                                    style: TextStyle(fontSize: 14, color: Color(0xFF9BA8BB)),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedMethod == 'email')
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF00A3A3)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Aadhaar Option Card
                    GestureDetector(
                      onTap: () => selectMethod('aadhaar'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'aadhaar' ? const Color(0xFFE8F7F7) : Colors.white,
                          border: Border.all(
                            color: selectedMethod == 'aadhaar' ? const Color(0xFF00A3A3) : const Color(0xFFD8DDE6),
                            width: selectedMethod == 'aadhaar' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F7F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fingerprint_outlined, size: 24, color: Color(0xFF00A3A3)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Aadhaar Number',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D2240)),
                                  ),
                                  Text(
                                    'Use your Aadhaar for quick verification',
                                    style: TextStyle(fontSize: 14, color: Color(0xFF9BA8BB)),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedMethod == 'aadhaar')
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF00A3A3)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(18),
              child: ElevatedButton(
                onPressed: selectedMethod.isEmpty ? null : () {
                  // Navigate based on selection
                  if (selectedMethod == 'mobile') {
                    Navigator.pushNamed(context, '/create-abha-mobile');
                  } else if (selectedMethod == 'email') {
                    // TODO: Email flow
                  } else if (selectedMethod == 'aadhaar') {
                    // TODO: Aadhaar flow
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedMethod.isEmpty ? const Color(0xFFD8DDE6) : const Color(0xFF00A3A3),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selectedMethod.isEmpty ? const Color(0xFF9BA8BB) : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}