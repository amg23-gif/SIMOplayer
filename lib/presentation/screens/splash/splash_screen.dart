import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import '../../../core/constants/app_constants.dart';

  class SplashScreen extends ConsumerStatefulWidget {
    const SplashScreen({super.key});

    @override
    ConsumerState<SplashScreen> createState() => _SplashScreenState();
  }

  class _SplashScreenState extends ConsumerState<SplashScreen>
      with SingleTickerProviderStateMixin {
    late AnimationController _animController;
    late Animation<double> _fadeAnim;
    late Animation<double> _scaleAnim;

    @override
    void initState() {
      super.initState();
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
      _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
      );
      _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
      );
      _animController.forward();
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) context.go(AppConstants.routeHome);
      });
    }

    @override
    void dispose() {
      _animController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) => Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SIMO Player',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'مشغل IPTV الاحترافي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: Color(0xFF8B949E),
                      ),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF1565C0).withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
  