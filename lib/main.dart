import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/mock_api_client.dart';
import 'core/theme.dart';
import 'providers/bookings_provider.dart';
import 'providers/hotel_list_provider.dart';
import 'providers/nav_provider.dart';
import 'providers/profile_provider.dart';
import 'repositories/hotel_repository.dart';
import 'screens/app_shell.dart';

void main() => runApp(const StayScapeApp());

class StayScapeApp extends StatelessWidget {
  const StayScapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HotelRepository>(
          create: (_) => HotelRepository(MockApiClient.instance),
        ),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(
          create: (c) => HotelListProvider(c.read<HotelRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (c) => BookingsProvider(c.read<HotelRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (c) => ProfileProvider(c.read<HotelRepository>())..load(),
        ),
      ],
      child: MaterialApp(
        title: 'StayScape',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const LuxurySplashScreen(),
      ),
    );
  }
}

class LuxurySplashScreen extends StatefulWidget {
  const LuxurySplashScreen({super.key});

  @override
  State<LuxurySplashScreen> createState() => _LuxurySplashScreenState();
}

class _LuxurySplashScreenState extends State<LuxurySplashScreen>
    with TickerProviderStateMixin {
  static const Color navy = Color(0xFF06172D);
  static const Color deepNavy = Color(0xFF020B19);
  static const Color gold = Color(0xFFE9C783);
  static const Color paleGold = Color(0xFFFFE7B0);

  late final AnimationController _introController;
  late final AnimationController _waveController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _wordFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _bottomFade;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.38, curve: Curves.easeIn),
    );

    _logoScale = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _wordFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.25, 0.65, curve: Curves.easeIn),
    );

    _taglineFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.48, 0.78, curve: Curves.easeIn),
    );

    _bottomFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
    );

    _introController.forward();

    Future.delayed(const Duration(milliseconds: 3400), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 850),
          pageBuilder: (_, animation, secondaryAnimation) => const AppShell(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Deep navy luxury gradient.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF071B34),
                  navy,
                  deepNavy,
                ],
              ),
            ),
          ),

          // Soft central glow.
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    gold.withValues(alpha: 0.075),
                    gold.withValues(alpha: 0.025),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Animated gold waves near the bottom.
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            height: 190,
            child: FadeTransition(
              opacity: _bottomFade,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GoldWavePainter(
                      progress: _waveController.value,
                      color: gold,
                    ),
                  );
                },
              ),
            ),
          ),

          // Centered brand.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _LuxuryLogo(
                        gold: gold,
                        paleGold: paleGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  FadeTransition(
                    opacity: _wordFade,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [paleGold, gold],
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'StayScape',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Georgia',
                          fontSize: 43,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: const Text(
                      'H O T E L S   &   S T A Y S',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: paleGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Container(
                      width: 42,
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            gold,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: const Text(
                      'Better stays. Bigger memories.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFC2CAD5),
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Small animated loading indicator.
          Positioned(
            left: 0,
            right: 0,
            bottom: 65,
            child: FadeTransition(
              opacity: _bottomFade,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Center(
                    child: SizedBox(
                      width: 110,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Container(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.28,
                              child: Align(
                                alignment: Alignment(
                                  -1.0 + 2 * _waveController.value,
                                  0,
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [gold, paleGold],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxuryLogo extends StatelessWidget {
  final Color gold;
  final Color paleGold;

  const _LuxuryLogo({
    required this.gold,
    required this.paleGold,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: gold.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
          ),

          // Stylized architectural S logo.
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [paleGold, gold, const Color(0xFFB88A43)],
            ).createShader(bounds),
            child: const Icon(
              Icons.apartment_rounded,
              size: 53,
              color: Colors.white,
            ),
          ),

          Positioned(
            bottom: 8,
            child: Container(
              width: 65,
              height: 2,
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),

          Positioned(
            bottom: 1,
            child: Container(
              width: 45,
              height: 2,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoldWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  GoldWavePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final baseY = size.height * (0.42 + i * 0.13);
      final shift = progress * size.width;

      path.moveTo(0, baseY + 15);

      path.cubicTo(
        size.width * 0.20,
        baseY - 45 + shift * 0.03,
        size.width * 0.38,
        baseY + 65,
        size.width * 0.60,
        baseY + 5,
      );

      path.cubicTo(
        size.width * 0.77,
        baseY - 40,
        size.width * 0.90,
        baseY + 5 - shift * 0.02,
        size.width,
        baseY - 18,
      );

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 1.1 : 0.65
        ..color = color.withValues(
          alpha: i == 0 ? 0.65 : 0.20,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GoldWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
