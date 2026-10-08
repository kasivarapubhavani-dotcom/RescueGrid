import 'package:flutter/material.dart';
import 'widgets.dart';

/// First page of the app: a "Campus Safety" landing screen.
/// Wide screens show text on the left and the phone on the right.
/// Narrow screens stack the phone above the text.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: NightPainter())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 860;
                final Widget content;
                if (wide) {
                  final phoneH = (c.maxHeight - 48).clamp(380.0, 620.0).toDouble();
                  content = ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: _Pitch(onStart: widget.onStart, centered: false),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: SizedBox(
                                width: phoneH / 2,
                                height: phoneH,
                                child: PhoneMock(
                                    pulse: _pulse, onAlert: widget.onStart),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final w = (c.maxWidth * 0.6).clamp(180.0, 250.0).toDouble();
                  content = Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: w,
                          height: w * 2,
                          child: PhoneMock(pulse: _pulse, onAlert: widget.onStart),
                        ),
                        const SizedBox(height: 28),
                        _Pitch(onStart: widget.onStart, centered: true),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: Center(child: content),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- pitch ----
class _Pitch extends StatelessWidget {
  const _Pitch({required this.onStart, required this.centered});
  final VoidCallback onStart;
  final bool centered;

  Widget _feature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFC46B), size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final align = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Text(
          'Campus Safety',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white,
            fontSize: centered ? 36 : 54,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Report an emergency in seconds. Help is matched to you automatically, and you can follow every step.',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
        ),
        const SizedBox(height: 20),
        _feature(Icons.my_location, 'Share your exact location instantly'),
        _feature(Icons.bolt, 'Smart severity scoring and responder dispatch'),
        _feature(Icons.timeline, 'Live tracking from report to resolution'),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: brandMaroon,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          onPressed: onStart,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Get started'),
        ),
        const SizedBox(height: 10),
        const Text(
          'For students, responders and the command center',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ phone mock ----
class PhoneMock extends StatelessWidget {
  const PhoneMock({super.key, required this.pulse, required this.onAlert});
  final Animation<double> pulse;
  final VoidCallback onAlert;

  @override
  Widget build(BuildContext context) {
    // Designed at 260 x 520 and scaled to fit whatever space it is given.
    return FittedBox(
      child: SizedBox(
        width: 260,
        height: 520,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(160),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: brandMaroon.withAlpha(90),
                blurRadius: 60,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              color: brandMaroon,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 58,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(80),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Campus Safety',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const ShieldMark(),
                  const SizedBox(height: 22),
                  AlertButton(pulse: pulse, onTap: onAlert),
                  const Spacer(),
                  Container(
                    height: 52,
                    color: const Color(0xFF3A0D12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.home_outlined, color: Colors.white70, size: 22),
                        Icon(Icons.location_on_outlined,
                            color: Colors.white70, size: 22),
                        Icon(Icons.phone_outlined, color: Colors.white70, size: 22),
                        Icon(Icons.notifications_none,
                            color: Colors.white70, size: 22),
                        Icon(Icons.more_vert, color: Colors.white70, size: 22),
                      ],
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

class ShieldMark extends StatelessWidget {
  const ShieldMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 118, color: Colors.white),
        Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Icon(Icons.priority_high, size: 54, color: Colors.white),
        ),
      ],
    );
  }
}

class AlertButton extends StatelessWidget {
  const AlertButton({super.key, required this.pulse, required this.onTap});
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 124,
          height: 124,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              final t = pulse.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 84 + 40 * t,
                    height: 84 + 40 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha((130 * (1 - t)).round()),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Text(
                      'ALERT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------ night background ----
class NightPainter extends CustomPainter {
  const NightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF05070D), Color(0xFF111522), Color(0xFF2A0E14)],
        ).createShader(rect),
    );

    void glow(double fx, double fy, double r, Color c, int alpha) {
      final center = Offset(size.width * fx, size.height * fy);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [c.withAlpha(alpha), c.withAlpha(0)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    const warm = Color(0xFFFFC46B);
    // Street lamps fading into the distance on the left.
    glow(0.10, 0.30, 110, warm, 150);
    glow(0.10, 0.30, 26, warm, 230);
    glow(0.19, 0.42, 70, warm, 120);
    glow(0.19, 0.42, 16, warm, 220);
    glow(0.27, 0.50, 44, warm, 100);
    glow(0.27, 0.50, 10, warm, 200);
    // A faint lamp on the right and a red glow rising from the bottom.
    glow(0.92, 0.22, 70, warm, 70);
    glow(0.5, 1.05, size.width * 0.55, brandMaroon, 110);
  }

  @override
  bool shouldRepaint(covariant NightPainter oldDelegate) => false;
}
