import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'app_shell.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _finished = true);
        }
      });
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_finished) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _finished
          ? const AppShell(key: ValueKey('app-shell'))
          : _buildIntro(),
    );
  }

  Widget _buildIntro() {
    final markFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.68, curve: Curves.easeOut),
    );
    final textFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.2, 0.78, curve: Curves.easeOut),
    );
    final progress = CurvedAnimation(parent: _intro, curve: Curves.easeInOut);

    return Scaffold(
      key: const ValueKey('launch-page'),
      backgroundColor: const Color(0xFF08080C),
      body: AnimatedBuilder(
        animation: _intro,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CinemaBackdrop(progress: _intro.value),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 26),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 7,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'EDIÇÃO PRIVADA · NO SEU APARELHO',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _continue,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Pular'),
                        ),
                      ],
                    ),
                    const Spacer(flex: 3),
                    FadeTransition(
                      opacity: markFade,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.76, end: 1).animate(
                          CurvedAnimation(
                            parent: _intro,
                            curve: const Interval(
                              0,
                              0.72,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                        ),
                        child: _BrandMark(progress: _intro.value),
                      ),
                    ),
                    const SizedBox(height: 38),
                    FadeTransition(
                      opacity: textFade,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(textFade),
                        child: Column(
                          children: [
                            Text(
                              'Aprimorar',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.brand.createShader(bounds),
                              child: Text(
                                'Vídeo',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Sua história. Em alta definição.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    FadeTransition(
                      opacity: textFade,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.55),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ATÉ 4K',
                              style: TextStyle(
                                color: AppColors.teal,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'DETALHES QUE FAZEM A DIFERENÇA',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress.value,
                        minHeight: 2,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'PREPARANDO SEU ESTÚDIO',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            letterSpacing: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              gradient: AppColors.brand,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  blurRadius: 42,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.movie_creation_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
          Positioned(
            right: 3,
            top: 15,
            child: Transform.rotate(
              angle: (1 - progress) * 0.7,
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: const Color(0xFF08080C),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.teal, width: 2),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CinemaBackdrop extends CustomPainter {
  const _CinemaBackdrop({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final beamCenter =
        Offset(size.width * (progress * 1.8 - 0.4), size.height * 0.4);
    final beam = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.11),
          AppColors.primary.withValues(alpha: 0.025),
          Colors.transparent,
        ],
        stops: const [0, 0.36, 1],
      ).createShader(
        Rect.fromCircle(center: beamCenter, radius: size.width * 0.8),
      );
    canvas.drawRect(Offset.zero & size, beam);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var index = 0; index < 8; index++) {
      final y = size.height * (0.13 + index * 0.105);
      canvas.drawLine(Offset.zero.translate(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CinemaBackdrop oldDelegate) =>
      oldDelegate.progress != progress;
}