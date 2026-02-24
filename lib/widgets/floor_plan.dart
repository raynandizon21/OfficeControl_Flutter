import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';

class FloorPlanWidget extends StatefulWidget {
  const FloorPlanWidget({super.key});

  @override
  State<FloorPlanWidget> createState() => _FloorPlanWidgetState();
}

class _FloorPlanWidgetState extends State<FloorPlanWidget> {
  String? _openCurtainId;

  bool get _isTablet => MediaQuery.of(context).size.width <= 1280;

  String get _assetPath => _isTablet
      ? 'assets/images/floor_plan_tablet.png'
      : 'assets/images/floor_plan_desktop.png';

  double get _aspectRatio => _isTablet ? 0.65 : 1.6;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final lights = provider.devices.where((d) => d.type == DeviceType.light).toList();
    final curtains = provider.devices
        .where((d) => d.type == DeviceType.curtain && kCurtainDesktopCoords.containsKey(d.id))
        .toList();
    final isTablet = _isTablet;

    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              return Stack(
                children: [
                  // Floor plan image
                  Positioned.fill(
                    child: Image.asset(
                      _assetPath,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Curtain horizontal lines
                  for (final curtain in curtains)
                    _buildCurtainLine(curtain, w, h, isTablet),

                  // Dismiss barrier — tap outside curtain panel to close
                  if (_openCurtainId != null)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => setState(() => _openCurtainId = null),
                        behavior: HitTestBehavior.translucent,
                        child: const SizedBox.expand(),
                      ),
                    ),

                  // Curtain control panel
                  if (_openCurtainId != null)
                    _buildCurtainPanel(
                      curtains.firstWhere((c) => c.id == _openCurtainId,
                          orElse: () => curtains.first),
                      w, h, isTablet, provider,
                    ),


                  // Light icons
                  for (final light in lights)
                    _buildLightIcon(light, w, h, isTablet, provider),


                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Curtain line
  // ---------------------------------------------------------------------------

  Widget _buildCurtainLine(Device curtain, double w, double h, bool isTablet) {
    final pos = isTablet
        ? kCurtainTabletCoords[curtain.id]
        : kCurtainDesktopCoords[curtain.id];
    if (pos == null) return const SizedBox();

    final left = w * pos.left / 100;
    final top = h * pos.top / 100;
    final lineW = w * pos.width / 100;
    final isOpen = _openCurtainId == curtain.id;

    // Large tap area (40px tall) wrapping a thin visual line (8px)
    return Positioned(
      left: left - lineW / 2,
      top: top - 20,
      width: lineW,
      height: 40,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _openCurtainId = isOpen ? null : curtain.id;
        }),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isOpen
                    ? [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.5),
                      ]
                    : [
                        Colors.grey[400]!.withOpacity(0.9),
                        Colors.grey[700]!.withOpacity(0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                if (isOpen)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Curtain control panel
  // ---------------------------------------------------------------------------

  Widget _buildCurtainPanel(
    Device curtain,
    double w,
    double h,
    bool isTablet,
    DeviceProvider provider,
  ) {
    final pos = isTablet
        ? kCurtainTabletCoords[curtain.id]
        : kCurtainDesktopCoords[curtain.id];
    if (pos == null) return const SizedBox();

    final left = w * pos.left / 100;
    final curtainTop = h * pos.top / 100;
    // If curtain is in the bottom half, show panel above it; otherwise below
    final showAbove = pos.top > 50;

    const actions = [
      ('open', 'OPEN'),
      ('stop', 'STOP'),
      ('close', 'CLOSE'),
      ('tilt', 'TILT'),
      ('untilt', 'STRAIGHTEN'),
    ];

    const panelHeight = 90.0;

    return Positioned(
      left: (left - 80).clamp(4.0, w - 180),
      top: showAbove ? (curtainTop - panelHeight - 8) : (curtainTop + 8),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                curtain.name,
                style: const TextStyle(fontSize: 8, color: Colors.white54),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: actions
                    .map((a) => GestureDetector(
                          onTap: () {
                            provider.triggerCurtainScene(curtain.id, a.$1);
                            setState(() => _openCurtainId = null);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Text(
                              a.$2,
                              style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Light icon
  // ---------------------------------------------------------------------------

  Widget _buildLightIcon(
    Device light,
    double w,
    double h,
    bool isTablet,
    DeviceProvider provider,
  ) {
    final coords = isTablet && kLightTabletCoords.containsKey(light.id)
        ? kLightTabletCoords[light.id]!
        : Offset(light.x, light.y);

    final left = w * coords.dx / 100;
    final top = h * coords.dy / 100;

    return Positioned(
      left: left - 20,
      top: top - 20,
      child: GestureDetector(
        onTap: () => provider.toggleDevice(light.id),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (light.status) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.90),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.40),
                            blurRadius: 55,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                  Icon(
                    light.lightIcon == LightIcon.lamp
                        ? Icons.emoji_objects_outlined
                        : Icons.lightbulb_outline,
                    size: 20,
                    color: light.status
                        ? const Color(0xFFF8F7F2)
                        : Colors.grey[600],
                  ),
                ],
              ),
            ),
            Text(
              light.room == 'Dev Team'
                  ? light.name.replaceAll('Dev Team – Switch ', '')
                  : light.name,
              style: TextStyle(
                fontSize: 8,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                height: 1.0,
                letterSpacing: -0.3,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DimOverlayPainter extends CustomPainter {
  final List<Device> lights;
  final double w;
  final double h;
  final bool isTablet;

  const _DimOverlayPainter({
    required this.lights,
    required this.w,
    required this.h,
    required this.isTablet,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final onLights = lights.where((l) => l.status).toList();
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // ── Step 1: Dark overlay with holes cut for each ON light ─────────
    canvas.saveLayer(fullRect, Paint());
    // Save layer so blend modes work correctly
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    // Cut "holes" around each ON light using dstOut blend mode
    );


    // Draw dark overlay
    // Save layer so blend modes work correctly
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    // Cut "holes" around each ON light using dstOut blend mode
    );


    // Draw dark overlay

    canvas.drawRect(
      fullRect,
      Paint()..color = const Color(0xFF1A1A1A).withOpacity(0.68),
    );

    for (final light in onLights) {
      final coords = isTablet && kLightTabletCoords.containsKey(light.id)
          ? kLightTabletCoords[light.id]!
          : Offset(light.x, light.y);
      final cx = size.width * coords.dx / 100;
      final cy = size.height * coords.dy / 100;
      final radius = size.width * 0.18;

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = RadialGradient(
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.90),
              Colors.white.withOpacity(0.40),
              Colors.transparent,
            ],
            stops: const [0.0, 0.40, 0.75, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          ),
      );
    }

    canvas.restore();

    // ── Step 2: Warm amber glow on top (screen blend) ─────────────────
    for (final light in onLights) {
      final coords = isTablet && kLightTabletCoords.containsKey(light.id)
          ? kLightTabletCoords[light.id]!
          : Offset(light.x, light.y);
      final cx = size.width * coords.dx / 100;
      final cy = size.height * coords.dy / 100;
      final radius = size.width * 0.16;

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE08A).withOpacity(0.50),
              const Color(0xFFFFAA30).withOpacity(0.22),
              const Color(0xFFFF8800).withOpacity(0.06),
              Colors.transparent,
            ],
            stops: const [0.0, 0.40, 0.70, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_DimOverlayPainter old) =>
      old.lights != lights ||
      old.isTablet != isTablet;
}

