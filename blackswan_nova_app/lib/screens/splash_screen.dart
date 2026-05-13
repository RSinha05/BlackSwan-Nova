import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showButton = true);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _enterDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E17),
              Color(0xFF0D1321),
              Color(0xFF0A0E17),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Grid overlay
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _GridPainter(),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo glow
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(
                                  alpha: 0.15 + _pulseController.value * 0.2),
                              blurRadius: 40 + _pulseController.value * 30,
                              spreadRadius: 5 + _pulseController.value * 10,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00F0FF)
                                  .withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF00F0FF).withValues(alpha: 0.15),
                                const Color(0xFF7B61FF).withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.show_chart_rounded,
                            color: Color(0xFF00F0FF),
                            size: 40,
                          ),
                        ),
                      );
                    },
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.5, 0.5)),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'BLACKSWAN',
                    style: GoogleFonts.spaceMono(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.3),

                  const SizedBox(height: 4),

                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00F0FF), Color(0xFF7B61FF)],
                    ).createShader(bounds),
                    child: Text(
                      'NOVA',
                      style: GoogleFonts.spaceMono(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 14,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 0.3),

                  const SizedBox(height: 16),

                  Text(
                    'Where uncertainty is engineered into insight.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

                  const SizedBox(height: 48),

                  // Initialize button
                  if (_showButton)
                    GestureDetector(
                      onTap: _enterDashboard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                const Color(0xFF00F0FF).withValues(alpha: 0.4),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00F0FF).withValues(alpha: 0.08),
                              const Color(0xFF7B61FF).withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'INITIALIZE ENGINE',
                              style: GoogleFonts.spaceMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF00F0FF),
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward,
                                color: Color(0xFF00F0FF), size: 18),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2),
                ],
              ),
            ),

            // Version badge
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'v1.0.0  ·  MOBILE COMPANION',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.2),
                  letterSpacing: 3,
                ),
              ).animate().fadeIn(delay: 1200.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
