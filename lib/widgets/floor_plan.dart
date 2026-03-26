import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import 'propeller_fan_icon.dart';

class FloorPlanWidget extends StatefulWidget {
  const FloorPlanWidget({super.key});

  @override
  State<FloorPlanWidget> createState() => _FloorPlanWidgetState();
}

class _FloorPlanWidgetState extends State<FloorPlanWidget> {
  String? _openCurtainId;
  String? _openFanId;
  String? _openAirconId;

  String get _assetPath => 'assets/images/planb.png';

  double get _aspectRatio => 0.65;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final lights = provider.devices.where((d) => d.type == DeviceType.light).toList();
    final fans = provider.devices.where((d) => d.type == DeviceType.fan).toList();
    final aircons = provider.devices.where((d) => d.type == DeviceType.aircon).toList();
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

                      // Light icons
                      for (final light in lights)
                        _buildLightIcon(light, w, h, provider),

                      // Fan icons
                      for (final fan in fans)
                        _buildFanIcon(fan, w, h, provider),

                      // Aircon marker (tap to open ON/OFF box)
                      for (final aircon in aircons)
                        _buildAirconMarker(aircon, w, h),

                      // Dismiss barrier — tap outside control panels to close.
                      // Keep this near the top of stack so panels can overlap other devices.
                      if (_openCurtainId != null || _openFanId != null || _openAirconId != null)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _openCurtainId = null;
                              _openFanId = null;
                              _openAirconId = null;
                            }),
                            behavior: HitTestBehavior.translucent,
                            child: const SizedBox.expand(),
                          ),
                        ),

                      // Control panels on top layer (overlap all devices/icons).
                      if (_openCurtainId != null)
                        _buildCurtainPanel(
                          curtains.firstWhere((c) => c.id == _openCurtainId,
                              orElse: () => curtains.first),
                          w, h, provider,
                        ),
                      if (_openFanId != null)
                        _buildFanPanel(
                          fans.firstWhere((f) => f.id == _openFanId, orElse: () => fans.first),
                          w,
                          h,
                          provider,
                        ),
                      if (_openAirconId != null)
                        _buildAirconPanel(
                          aircons.firstWhere((a) => a.id == _openAirconId, orElse: () => aircons.first),
                          w,
                          h,
                          provider,
                        ),

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

  Widget _buildFanIcon(
    Device fan,
    double w,
    double h,
    DeviceProvider provider,
  ) {
    final coords = kFanTabletCoords[fan.id] ?? Offset(fan.x, fan.y);
    final left = w * coords.dx / 100;
    final top = h * coords.dy / 100;
    final isOpen = _openFanId == fan.id;

    return Positioned(
      left: left - 20,
      top: top - 20,
      child: GestureDetector(
        onTap: () => setState(() => _openFanId = isOpen ? null : fan.id),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PropellerFanIcon(active: fan.status, size: 20),
            Text(
              fan.name,
              style: TextStyle(
                fontSize: 8,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                height: 1.0,
                letterSpacing: -0.2,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 2),
            Builder(
              builder: (context) {
                final speed = fan.status
                    ? (fan.value ?? 1).round().clamp(1, 3)
                    : 0;
                return Text(
                  fan.status ? 'SPEED $speed' : 'OFF',
                  style: TextStyle(
                    fontSize: 7,
                    color: fan.status
                        ? const Color(0xFF93C5FD)
                        : Colors.white54,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFanPanel(
    Device fan,
    double w,
    double h,
    DeviceProvider provider,
  ) {
    final coords = kFanTabletCoords[fan.id] ?? Offset(fan.x, fan.y);
    final left = w * coords.dx / 100;
    final top = h * coords.dy / 100;
    const panelW = 180.0;
    const panelH = 94.0;
    // Keep Dev Team fan controls below icon (same behavior as front desk fan).
    final forceBelow = fan.id == 'f3' || fan.id == 'f4';
    final showAbove = !forceBelow && coords.dy > 50;
    final activeSpeed = (fan.value ?? 0).round().clamp(0, 3);

    return Positioned(
      left: (left - panelW / 2).clamp(4.0, w - panelW - 4),
      top: showAbove ? (top - panelH - 8) : (top + 10),
      width: panelW,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fan.name,
                style: TextStyle(
                  fontSize: 8.5,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _FanPanelBtn(
                      label: 'ON',
                      active: fan.status,
                      onTap: () {
                        provider.toggleDevice(fan.id, forceState: true);
                        setState(() => _openFanId = null);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _FanPanelBtn(
                      label: 'OFF',
                      active: !fan.status,
                      onTap: () {
                        provider.toggleDevice(fan.id, forceState: false);
                        setState(() => _openFanId = null);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final speed in [1, 2, 3]) ...[
                    Expanded(
                      child: _FanSpeedBtn(
                        label: '$speed',
                        active: fan.status && activeSpeed == speed,
                        onTap: () {
                          provider.triggerFanSpeed(fan.id, speed);
                          setState(() => _openFanId = null);
                        },
                      ),
                    ),
                    if (speed != 3) const SizedBox(width: 6),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAirconMarker(Device aircon, double w, double h) {
    final coords = kAirconTabletCoords[aircon.id];
    if (coords == null) return const SizedBox.shrink();
    final left = w * coords.dx / 100;
    final top = h * coords.dy / 100;
    final isOpen = _openAirconId == aircon.id;

    return Positioned(
      left: left - 10,
      top: top - 10,
      child: GestureDetector(
        onTap: () => setState(() => _openAirconId = isOpen ? null : aircon.id),
        child: Transform.rotate(
          angle: 0.95,
          child: Container(
            width: 21,
            height: 21,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[400]!.withOpacity(0.9),
                  Colors.grey[700]!.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAirconPanel(
    Device aircon,
    double w,
    double h,
    DeviceProvider provider,
  ) {
    final coords = kAirconTabletCoords[aircon.id];
    if (coords == null) return const SizedBox.shrink();
    final left = w * coords.dx / 100;
    final top = h * coords.dy / 100;
    const panelW = 150.0;

    return Positioned(
      left: (left - panelW / 2).clamp(4.0, w - panelW - 4),
      top: top + 12,
      width: panelW,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  provider.toggleDevice(aircon.id, forceState: true);
                  setState(() => _openAirconId = null);
                },
                child: _SimpleAirconBtn(label: 'ON', active: aircon.status),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  provider.toggleDevice(aircon.id, forceState: false);
                  setState(() => _openAirconId = null);
                },
                child: _SimpleAirconBtn(label: 'OFF', active: !aircon.status),
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

class _FanPanelBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FanPanelBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF60A5FA);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? activeColor.withOpacity(0.22)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? activeColor.withOpacity(0.65) : Colors.white12,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: active ? activeColor : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FanSpeedBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FanSpeedBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF60A5FA);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 26,
          decoration: BoxDecoration(
            color: active
                ? activeColor.withOpacity(0.20)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? activeColor.withOpacity(0.60) : Colors.white12,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: active ? activeColor : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleAirconBtn extends StatelessWidget {
  final String label;
  final bool active;

  const _SimpleAirconBtn({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    const airconAccent = Color(0xFF67E8F9);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? airconAccent.withOpacity(0.30)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? airconAccent.withOpacity(0.65)
              : airconAccent.withOpacity(0.30),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: active ? airconAccent : Colors.white70,
          ),
        ),
      ),
    );
  }
}

