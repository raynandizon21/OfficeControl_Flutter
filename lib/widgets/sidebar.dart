import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/device_provider.dart';
import 'demo_floor_plan.dart';
import 'propeller_fan_icon.dart';

enum ViewType {
  rooms,
  devices,
  curtain,
  aircon,
  light,
  demoFloor1,
  demoFloor2,
  demoFloor3,
}

DemoFloorLevel? demoFloorForViewType(ViewType view) => switch (view) {
      ViewType.demoFloor1 => DemoFloorLevel.first,
      ViewType.demoFloor2 => DemoFloorLevel.second,
      ViewType.demoFloor3 => DemoFloorLevel.third,
      _ => null,
    };

ViewType viewTypeForDemoFloor(DemoFloorLevel floor) => switch (floor) {
      DemoFloorLevel.first => ViewType.demoFloor1,
      DemoFloorLevel.second => ViewType.demoFloor2,
      DemoFloorLevel.third => ViewType.demoFloor3,
    };

Color _surface(Color c, [double opacity = 0.92]) => c.withOpacity(opacity);

/// Matches [DeviceCard] compact card decoration exactly.
enum _CardStyle { light, fan, blind, aircon, neutral }

BoxDecoration _compactCardDecoration({
  required Color accent,
  required bool on,
  required _CardStyle style,
  double radius = 18,
}) {
  if (style == _CardStyle.blind) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _surface(const Color(0xFF1B1C24)),
          Colors.black,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: on
            ? accent.withOpacity(0.22)
            : Colors.white.withOpacity(0.08),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.30),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
        if (on)
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
      ],
    );
  }

  final fixedSidebarTint = style == _CardStyle.aircon;
  final activeTint = on || fixedSidebarTint;
  final baseA = _surface(const Color(0xFF1B1C24));
  final tintAmt = activeTint ? 0.08 : 0.0;
  final bgA = tintAmt == 0.0
      ? baseA
      : Color.lerp(baseA, accent, tintAmt)!;
  const bgB = Colors.black;

  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [bgA, bgB],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: activeTint
          ? accent.withOpacity(0.22)
          : Colors.white.withOpacity(0.08),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.28),
        blurRadius: 16,
        offset: const Offset(0, 10),
      ),
      if (activeTint)
        BoxShadow(
          color: accent.withOpacity(0.14),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
    ],
  );
}

Widget _iconChip({
  required Widget icon,
  required Color accent,
  required bool active,
  double size = 36,
}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: active ? accent.withOpacity(0.18) : Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
    ),
    child: icon,
  );
}

class _SidebarDeviceCard extends StatelessWidget {
  final Color accent;
  final bool active;
  final _CardStyle style;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final VoidCallback? onTap;

  const _SidebarDeviceCard({
    required this.accent,
    required this.active,
    required this.child,
    this.style = _CardStyle.neutral,
    this.radius = 18,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: _compactCardDecoration(
        accent: accent,
        on: active,
        style: style,
        radius: radius,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

extension ViewTypeLabel on ViewType {
  String get label {
    switch (this) {
      case ViewType.rooms:
        return 'Floor Plan';
      case ViewType.devices:
        return 'All Devices';
      case ViewType.curtain:
        return 'Blinds';
      case ViewType.aircon:
        return 'Aircon';
      case ViewType.light:
        return 'Lights';
      case ViewType.demoFloor1:
        return '1st Floor';
      case ViewType.demoFloor2:
        return '2nd Floor';
      case ViewType.demoFloor3:
        return '3rd Floor';
    }
  }

  IconData get icon {
    switch (this) {
      case ViewType.rooms:
        return Icons.dashboard_rounded;
      case ViewType.devices:
        return Icons.devices_rounded;
      case ViewType.curtain:
        return Icons.blinds_rounded;
      case ViewType.aircon:
        return Icons.ac_unit_rounded;
      case ViewType.light:
        return Icons.lightbulb_rounded;
      case ViewType.demoFloor1:
      case ViewType.demoFloor2:
      case ViewType.demoFloor3:
        return Icons.layers_rounded;
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
  bool _refreshing = false;
  bool _demoFloorExpanded = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _demoFloorExpanded = demoFloorForViewType(widget.activeView) != null;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (demoFloorForViewType(widget.activeView) != null) {
      _demoFloorExpanded = true;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String get _timeLabel {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final ampm = _now.hour < 12 ? 'AM' : 'PM';
    return '$h:${_pad(_now.minute)}:${_pad(_now.second)} $ampm';
  }

  String get _dateLabel {
    const wd = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    const mo = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${wd[_now.weekday - 1]}, ${mo[_now.month - 1]} ${_now.day}';
  }

  Future<void> _onRefresh(DeviceProvider provider) async {
    setState(() => _refreshing = true);
    await provider.refreshStates();
    if (mounted) setState(() => _refreshing = false);
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide < 600;

  Widget _buildSidebarContent({
    required DeviceProvider provider,
    required bool connected,
    required bool compact,
  }) {
    final gapMd = compact ? 8.0 : 10.0;
    final gapSm = compact ? 6.0 : 6.0;
    final afterConnected = compact ? 12.0 : 22.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _timeLabel,
          style: TextStyle(
            fontSize: compact ? 32 : 42,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: compact ? -1.0 : -1.5,
            height: 1.0,
            shadows: const [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          _dateLabel,
          style: TextStyle(
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white.withOpacity(0.42),
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
        _ConnectedBar(
          connected: connected,
          refreshing: _refreshing,
          onRefresh: () => _onRefresh(provider),
          compact: compact,
        ),
        SizedBox(height: compact ? 10 : 14),
        const _SectionLabel('NAVIGATION'),
        SizedBox(height: gapMd),
        _NavRow(
          activeView: widget.activeView,
          onNavigate: widget.onNavigate,
          compact: compact,
        ),
        SizedBox(height: compact ? 4 : 6),
        _DemoFloorNavSection(
          activeView: widget.activeView,
          expanded: _demoFloorExpanded,
          onToggle: () => setState(() => _demoFloorExpanded = !_demoFloorExpanded),
          onNavigate: widget.onNavigate,
          compact: compact,
        ),
        if (!compact) ...[
          SizedBox(height: afterConnected),
          _QuickControlSection(provider: provider, compact: compact),
          SizedBox(height: gapSm),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final connected = provider.isConnected;
    final compact = _isMobile(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                kSidebarBlackTop.withOpacity(0.78),
                kSidebarBlackBottom.withOpacity(0.88),
              ],
            ),
            border: Border(
              right: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.07),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: constraints.maxHeight,
                    width: constraints.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 248,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            compact ? 10 : 16,
                            16,
                            compact ? 8 : 12,
                          ),
                          child: _buildSidebarContent(
                            provider: provider,
                            connected: connected,
                            compact: compact,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: Colors.white.withOpacity(0.32),
      ),
    );
  }
}

class _ConnectedBar extends StatelessWidget {
  final bool connected;
  final bool refreshing;
  final VoidCallback onRefresh;
  final bool compact;

  const _ConnectedBar({
    required this.connected,
    required this.refreshing,
    required this.onRefresh,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = connected ? kBtnAccentConnected : kBtnAccentMuted;
    final iconSize = compact ? 30.0 : 36.0;

    return Row(
      children: [
        Expanded(
          child: _SidebarDeviceCard(
            accent: accent,
            active: connected,
            radius: compact ? 14 : 18,
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 8 : 12,
            ),
            child: Row(
              children: [
                _iconChip(
                  icon: Icon(
                    Icons.wifi_rounded,
                    size: compact ? 14 : 16,
                    color: connected ? accent : kBtnAccentMuted,
                  ),
                  accent: accent,
                  active: connected,
                  size: iconSize,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    connected ? 'Connected' : 'Reconnecting…',
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(connected ? 0.9 : 0.5),
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected ? accent : const Color(0xFFEF4444),
                    boxShadow: connected
                        ? [
                            BoxShadow(
                              color: accent.withOpacity(0.55),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _SidebarDeviceCard(
          accent: Colors.white,
          active: false,
          radius: compact ? 14 : 18,
          padding: EdgeInsets.zero,
          onTap: refreshing ? null : onRefresh,
          child: SizedBox(
            width: compact ? 36 : 42,
            height: compact ? 36 : 42,
            child: Center(
              child: refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(0.55),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OneTimeToggleCard extends StatelessWidget {
  final String title;
  final bool on;
  final VoidCallback onTap;
  final List<Color> activeGradient;
  final Color glowColor;
  final Widget icon;

  const _OneTimeToggleCard({
    required this.title,
    required this.on,
    required this.onTap,
    required this.activeGradient,
    required this.glowColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: on
              ? LinearGradient(
                  colors: activeGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: on ? null : const Color(0xFF1A1A22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: on ? Colors.transparent : Colors.white.withOpacity(0.07),
          ),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: glowColor.withOpacity(0.3),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: on
                    ? Colors.white.withOpacity(0.25)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: on ? Colors.white : Colors.white.withOpacity(0.45),
                    ),
                  ),
                  Text(
                    on ? 'Tap to turn off' : 'Tap to turn on',
                    style: TextStyle(
                      fontSize: 10,
                      color: on
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white.withOpacity(0.25),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: on
                    ? Colors.white.withOpacity(0.30)
                    : Colors.white.withOpacity(0.08),
              ),
              child: Align(
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickControlSection extends StatelessWidget {
  final DeviceProvider provider;
  final bool compact;

  const _QuickControlSection({required this.provider, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final lightsOn = provider.anyLightOn;
    final fansOn = provider.anyFanOn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('QUICK CONTROL'),
        SizedBox(height: compact ? 6 : 10),
        _OneTimeToggleCard(
          title: 'All Lights',
          on: lightsOn,
          onTap: () => provider.toggleAllLights(turnOn: !lightsOn),
          activeGradient: const [Color(0xFFFBBF24), Color(0xFFF97316)],
          glowColor: const Color(0xFFFBBF24),
          icon: Icon(
            lightsOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
            color: lightsOn ? Colors.white : Colors.white38,
            size: 17,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        _OneTimeToggleCard(
          title: 'All Fans',
          on: fansOn,
          onTap: () => provider.toggleAllFans(turnOn: !fansOn),
          activeGradient: const [Color(0xFF60A5FA), Color(0xFF3B82F6)],
          glowColor: kBtnAccentFan,
          icon: PropellerFanIcon(
            active: fansOn,
            size: 17,
            color: fansOn ? Colors.white : Colors.white38,
          ),
        ),
      ],
    );
  }
}

class _DemoFloorNavSection extends StatelessWidget {
  final ViewType activeView;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(ViewType) onNavigate;
  final bool compact;

  const _DemoFloorNavSection({
    required this.activeView,
    required this.expanded,
    required this.onToggle,
    required this.onNavigate,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final demoActive = demoFloorForViewType(activeView) != null;
    final radius = compact ? 14.0 : 18.0;

    return Column(
      children: [
        _SidebarDeviceCard(
          accent: Colors.white,
          active: demoActive,
          radius: radius,
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 10 : 12,
          ),
          onTap: () {
            if (!expanded) {
              onToggle();
              if (!demoActive) onNavigate(ViewType.demoFloor1);
            } else {
              onToggle();
            }
          },
          child: Row(
            children: [
              _iconChip(
                icon: Icon(
                  Icons.apartment_rounded,
                  size: compact ? 14 : 16,
                  color: demoActive ? Colors.white : kBtnAccentMuted,
                ),
                accent: Colors.white,
                active: demoActive,
                size: compact ? 30 : 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo Floor Plan',
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: demoActive ? FontWeight.w600 : FontWeight.w500,
                    color: demoActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                  ),
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.white.withOpacity(demoActive ? 0.7 : 0.35),
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(
              left: 12,
              top: compact ? 4 : 6,
            ),
            child: Column(
              children: DemoFloorLevel.values.map((floor) {
                final view = viewTypeForDemoFloor(floor);
                final active = activeView == view;
                return Padding(
                  padding: EdgeInsets.only(bottom: compact ? 4 : 6),
                  child: _SidebarDeviceCard(
                    accent: Colors.white,
                    active: active,
                    radius: compact ? 12 : 14,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: compact ? 8 : 10,
                    ),
                    onTap: () => onNavigate(view),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 4, right: 14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? Colors.white
                                : Colors.white.withOpacity(0.25),
                          ),
                        ),
                        Text(
                          floor.label,
                          style: TextStyle(
                            fontSize: compact ? 11 : 12,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w500,
                            color: active
                                ? Colors.white
                                : Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  final ViewType activeView;
  final void Function(ViewType) onNavigate;
  final bool compact;

  const _NavRow({
    required this.activeView,
    required this.onNavigate,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    const views = [ViewType.rooms, ViewType.devices];
    return Column(
      children: views.map((view) {
        final active = activeView == view;
        return Padding(
          padding: EdgeInsets.only(bottom: compact ? 4 : 6),
          child: _SidebarDeviceCard(
            accent: Colors.white,
            active: active,
            radius: compact ? 14 : 18,
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 10 : 12,
            ),
            onTap: () => onNavigate(view),
            child: Row(
              children: [
                _iconChip(
                  icon: Icon(
                    view.icon,
                    size: compact ? 14 : 16,
                    color: active ? Colors.white : kBtnAccentMuted,
                  ),
                  accent: Colors.white,
                  active: active,
                  size: compact ? 30 : 36,
                ),
                const SizedBox(width: 10),
                Text(
                  view.label,
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
