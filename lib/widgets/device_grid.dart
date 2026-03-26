import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import 'device_card.dart';
import 'propeller_fan_icon.dart';
import 'sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class DeviceGrid extends StatefulWidget {
  final ViewType defaultFilter;

  const DeviceGrid({super.key, this.defaultFilter = ViewType.devices});

  @override
  State<DeviceGrid> createState() => _DeviceGridState();
}

class _DeviceGridState extends State<DeviceGrid> {
  late String _filter;

  static const _filterLabels = {
    'all':     'All Devices',
    'curtain': 'Blinds',
    'aircon':  'Aircon',
    'light':   'Lights',
  };

  @override
  void initState() {
    super.initState();
    _filter = _viewToFilter(widget.defaultFilter);
  }

  @override
  void didUpdateWidget(DeviceGrid old) {
    super.didUpdateWidget(old);
    if (old.defaultFilter != widget.defaultFilter) {
      setState(() => _filter = _viewToFilter(widget.defaultFilter));
    }
  }

  String _viewToFilter(ViewType v) => switch (v) {
    ViewType.devices => 'all',
    ViewType.curtain => 'curtain',
    ViewType.aircon  => 'aircon',
    ViewType.light   => 'light',
    _                => 'all',
  };

  List<_RoomGroup> _buildGroups(List<Device> all) {
    final filtered =
        _filter == 'all' ? all : all.where((d) => d.type.name == _filter).toList();

    // Always group by room (HA dashboard style) for each category
    final Map<String, List<Device>> byRoom = {};
    for (final d in filtered) {
      byRoom.putIfAbsent(d.room.isEmpty ? 'Other' : d.room, () => []).add(d);
    }
    final groups = byRoom.entries
        .map((e) => _RoomGroup(room: e.key, devices: e.value))
        .toList();
    groups.sort((a, b) => (a.room ?? '').compareTo(b.room ?? ''));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<DeviceProvider>();
    final groups    = _buildGroups(provider.devices);
    final showWidgets = _filter == 'all';

    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;
          final hPadding = isSmall ? 16.0 : 28.0;
          final contentW = constraints.maxWidth - (hPadding * 2);

          return Stack(
            children: [
              // ── Background photo ────────────────────────────────────────
              Positioned.fill(
                child: Opacity(
                  opacity: 0.45,
                  child: Image.asset('assets/images/image.png', fit: BoxFit.cover),
                ),
              ),
              // Dark gradient wash for readability (HA-like)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0.35),
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Content ─────────────────────────────────────────────────
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPadding, 28, hPadding, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: title + filter bar + status
                      constraints.maxWidth > 720
                          ? Row(
                              children: [
                                Text(
                                  _filterLabels[_filter] ?? 'Devices',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                          const SizedBox(width: 20),
                          _FilterBar(
                            current: _filter,
                            onChanged: (val) => setState(() => _filter = val),
                          ),
                          const Spacer(),
                                _SyncStatusPill(syncError: provider.syncError),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _filterLabels[_filter] ?? 'Devices',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                      ),
                                    ),
                                    _SyncStatusPill(syncError: provider.syncError),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _FilterBar(
                                  current: _filter,
                                  onChanged: (val) => setState(() => _filter = val),
                                ),
                              ],
                            ),
                      const SizedBox(height: 20),

                      // Device panels
                      Expanded(
                        child: _DashboardLayout(
                          groups:     groups,
                          provider:   provider,
                          availWidth: contentW,
                          showWidgets: showWidgets,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _RoomGroup {
  final String? room;
  final List<Device> devices;
  const _RoomGroup({required this.room, required this.devices});
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard layout — masonry: panels fill shortest column first (no gaps)
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardLayout extends StatelessWidget {
  final List<_RoomGroup> groups;
  final DeviceProvider provider;
  final double availWidth;
  final bool showWidgets;

  const _DashboardLayout({
    required this.groups,
    required this.provider,
    required this.availWidth,
    required this.showWidgets,
  });

  static const _gap       = 14.0;
  static const _minPanelW = 250.0;

  static double _panelHeight(_RoomGroup g, double panelW) {
    const pad          = _SectionPanel._padding;
    const cardH        = _SectionPanel._cardH;
    const curtainCardH = _SectionPanel._curtainCardH;
    const fanCardH     = _SectionPanel._fanCardH;
    const airconCardH  = _SectionPanel._airconCardH;
    const spacing      = _SectionPanel._spacing;

    final innerW = panelW - pad * 2;
    // For lights etc grid, prefer 2 columns.
    const otherCardMinW = 92.0;
    final otherCols = ((innerW + spacing) / (otherCardMinW + spacing))
        .floor()
        .clamp(1, 2);

    final curtains = g.devices.where((d) => d.type == DeviceType.curtain).toList();
    final others   = g.devices.where((d) => d.type != DeviceType.curtain).toList();

    double h = pad * 2;
    if (g.room != null) h += 22 + 10;
    
    // Curtains (Full width)
    for (var i = 0; i < curtains.length; i++) {
      if (i > 0) h += spacing;
      h += curtainCardH;
    }
    
    if (curtains.isNotEmpty && others.isNotEmpty) h += spacing;

    // Others (Grid): per-row height follows tallest card in that row.
    for (var start = 0; start < others.length; start += otherCols) {
      if (start > 0) h += spacing;
      final end = (start + otherCols).clamp(0, others.length);
      final row = others.sublist(start, end);
      var rowH = cardH;
      for (final d in row) {
        if (d.type == DeviceType.aircon) {
          if (airconCardH > rowH) rowH = airconCardH;
        } else if (d.type == DeviceType.fan) {
          if (fanCardH > rowH) rowH = fanCardH;
        }
      }
      h += rowH;
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final w       = availWidth.clamp(100.0, double.infinity);
    final numCols = ((w + _gap) / (_minPanelW + _gap)).floor().clamp(1, 6);
    final panelW  = (w - _gap * (numCols - 1)) / numCols;

    String norm(String? s) => (s ?? '').trim().toLowerCase();

    // Greedy masonry, with fixed column targets for key rooms:
    // Left:  Front door
    // Middle: Lobby, then Office
    // Right: Dev Team
    final colWidgets = List.generate(numCols, (_) => <Widget>[]);
    final colHeights = List.filled(numCols, 0.0);
    final rightCol = (numCols - 1).clamp(0, numCols - 1);

    if (numCols >= 2) {
      final byRoom = <String, _RoomGroup>{
        for (final g in groups) norm(g.room): g,
      };

      final fixed = numCols >= 3
          ? <int, List<String>>{
              0: ['front door'],
              1: ['lobby', 'office'],
              rightCol: ['dev team'],
            }
          : <int, List<String>>{
              0: ['front door', 'lobby', 'office'],
              1: ['dev team'],
            };

      for (final entry in fixed.entries) {
        final col = entry.key;
        if (col >= numCols) continue;
        
        // Ensure One-Time Control is injected in Col 0 for "All Devices" view
        bool otcInjected = false;

        for (final roomKey in entry.value) {
          final g = byRoom.remove(roomKey);
          
          if (g != null) {
            colWidgets[col].add(_SectionPanel(group: g, panelW: panelW, provider: provider));
            colHeights[col] += _panelHeight(g, panelW) + _gap;
          }

          if (showWidgets && roomKey == 'front door' && col == 0 && !otcInjected) {
            const h = 320.0;
            colWidgets[col].add(_OneTimeControlPanel(panelW: panelW, provider: provider));
            colHeights[col] += h + _gap;
            otcInjected = true;
          }
        }
        
        // If "front door" wasn't in this col's fixed list but it's col 0, 
        // and we haven't injected OTC yet, do it now.
        if (showWidgets && col == 0 && !otcInjected) {
          const h = 320.0;
          colWidgets[col].add(_OneTimeControlPanel(panelW: panelW, provider: provider));
          colHeights[col] += h + _gap;
          otcInjected = true;
        }
      }

      final remaining = byRoom.values.toList();
      // Keep prior visual ordering for the rest.
      remaining.sort((a, b) => norm(a.room).compareTo(norm(b.room)));
      for (final g in remaining) {
        final h = _panelHeight(g, panelW);
        var min = 0;
        for (var i = 1; i < numCols; i++) {
          if (colHeights[i] < colHeights[min]) min = i;
        }
        colWidgets[min].add(_SectionPanel(group: g, panelW: panelW, provider: provider));
        colHeights[min] += h + _gap;
      }
    } else {
      // Fallback: greedy masonry when we don't have 3 columns.
      for (final g in groups) {
        final h = _panelHeight(g, panelW);
        var min = 0;
        for (var i = 1; i < numCols; i++) {
          if (colHeights[i] < colHeights[min]) min = i;
        }
        colWidgets[min].add(_SectionPanel(group: g, panelW: panelW, provider: provider));
        colHeights[min] += h + _gap;
      }
    }

    // ListView handles scrolling reliably inside Expanded
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < numCols; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              SizedBox(
                width: panelW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var j = 0; j < colWidgets[i].length; j++) ...[
                      if (j > 0) const SizedBox(height: _gap),
                      colWidgets[i][j],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SyncStatusPill extends StatelessWidget {
  final String? syncError;

  const _SyncStatusPill({required this.syncError});

  @override
  Widget build(BuildContext context) {
    final ok = syncError == null;
    final accent = ok ? const Color(0xFF34D399) : const Color(0xFFEF4444);
    final label = ok ? 'Connected' : 'Reconnecting…';
    final icon = ok ? Icons.cloud_done_rounded : Icons.cloud_off_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ok ? Colors.white70 : accent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.white.withOpacity(ok ? 0.90 : 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Section panel — individual room card (like HA section card)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionPanel extends StatelessWidget {
  final _RoomGroup group;
  final double panelW;
  final DeviceProvider provider;

  const _SectionPanel({
    required this.group,
    required this.panelW,
    required this.provider,
  });

  // Slightly smaller, tighter layout (premium dashboard feel)
  // Follow Lights sizing (small cards)
  static const _cardH        = 96.0;
  static const _airconCardH  = 112.0;
  static const _fanCardH     = 114.0;
  // Taller to fit the larger Blinds action buttons.
  static const _curtainCardH = 170.0;
  static const _spacing      = 12.0;
  // Removed outer "panel card" surface to avoid double cards.
  // DeviceCard already renders as a card; this section is now just layout + header.
  static const _padding      = 0.0;

  static double _cardWidth(double innerW, int cols) =>
      (innerW - _spacing * (cols - 1)) / cols;

  @override
  Widget build(BuildContext context) {
    final innerW   = panelW - _padding * 2;
    // For lights etc grid, prefer 2 columns.
    const otherCardMinW = 92.0;
    final otherCols = ((innerW + _spacing) / (otherCardMinW + _spacing))
        .floor()
        .clamp(1, 2);

    // Split types for layered layout
    final curtains = group.devices
        .where((d) => d.type == DeviceType.curtain)
        .toList();
    final others   = group.devices
        .where((d) => d.type != DeviceType.curtain)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header (no surrounding panel card)
        if (group.room != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                group.room!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // 1st layer: Curtain cards — each full-width
        for (var i = 0; i < curtains.length; i++) ...[
          if (i > 0) const SizedBox(height: _spacing),
          SizedBox(
            width: innerW,
            height: _curtainCardH,
            child: DeviceCard(
              device: curtains[i],
              compact: true,
              provider: provider,
            ),
          ),
        ],

        // Separator between layers
        if (curtains.isNotEmpty && others.isNotEmpty)
          const SizedBox(height: _spacing),

        // 2nd layer: Lights / Aircon etc — grid
        if (others.isNotEmpty)
          SizedBox(
            width: innerW,
            child: Wrap(
              spacing: _spacing,
              runSpacing: _spacing,
              children: [
                for (final d in others)
                  SizedBox(
                    width: _cardWidth(innerW, otherCols),
                    height: d.type == DeviceType.aircon
                        ? _airconCardH
                        : (d.type == DeviceType.fan ? _fanCardH : _cardH),
                    child: DeviceCard(
                      device: d,
                      compact: true,
                      provider: provider,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanded layout — Blinds / Aircon: full-width cards, single scroll
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// One-Time Control Panel (Master controls for Lights/Blinds)
// ─────────────────────────────────────────────────────────────────────────────

class _OneTimeControlPanel extends StatelessWidget {
  final double panelW;
  final DeviceProvider provider;

  const _OneTimeControlPanel({
    required this.panelW,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final allOn = provider.anyLightOn;
    final allFansOn = provider.anyFanOn;
    final fanDevices = provider.devices.where((d) => d.type == DeviceType.fan).toList();
    int? commonFanSpeed;
    if (fanDevices.isNotEmpty) {
      final speeds = fanDevices
          .map((f) => (f.value ?? 1).round().clamp(1, 3))
          .toSet();
      if (speeds.length == 1) {
        commonFanSpeed = speeds.first;
      }
    }
    const accentPurple = Color(0xFFC084FC); // Blinds accent color
    const accentPurpleBorder = Color(0xFFD8B4FE); // Blinds border color
    const accentBlue = Color(0xFF60A5FA); // Fan accent color
    const accentBlueBorder = Color(0xFF93C5FD);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // One-Time Control Title
        const Text(
          'One-Time Control',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // Master Light Toggle
        GestureDetector(
          onTap: () => provider.toggleAllLights(turnOn: !allOn),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: allOn
                  ? const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: allOn ? null : const Color(0xFF1A1A22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: allOn ? Colors.transparent : Colors.white.withOpacity(0.07),
              ),
              boxShadow: allOn
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withOpacity(0.3),
                        blurRadius: 16,
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: allOn
                        ? Colors.white.withOpacity(0.25)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    allOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                    color: allOn ? Colors.white : Colors.white38,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Lights',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: allOn ? Colors.white : Colors.white.withOpacity(0.45),
                        ),
                      ),
                      Text(
                        allOn ? 'Tap to turn off' : 'Tap to turn on',
                        style: TextStyle(
                          fontSize: 10,
                          color: allOn
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
                    color: allOn
                        ? Colors.white.withOpacity(0.30)
                        : Colors.white.withOpacity(0.08),
                  ),
                  child: Align(
                    alignment: allOn ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Master Fan Controls
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 155.0,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xEB1B1C24), Colors.black],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: allFansOn
                  ? accentBlue.withOpacity(0.22)
                  : Colors.white.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
              if (allFansOn)
                BoxShadow(
                  color: accentBlue.withOpacity(0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: allFansOn
                          ? accentBlue.withOpacity(0.18)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PropellerFanIcon(
                      active: allFansOn,
                      size: 18,
                      shapeScale: 0.55,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'All Fans',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: allFansOn
                              ? Colors.white
                              : Colors.white.withOpacity(0.80),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _OneTimeMiniBtn(
                    label: 'On',
                    color: accentBlueBorder,
                    onTap: () => provider.toggleAllFans(turnOn: true),
                  ),
                  const SizedBox(width: 6),
                  _OneTimeMiniBtn(
                    label: 'Off',
                    color: accentBlueBorder,
                    onTap: () => provider.toggleAllFans(turnOn: false),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _OneTimeMiniBtn(
                    label: commonFanSpeed == 1 ? 'Speed 1 *' : 'Speed 1',
                    color: accentBlueBorder,
                    onTap: () => provider.setAllFansSpeed(1),
                  ),
                  const SizedBox(width: 6),
                  _OneTimeMiniBtn(
                    label: commonFanSpeed == 2 ? 'Speed 2 *' : 'Speed 2',
                    color: accentBlueBorder,
                    onTap: () => provider.setAllFansSpeed(2),
                  ),
                  const SizedBox(width: 6),
                  _OneTimeMiniBtn(
                    label: commonFanSpeed == 3 ? 'Speed 3 *' : 'Speed 3',
                    color: accentBlueBorder,
                    onTap: () => provider.setAllFansSpeed(3),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Master Blinds Controls
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 170.0, // Match _curtainCardH
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xEB1B1C24), // Approx _surface(0xFF1B1C24, 0.92)
                Colors.black,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: provider.anyBlindOpen
                  ? accentPurple.withOpacity(0.22)
                  : Colors.white.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
              if (provider.anyBlindOpen)
                BoxShadow(
                  color: accentPurple.withOpacity(0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Icon + Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon container
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: provider.anyBlindOpen
                          ? accentPurple.withOpacity(0.18)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      provider.anyBlindOpen ? Icons.blinds_rounded : Icons.blinds,
                      color: provider.anyBlindOpen
                          ? accentPurple
                          : Colors.white.withOpacity(0.35),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Label in upper-right style
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'All Blinds',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  color: provider.anyBlindOpen
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.80),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _OneTimeMiniBtn(
                        label: 'Open',
                        color: accentPurpleBorder,
                        onTap: () => provider.openAllBlinds(),
                      ),
                      const SizedBox(width: 6),
                      _OneTimeMiniBtn(
                        label: 'Stop',
                        color: accentPurpleBorder,
                        onTap: () => provider.stopAllBlinds(),
                      ),
                      const SizedBox(width: 6),
                      _OneTimeMiniBtn(
                        label: 'Close',
                        color: accentPurpleBorder,
                        onTap: () => provider.closeAllBlinds(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _OneTimeMiniBtn(
                        label: 'Tilt',
                        color: accentPurpleBorder,
                        onTap: () => provider.tiltAllBlinds(),
                      ),
                      const SizedBox(width: 6),
                      _OneTimeMiniBtn(
                        label: 'OPEN TILT',
                        color: accentPurpleBorder,
                        onTap: () => provider.straightenAllBlinds(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OneTimeMiniBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OneTimeMiniBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 36.0,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF232634).withOpacity(0.9),
                    const Color(0xFF1C1F2B).withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.40)),
              ),
              child: Center(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedLayout extends StatelessWidget {
  final List<_RoomGroup> groups;
  final DeviceProvider provider;
  final double availWidth;

  const _ExpandedLayout({
    required this.groups,
    required this.provider,
    required this.availWidth,
  });

  static const _cardH    = 260.0;
  static const _cardMinW = 220.0;
  static const _spacing  = 16.0;

  @override
  Widget build(BuildContext context) {
    final w    = availWidth.clamp(100.0, double.infinity);
    final cols = ((w + _spacing) / (_cardMinW + _spacing)).floor().clamp(1, 99);
    final cardW = (w - _spacing * (cols - 1)) / cols;
    final allDevices = groups.expand((g) => g.devices).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Wrap(
          spacing:    _spacing,
          runSpacing: _spacing,
          children: [
            for (final d in allDevices)
              SizedBox(
                width:  cardW,
                height: _cardH,
                child: DeviceCard(
                  device:   d,
                  compact:  false,
                  provider: provider,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flat layout — All / Blinds / Aircon: single Wrap grid, no room sections
// ─────────────────────────────────────────────────────────────────────────────

class _FlatLayout extends StatelessWidget {
  final List<Device> devices;
  final DeviceProvider provider;
  final double availWidth;
  final bool compact;

  const _FlatLayout({
    required this.devices,
    required this.provider,
    required this.availWidth,
    required this.compact,
  });

  static const _spacing     = 12.0;
  static const _compactMinW = 130.0;
  static const _compactH    = 110.0;
  // Compact Blinds card needs a bit more height for action buttons.
  static const _curtainH    = 160.0;
  static const _expandedMinW = 220.0;
  static const _expandedH    = 260.0;

  @override
  Widget build(BuildContext context) {
    if (availWidth <= 0 || devices.isEmpty) return const SizedBox.shrink();

    final w = availWidth.clamp(100.0, double.infinity);

    if (compact) {
      final cols  = ((w + _spacing) / (_compactMinW + _spacing)).floor().clamp(2, 99);
      final cardW = (w - _spacing * (cols - 1)) / cols;

      return ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Wrap(
            spacing:    _spacing,
            runSpacing: _spacing,
            children: [
              for (final d in devices)
                SizedBox(
                  width:  cardW,
                  height: d.type == DeviceType.curtain ? _curtainH : _compactH,
                  child:  DeviceCard(device: d, compact: true, provider: provider),
                ),
            ],
          ),
        ],
      );
    }

    // Expanded grid: Blinds / Aircon
    final cols  = ((w + _spacing) / (_expandedMinW + _spacing)).floor().clamp(1, 99);
    final cardW = (w - _spacing * (cols - 1)) / cols;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Wrap(
          spacing:    _spacing,
          runSpacing: _spacing,
          children: [
            for (final d in devices)
              SizedBox(
                width:  cardW,
                height: _expandedH,
                child:  DeviceCard(device: d, compact: false, provider: provider),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const {
              'all':     'All',
              'curtain': 'Blinds',
              'aircon':  'Aircon',
              'light':   'Lights',
            }.entries)
              _FilterChip(
                label: entry.value,
                selected: current == entry.key,
                onTap: () => onChanged(entry.key),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.92) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: selected ? const Color(0xFF111827) : Colors.white70,
          ),
        ),
      ),
    );
  }
}
