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

  String get _assetPath => 'assets/images/planb.png';

  double get _aspectRatio => 0.65;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final lights = provider.devices.where((d) => d.type == DeviceType.light).toList();
    final curtains = provider.devices
        .where((d) => d.type == DeviceType.curtain && kCurtainTabletCoords.containsKey(d.id))
        .toList();

    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              return FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: w,
                  height: h,
                  child: Stack(
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
                        _buildCurtainLine(curtain, w, h),

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
                          w, h, provider,
                        ),


                      // Light icons
                      for (final light in lights)
                        _buildLightIcon(light, w, h, provider),


                    ],
                  ),
                ),
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

  Widget _buildCurtainLine(Device curtain, double w, double h) {
    final pos = kCurtainTabletCoords[curtain.id];
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
    DeviceProvider provider,
  ) {
    final pos = kCurtainTabletCoords[curtain.id];
    if (pos == null) return const SizedBox();

    final left = w * pos.left / 100;
    final curtainTop = h * pos.top / 100;
    // If curtain is in the bottom half, show panel above it; otherwise below
    final showAbove = pos.top > 50;

    const panelW = 200.0;
    const btnH = 32.0;
    const panelHeight = 114.0;
    const accent = Color(0xFFD8B4FE); // Blinds border/text accent (All Devices)

    return Positioned(
      left: (left - panelW / 2).clamp(4.0, w - panelW - 4),
      top: showAbove ? (curtainTop - panelHeight - 8) : (curtainTop + 8),
      width: panelW,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                curtain.name,
                style: TextStyle(
                  fontSize: 8.5,
                  color: Colors.white.withOpacity(0.60),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              // Action buttons — match All Devices: 2 rows
              // Row 1: Open / Stop / Close
              // Row 2: Tilt / Straighten
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (curtain.sceneCurtainOpen != null)
                        Expanded(
                          child: SizedBox(
                            height: btnH,
                            child: _CurtainPanelBtn(
                              label: 'Open',
                              accent: accent,
                              onTap: () {
                                provider.triggerCurtainScene(curtain.id, 'open');
                                setState(() => _openCurtainId = null);
                              },
                            ),
                          ),
                        ),
                      if (curtain.sceneCurtainOpen != null) const SizedBox(width: 5),
                      if (curtain.sceneCurtainStop != null)
                        Expanded(
                          child: SizedBox(
                            height: btnH,
                            child: _CurtainPanelBtn(
                              label: 'Stop',
                              accent: accent,
                              onTap: () {
                                provider.triggerCurtainScene(curtain.id, 'stop');
                                setState(() => _openCurtainId = null);
                              },
                            ),
                          ),
                        ),
                      if (curtain.sceneCurtainStop != null) const SizedBox(width: 5),
                      if (curtain.sceneCurtainClose != null)
                        Expanded(
                          child: SizedBox(
                            height: btnH,
                            child: _CurtainPanelBtn(
                              label: 'Close',
                              accent: accent,
                              onTap: () {
                                provider.triggerCurtainScene(curtain.id, 'close');
                                setState(() => _openCurtainId = null);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (curtain.sceneCurtainTilt != null)
                        Expanded(
                          child: SizedBox(
                            height: btnH,
                            child: _CurtainPanelBtn(
                              label: 'Tilt',
                              accent: accent,
                              onTap: () {
                                provider.triggerCurtainScene(curtain.id, 'tilt');
                                setState(() => _openCurtainId = null);
                              },
                            ),
                          ),
                        ),
                      if (curtain.sceneCurtainTilt != null) const SizedBox(width: 5),
                      if (curtain.sceneCurtainUntilt != null)
                        Expanded(
                          child: SizedBox(
                            height: btnH,
                            child: _CurtainPanelBtn(
                              label: 'OPEN TILT',
                              accent: accent,
                              onTap: () {
                                provider.triggerCurtainScene(curtain.id, 'untilt');
                                setState(() => _openCurtainId = null);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
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
    DeviceProvider provider,
  ) {
    final coords = kLightTabletCoords.containsKey(light.id)
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

class _CurtainPanelBtn extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _CurtainPanelBtn({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF232634).withOpacity(0.90),
                const Color(0xFF1C1F2B).withOpacity(0.90),
              ],
            ),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accent.withOpacity(0.40)),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

