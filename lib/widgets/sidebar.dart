import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../providers/device_provider.dart';
import 'package:flutter/material.dart';
import '../constants.dart';

enum ViewType { rooms, devices, curtain, aircon, light }

extension ViewTypeLabel on ViewType {
  String get label {
    switch (this) {
      case ViewType.rooms:   return 'Floor Plan';
      case ViewType.devices: return 'All Devices';
      case ViewType.curtain: return 'Blinds';
      case ViewType.aircon:  return 'Aircon';
      case ViewType.light:   return 'Lights';
    }
  }

  IconData get icon {
    switch (this) {
      case ViewType.rooms:   return Icons.dashboard_rounded;
      case ViewType.devices: return Icons.devices_rounded;
      case ViewType.curtain: return Icons.blinds_rounded;
      case ViewType.aircon:  return Icons.ac_unit_rounded;
      case ViewType.light:   return Icons.lightbulb_rounded;
    }
  }

  Color get iconColor {
    switch (this) {
      case ViewType.rooms:   return const Color(0xFF60A5FA);
      case ViewType.devices: return const Color(0xFF34D399);
      case ViewType.curtain: return const Color(0xFFC084FC);
      case ViewType.aircon:  return const Color(0xFF67E8F9);
      case ViewType.light:   return const Color(0xFFFBBF24);
    }
  }
}

class Sidebar extends StatefulWidget {
  final ViewType activeView;
  final void Function(ViewType) onNavigate;

  const Sidebar({
    super.key,
    required this.activeView,
    required this.onNavigate,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
  String get _timeStr {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    return '$h:${_pad(_now.minute)}';
  }

  String get _amPm => _now.hour < 12 ? 'AM' : 'PM';
  String get _secStr  => _pad(_now.second);

  String get _dateStr {
    const wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${wd[_now.weekday - 1]}, ${mo[_now.month - 1]} ${_now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F0F12),
            const Color(0xFF141418),
          ],
        ),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: app name ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  '3Core Office Control',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Clock card ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E1E26),
                    const Color(0xFF18181F),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _timeStr,
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                          letterSpacing: -2,
                          height: 1.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5, left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _amPm,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.45),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              ':$_secStr',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withOpacity(0.25),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.40),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Section label ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 0, 8),
            child: Text(
              'NAVIGATION',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nav items ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: ViewType.values
                          .where((v) =>
                              v != ViewType.curtain &&
                              v != ViewType.aircon &&
                              v != ViewType.light)
                          .map((view) {
                        final active = widget.activeView == view;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => widget.onNavigate(view),
                              splashColor: view.iconColor.withOpacity(0.15),
                              highlightColor: view.iconColor.withOpacity(0.08),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 11),
                                decoration: BoxDecoration(
                                  color: active
                                      ? view.iconColor.withOpacity(0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: active
                                      ? Border.all(
                                          color: view.iconColor.withOpacity(0.25))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Icon container
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? view.iconColor.withOpacity(0.20)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        view.icon,
                                        color: active
                                            ? view.iconColor
                                            : Colors.white.withOpacity(0.35),
                                        size: 17,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      view.label,
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.45),
                                        fontWeight: active
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    if (active) ...[ 
                                      const Spacer(),
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: view.iconColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Waveform bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            child: SizedBox(
              height: 28,
              child: CustomPaint(
                size: const Size(double.infinity, 28),
                painter: _WaveformPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bars = 28;
    final barW = (size.width - bars * 2) / bars;
    final rng = math.Random(42);

    for (int i = 0; i < bars; i++) {
      final h = 6.0 + rng.nextDouble() * (size.height - 8);
      final x = i * (barW + 2);
      final y = (size.height - h) / 2;

      final t = i / bars;
      final color = Color.lerp(
        const Color(0xFF6366F1),
        const Color(0xFF06B6D4),
        t,
      )!;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, h),
          const Radius.circular(2),
        ),
        Paint()..color = color.withOpacity(0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
