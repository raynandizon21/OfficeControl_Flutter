import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../light_icons.dart';
import '../constants.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import 'propeller_fan_icon.dart';

class FloorPlanWidget extends StatefulWidget {
  const FloorPlanWidget({super.key});

  static const kMobileBackdrop = Color(0xFF1D164F);

  /// Same gradient as plan_floor_mobile1 image edges (blue L/R, purple mid T/B).
  static const mobileBackdrop = MobileBackdrop();

  static Widget mobileBackground({Widget? child}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const MobileBackdrop(),
        if (child != null) Positioned.fill(child: child),
      ],
    );
  }

  @override
  State<FloorPlanWidget> createState() => _FloorPlanWidgetState();
}

class _FloorPlanWidgetState extends State<FloorPlanWidget> {
  String? _openCurtainId;
  String? _openFanId;
  String? _openAirconId;

  /// Desktop-only: drag icons to tune layout, then copy coords into constants.dart.
  bool _desktopLayoutEdit = false;
  Map<String, Offset> _desktopDragOverrides = {};
  Map<String, double> _desktopRotationOverrides = {};
  String? _selectedEditId;
  final TextEditingController _rotationDegController = TextEditingController();

  static const _airconDefaultRotationDeg = 54.4; // was hardcoded 0.95 rad
  static const _airconMarkerW = 27.0;
  static const _airconMarkerH = 14.0;

  @override
  void dispose() {
    _rotationDegController.dispose();
    super.dispose();
  }

  List<BoxShadow> get _iotActiveGlow => [
        BoxShadow(
          color: kIotGlowBlue.withOpacity(0.55),
          blurRadius: 18,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: kIotGlowPurple.withOpacity(0.42),
          blurRadius: 32,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: kIotOn.withOpacity(0.38),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  static const _lineDarkGrey = Color(0xFF52525B);
  static const _lineDarkGreyDeep = Color(0xFF3F3F46);

  static const _desktopNativeW = 1329.0; // plan_floor.png
  static const _desktopNativeH = 784.0;
  static const _desktopAspect = _desktopNativeW / _desktopNativeH;
  static const _mobileNativeW = 1040.0; // plan_floor_mobile1_1080_2400.png
  static const _mobileNativeH = 1860.0;
  static const _tabletAspect = _mobileNativeW / _mobileNativeH;

  bool _isMobileLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // shortestSide works for portrait AND landscape phones on web/mobile.
    return size.shortestSide < 600;
  }

  String _assetPath(bool isMobile) =>
      isMobile ? 'assets/images/plan_floor_mobile1_1080_2400.png' : 'assets/images/plan_floor.png';

  double _aspectRatio(bool isMobile) => isMobile ? _tabletAspect : _desktopAspect;

  Map<String, CurtainPos> _curtainCoords(bool isMobile) =>
      isMobile ? kCurtainTabletCoords : kCurtainDesktopCoords;

  /// Fill viewport (no letterboxing), crop edges if needed.
  ({double w, double h, double x, double y}) _coverRect(
    double availW,
    double availH,
    double aspectRatio,
  ) {
    // True cover: scale until both dimensions >= viewport, then center-crop.
    final hIfFitWidth = availW / aspectRatio;
    if (hIfFitWidth >= availH) {
      return (w: availW, h: hIfFitWidth, x: 0.0, y: (availH - hIfFitWidth) / 2);
    }
    final w = availH * aspectRatio;
    return (w: w, h: availH, x: (availW - w) / 2, y: 0.0);
  }

  static const _desktopGradient = BoxDecoration(
    gradient: kDesktopBackgroundGradient,
  );

  Offset _lightCoords(Device light, bool isMobile) {
    if (isMobile && kLightTabletCoords.containsKey(light.id)) {
      return kLightTabletCoords[light.id]!;
    }
    return Offset(light.x, light.y);
  }

  Offset _fanCoords(Device fan, bool isMobile) {
    if (isMobile) {
      return kFanTabletCoords[fan.id] ?? Offset(fan.x, fan.y);
    }
    return kFanDesktopCoords[fan.id] ?? Offset(fan.x, fan.y);
  }

  Offset? _airconCoords(Device aircon, bool isMobile) {
    if (isMobile) return kAirconTabletCoords[aircon.id];
    return Offset(aircon.x, aircon.y);
  }

  Offset _resolvedMarkerCoords(String id, Offset base, bool isMobile) {
    if (!isMobile && (_desktopLayoutEdit || _desktopDragOverrides.containsKey(id))) {
      return _desktopDragOverrides[id] ?? base;
    }
    return base;
  }

  double _desktopRotationDeg(
    String id,
    bool isMobile, {
    double defaultDeg = 0,
  }) {
    if (isMobile) return defaultDeg;
    if (_desktopLayoutEdit || _desktopRotationOverrides.containsKey(id)) {
      return _desktopRotationOverrides[id] ?? kDesktopMarkerRotation[id] ?? defaultDeg;
    }
    return kDesktopMarkerRotation[id] ?? defaultDeg;
  }

  void _onDesktopRotateUpdate(String id, double deltaDeg, {double defaultDeg = 0}) {
    setState(() {
      final cur = _desktopRotationDeg(id, false, defaultDeg: defaultDeg);
      _desktopRotationOverrides[id] = cur + deltaDeg;
      if (_selectedEditId == id) {
        _rotationDegController.text = _fmtDeg(_desktopRotationOverrides[id]!);
      }
    });
  }

  static String _fmtDeg(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  void _selectEditId(String id) {
    setState(() {
      _selectedEditId = id;
      _rotationDegController.text = _fmtDeg(
        _desktopRotationDeg(id, false, defaultDeg: _editDefaultRotationDeg(id)),
      );
    });
  }

  void _applyRotationInput() {
    final id = _selectedEditId;
    if (id == null) return;
    final raw = _rotationDegController.text.trim().replaceAll('°', '');
    final parsed = double.tryParse(raw);
    if (parsed == null) return;
    setState(() {
      _desktopRotationOverrides[id] = parsed;
      _rotationDegController.text = _fmtDeg(parsed);
    });
  }

  double _markerRotationDeg(
    String id,
    bool isMobile, {
    double defaultDeg = 0,
  }) {
    if (isMobile) {
      return kMobileMarkerRotation[id] ?? defaultDeg;
    }
    return _desktopRotationDeg(id, isMobile, defaultDeg: defaultDeg);
  }

  CurtainPos _resolvedCurtainPos(Device curtain, bool isMobile) {
    final base = _curtainCoords(isMobile)[curtain.id]!;
    if (!isMobile && (_desktopLayoutEdit || _desktopDragOverrides.containsKey(curtain.id))) {
      final o = _desktopDragOverrides[curtain.id] ?? Offset(base.left, base.top);
      return CurtainPos(left: o.dx, top: o.dy, width: base.width);
    }
    return base;
  }

  void _seedDesktopDragOverrides({
    required List<Device> lights,
    required List<Device> fans,
    required List<Device> aircons,
    required List<Device> curtains,
  }) {
    _desktopDragOverrides = {};
    for (final light in lights) {
      _desktopDragOverrides[light.id] = _lightCoords(light, false);
    }
    for (final fan in fans) {
      _desktopDragOverrides[fan.id] = _fanCoords(fan, false);
    }
    for (final aircon in aircons) {
      final coords = _airconCoords(aircon, false);
      if (coords != null) {
        _desktopDragOverrides[aircon.id] = coords;
      }
    }
    for (final curtain in curtains) {
      final pos = kCurtainDesktopCoords[curtain.id]!;
      _desktopDragOverrides[curtain.id] = Offset(pos.left, pos.top);
    }
    _desktopRotationOverrides = {};
    for (final light in lights) {
      _desktopRotationOverrides[light.id] =
          kDesktopMarkerRotation[light.id] ?? 0;
    }
    for (final fan in fans) {
      _desktopRotationOverrides[fan.id] =
          kDesktopMarkerRotation[fan.id] ?? 0;
    }
    for (final aircon in aircons) {
      _desktopRotationOverrides[aircon.id] =
          kDesktopMarkerRotation[aircon.id] ?? _airconDefaultRotationDeg;
    }
    for (final curtain in curtains) {
      _desktopRotationOverrides[curtain.id] =
          kDesktopMarkerRotation[curtain.id] ?? 0;
    }
  }

  void _onDesktopDragUpdate(String id, double w, double h, DragUpdateDetails details) {
    setState(() {
      final cur = _desktopDragOverrides[id]!;
      final px = w * cur.dx / 100 + details.delta.dx;
      final py = h * cur.dy / 100 + details.delta.dy;
      _desktopDragOverrides[id] = Offset(
        (px / w * 100).clamp(0.0, 100.0),
        (py / h * 100).clamp(0.0, 100.0),
      );
    });
  }

  static String _fmtPct(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  String _exportDesktopLayout({
    required List<Device> lights,
    required List<Device> fans,
    required List<Device> aircons,
    required List<Device> curtains,
  }) {
    final buf = StringBuffer('// Desktop layout — paste into constants.dart\n\n');
    buf.writeln('// Lights (update x, y in kInitialDevices):');
    for (final light in lights) {
      final c = _desktopDragOverrides[light.id]!;
      buf.writeln(
        '// ${light.name} (${light.id}): x: ${_fmtPct(c.dx)}, y: ${_fmtPct(c.dy)}',
      );
    }
    buf.writeln('\nconst Map<String, Offset> kFanDesktopCoords = {');
    for (final fan in fans) {
      final c = _desktopDragOverrides[fan.id]!;
      buf.writeln(
        "  '${fan.id}': Offset(${_fmtPct(c.dx)}, ${_fmtPct(c.dy)}), // ${fan.name}",
      );
    }
    buf.writeln('};');
    buf.writeln('\n// Aircons (update x, y in kInitialDevices):');
    for (final aircon in aircons) {
      final c = _desktopDragOverrides[aircon.id]!;
      buf.writeln(
        '// ${aircon.name} (${aircon.id}): x: ${_fmtPct(c.dx)}, y: ${_fmtPct(c.dy)}',
      );
    }
    buf.writeln('\nconst Map<String, CurtainPos> kCurtainDesktopCoords = {');
    for (final curtain in curtains) {
      final o = _desktopDragOverrides[curtain.id]!;
      final width = kCurtainDesktopCoords[curtain.id]!.width;
      buf.writeln(
        "  '${curtain.id}': CurtainPos(left: ${_fmtPct(o.dx)}, top: ${_fmtPct(o.dy)}, width: $width), // ${curtain.name}",
      );
    }
    buf.writeln('};');
    buf.writeln('\nconst Map<String, double> kDesktopMarkerRotation = {');
    for (final light in lights) {
      final r = _desktopRotationDeg(light.id, false);
      buf.writeln("  '${light.id}': ${_fmtPct(r)}, // ${light.name}");
    }
    for (final fan in fans) {
      final r = _desktopRotationDeg(fan.id, false);
      buf.writeln("  '${fan.id}': ${_fmtPct(r)}, // ${fan.name}");
    }
    for (final aircon in aircons) {
      final r = _desktopRotationDeg(aircon.id, false, defaultDeg: _airconDefaultRotationDeg);
      buf.writeln("  '${aircon.id}': ${_fmtPct(r)}, // ${aircon.name}");
    }
    for (final curtain in curtains) {
      final r = _desktopRotationDeg(curtain.id, false);
      buf.writeln("  '${curtain.id}': ${_fmtPct(r)}, // ${curtain.name}");
    }
    buf.writeln('};');
    return buf.toString();
  }

  Widget _buildDesktopLayoutPanel({
    required List<Device> lights,
    required List<Device> fans,
    required List<Device> aircons,
    required List<Device> curtains,
  }) {
    final export = _exportDesktopLayout(
      lights: lights,
      fans: fans,
      aircons: aircons,
      curtains: curtains,
    );

    return Positioned(
      top: 12,
      right: 12,
      width: 280,
      child: Material(
        color: Colors.black.withOpacity(0.82),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade400.withOpacity(0.6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Desktop Layout Edit',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Drag to move · tap icon · type exact degrees below.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 9.5,
                ),
              ),
              if (_selectedEditId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Selected: $_selectedEditId',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rotationDegController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Rotation',
                          labelStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                          ),
                          suffixText: '°',
                          suffixStyle: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w700,
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.amber.shade400),
                          ),
                        ),
                        onSubmitted: (_) => _applyRotationInput(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: _applyRotationInput,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Set', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                Slider(
                  value: _desktopRotationDeg(
                    _selectedEditId!,
                    false,
                    defaultDeg: _editDefaultRotationDeg(_selectedEditId!),
                  ).clamp(-360.0, 360.0),
                  min: -360,
                  max: 360,
                  activeColor: Colors.amber,
                  inactiveColor: Colors.white24,
                  label: '${_fmtDeg(_desktopRotationDeg(_selectedEditId!, false, defaultDeg: _editDefaultRotationDeg(_selectedEditId!)))}°',
                  onChanged: (v) {
                    setState(() {
                      _desktopRotationOverrides[_selectedEditId!] = v;
                      _rotationDegController.text = _fmtDeg(v);
                    });
                  },
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Tap an icon to set rotation by value.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: SelectableText(
                    export,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: export));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Desktop coords copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber,
                        side: BorderSide(color: Colors.amber.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Copy', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _desktopLayoutEdit = false;
                        _selectedEditId = null;
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.25)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Done', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _editDefaultRotationDeg(String id) {
    if (id.startsWith('ac')) return _airconDefaultRotationDeg;
    return 0;
  }

  Widget _buildRotateToolbar(
    String id,
    double rotDeg,
    double defaultRotationDeg,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) => _onDesktopRotateUpdate(
        id,
        d.delta.dx * 0.5,
        defaultDeg: defaultRotationDeg,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.orange.shade800.withOpacity(0.95),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _rotateTapBtn(Icons.rotate_left, -15, id, defaultRotationDeg),
            GestureDetector(
              onTap: () => _selectEditId(id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  '${rotDeg.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white54,
                  ),
                ),
              ),
            ),
            _rotateTapBtn(Icons.rotate_right, 15, id, defaultRotationDeg),
          ],
        ),
      ),
    );
  }

  Widget _rotateTapBtn(
    IconData icon,
    double delta,
    String id,
    double defaultRotationDeg,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDesktopRotateUpdate(
          id,
          delta,
          defaultDeg: defaultRotationDeg,
        ),
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget _desktopDragHandle({
    required String id,
    required bool isMobile,
    required double w,
    required double h,
    required Widget child,
    double defaultRotationDeg = 0,
  }) {
    final rotDeg = _markerRotationDeg(
      id,
      isMobile,
      defaultDeg: defaultRotationDeg,
    );
    final rotRad = rotDeg * math.pi / 180;
    final rotated = rotDeg == 0 ? child : Transform.rotate(angle: rotRad, child: child);

    if (isMobile || !_desktopLayoutEdit) return rotated;

    final isSelected = _selectedEditId == id;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRotateToolbar(id, rotDeg, defaultRotationDeg),
        const SizedBox(height: 2),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _selectEditId(id),
          onPanUpdate: (d) => _onDesktopDragUpdate(id, w, h, d),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.cyanAccent : Colors.amber.shade400,
                width: isSelected ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: rotated,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final isMobile = _isMobileLayout(context);
    if (isMobile && _desktopLayoutEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _desktopLayoutEdit = false;
            _selectedEditId = null;
          });
        }
      });
    }
    final curtainCoords = _curtainCoords(isMobile);
    final aspectRatio = _aspectRatio(isMobile);

    final lights = provider.devices.where((d) => d.type == DeviceType.light).toList();
    final fans = provider.devices.where((d) => d.type == DeviceType.fan).toList();
    final aircons = provider.devices.where((d) => d.type == DeviceType.aircon).toList();
    final curtains = provider.devices
        .where((d) => d.type == DeviceType.curtain && curtainCoords.containsKey(d.id))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        final availH = constraints.maxHeight;
        if (availW <= 0 || availH <= 0) {
          return const SizedBox.shrink();
        }

        if (isMobile) {
          final rect = _coverRect(availW, availH, _tabletAspect);
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: rect.x,
                top: rect.y,
                width: rect.w,
                height: rect.h,
                child: Image.asset(
                  _assetPath(true),
                  fit: BoxFit.cover,
                  width: rect.w,
                  height: rect.h,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Image load failed:\n$error',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: rect.x,
                top: rect.y,
                width: rect.w,
                height: rect.h,
                child: _buildOverlayStack(
                  w: rect.w,
                  h: rect.h,
                  isMobile: true,
                  lights: lights,
                  fans: fans,
                  aircons: aircons,
                  curtains: curtains,
                  provider: provider,
                ),
              ),
            ],
          );
        }

        final rect = _coverRect(availW, availH, aspectRatio);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: _desktopLayoutEdit ? Clip.none : Clip.hardEdge,
          children: [
            const Positioned.fill(child: DecoratedBox(decoration: _desktopGradient)),
            Positioned(
              left: rect.x,
              top: rect.y,
              width: rect.w,
              height: rect.h,
              child: Image.asset(
                _assetPath(false),
                fit: BoxFit.cover,
                width: rect.w,
                height: rect.h,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
            Positioned(
              left: rect.x,
              top: rect.y,
              width: rect.w,
              height: rect.h,
              child: _buildOverlayStack(
                w: rect.w,
                h: rect.h,
                isMobile: false,
                lights: lights,
                fans: fans,
                aircons: aircons,
                curtains: curtains,
                provider: provider,
              ),
            ),
            // Desktop layout edit — hidden for now; uncomment to tune icon positions.
            // if (_desktopLayoutEdit)
            //   _buildDesktopLayoutPanel(
            //     lights: lights,
            //     fans: fans,
            //     aircons: aircons,
            //     curtains: curtains,
            //   ),
            // Positioned(
            //   right: 16,
            //   bottom: 16,
            //   child: FloatingActionButton.extended(
            //     heroTag: 'desktop_layout_edit',
            //     backgroundColor: _desktopLayoutEdit ? Colors.amber.shade700 : const Color(0xFF4C1D95),
            //     foregroundColor: Colors.white,
            //     onPressed: () {
            //       setState(() {
            //         if (_desktopLayoutEdit) {
            //           _desktopLayoutEdit = false;
            //           _selectedEditId = null;
            //         } else {
            //           _seedDesktopDragOverrides(
            //             lights: lights,
            //             fans: fans,
            //             aircons: aircons,
            //             curtains: curtains,
            //           );
            //           _desktopLayoutEdit = true;
            //           _selectedEditId = null;
            //           _openCurtainId = null;
            //           _openFanId = null;
            //           _openAirconId = null;
            //         }
            //       });
            //     },
            //     icon: Icon(_desktopLayoutEdit ? Icons.check : Icons.open_with),
            //     label: Text(
            //       _desktopLayoutEdit ? 'Done Editing' : 'Edit Icons',
            //       style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            //     ),
            //   ),
            // ),
          ],
        );
      },
    );
  }

  Widget _buildOverlayStack({
    required double w,
    required double h,
    required bool isMobile,
    required List<Device> lights,
    required List<Device> fans,
    required List<Device> aircons,
    required List<Device> curtains,
    required DeviceProvider provider,
  }) {
    return Stack(
      clipBehavior: _desktopLayoutEdit && !isMobile ? Clip.none : Clip.hardEdge,
      children: [
        for (final curtain in curtains)
          _buildCurtainLine(curtain, w, h, isMobile),
        for (final light in lights)
          _buildLightIcon(light, w, h, provider, isMobile),
        for (final fan in fans)
          _buildFanIcon(fan, w, h, provider, isMobile),
        for (final aircon in aircons)
          _buildAirconMarker(aircon, w, h, isMobile),
        if (_openCurtainId != null || _openFanId != null || _openAirconId != null)
          if (!_desktopLayoutEdit)
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
        if (_openCurtainId != null && !_desktopLayoutEdit)
          _buildCurtainPanel(
            curtains.firstWhere((c) => c.id == _openCurtainId,
                orElse: () => curtains.first),
            w,
            h,
            provider,
            isMobile,
          ),
        if (_openFanId != null && !_desktopLayoutEdit)
          _buildFanPanel(
            fans.firstWhere((f) => f.id == _openFanId, orElse: () => fans.first),
            w,
            h,
            provider,
            isMobile,
          ),
        if (_openAirconId != null && !_desktopLayoutEdit)
          _buildAirconPanel(
            aircons.firstWhere((a) => a.id == _openAirconId, orElse: () => aircons.first),
            w,
            h,
            provider,
            isMobile,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Curtain line
  // ---------------------------------------------------------------------------

  Widget _buildCurtainLine(Device curtain, double w, double h, bool isMobile) {
    final pos = _resolvedCurtainPos(curtain, isMobile);

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
      child: _desktopDragHandle(
        id: curtain.id,
        isMobile: isMobile,
        w: w,
        h: h,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _desktopLayoutEdit && !isMobile
              ? null
              : () => setState(() {
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
                        _lineDarkGrey,
                        _lineDarkGreyDeep,
                      ]
                    : [
                        _lineDarkGreyDeep,
                        const Color(0xFF27272A),
                      ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                if (isOpen)
                  BoxShadow(
                    color: _lineDarkGrey.withOpacity(0.35),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
              ],
            ),
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
    bool isMobile,
  ) {
    final pos = _resolvedCurtainPos(curtain, isMobile);

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
    bool isMobile,
  ) {
    final coords = _resolvedMarkerCoords(
      light.id,
      _lightCoords(light, isMobile),
      isMobile,
    );

    final left = w * coords.dx / 100;
    final top = h * coords.dy / 100;

    final iconBody = Column(
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
                    boxShadow: _iotActiveGlow,
                  ),
                ),
              ],
              Icon(
                lightMarkerIcon(light.lightIcon, on: light.status),
                size: 20,
                color: light.status ? kIotOn : kIotOff,
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
    );

    return Positioned(
      left: left - 20,
      top: top - 20,
      child: _desktopDragHandle(
        id: light.id,
        isMobile: isMobile,
        w: w,
        h: h,
        child: GestureDetector(
          onTap: _desktopLayoutEdit && !isMobile
              ? null
              : () => provider.toggleDevice(light.id),
          child: iconBody,
        ),
      ),
    );
  }

  Widget _buildFanIcon(
    Device fan,
    double w,
    double h,
    DeviceProvider provider,
    bool isMobile,
  ) {
    final coords = _resolvedMarkerCoords(
      fan.id,
      _fanCoords(fan, isMobile),
      isMobile,
    );
    final left = w * coords.dx / 100;
    final top = h * coords.dy / 100;
    final isOpen = _openFanId == fan.id;

    final iconBody = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PropellerFanIcon(
          active: fan.status,
          size: 20,
          color: fan.status ? kIotOn : kIotOff,
        ),
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
                color: fan.status ? kIotOn : kIotOff,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            );
          },
        ),
      ],
    );

    return Positioned(
      left: left - 20,
      top: top - 20,
      child: _desktopDragHandle(
        id: fan.id,
        isMobile: isMobile,
        w: w,
        h: h,
        child: GestureDetector(
          onTap: _desktopLayoutEdit && !isMobile
              ? null
              : () => setState(() => _openFanId = isOpen ? null : fan.id),
          child: iconBody,
        ),
      ),
    );
  }

  Widget _buildFanPanel(
    Device fan,
    double w,
    double h,
    DeviceProvider provider,
    bool isMobile,
  ) {
    final coords = _resolvedMarkerCoords(
      fan.id,
      _fanCoords(fan, isMobile),
      isMobile,
    );
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

  Widget _buildAirconMarker(Device aircon, double w, double h, bool isMobile) {
    final base = _airconCoords(aircon, isMobile);
    if (base == null) return const SizedBox.shrink();
    final coords = _resolvedMarkerCoords(aircon.id, base, isMobile);
    final left = w * coords.dx / 100;
    final top = h * coords.dy / 100;
    final isOpen = _openAirconId == aircon.id;

    final marker = Container(
      width: _airconMarkerW,
      height: _airconMarkerH,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isOpen
              ? [
                  _lineDarkGrey,
                  _lineDarkGreyDeep,
                ]
              : [
                  _lineDarkGreyDeep,
                  const Color(0xFF27272A),
                ],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          if (isOpen)
            BoxShadow(
              color: _lineDarkGrey.withOpacity(0.35),
              blurRadius: 6,
              spreadRadius: 1,
            ),
        ],
      ),
    );

    return Positioned(
      left: left - _airconMarkerW / 2,
      top: top - _airconMarkerH / 2,
      child: _desktopDragHandle(
        id: aircon.id,
        isMobile: isMobile,
        w: w,
        h: h,
        defaultRotationDeg: _airconDefaultRotationDeg,
        child: GestureDetector(
          onTap: _desktopLayoutEdit && !isMobile
              ? null
              : () => setState(() => _openAirconId = isOpen ? null : aircon.id),
          child: marker,
        ),
      ),
    );
  }

  Widget _buildAirconPanel(
    Device aircon,
    double w,
    double h,
    DeviceProvider provider,
    bool isMobile,
  ) {
    final base = _airconCoords(aircon, isMobile);
    if (base == null) return const SizedBox.shrink();
    final coords = _resolvedMarkerCoords(aircon.id, base, isMobile);
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

class MobileBackdrop extends StatelessWidget {
  const MobileBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1D164F), Color(0xFF1E1750)],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF03275F), Color(0x001D164F), Color(0xFF2F0943)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

