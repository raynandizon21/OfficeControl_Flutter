import 'package:flutter/material.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final bool compact;
  final DeviceProvider provider;

  static const double _kCardSurfaceOpacity = 0.78;

  static Color _surface(Color c, [double factor = _kCardSurfaceOpacity]) {
    final a = (c.alpha * factor).round().clamp(0, 255);
    return c.withAlpha(a);
  }

  const DeviceCard({
    super.key,
    required this.device,
    required this.compact,
    required this.provider,
  });

  String get _displayName {
    var name = device.name.trim();
    if (device.type != DeviceType.light) return name;

    final room = device.room.trim();
    if (room.isEmpty) return name;

    final re = RegExp(
      '^\\s*${RegExp.escape(room)}\\s*[-–—]\\s*',
      caseSensitive: false,
    );
    name = name.replaceFirst(re, '');
    return name.isEmpty ? device.name.trim() : name;
  }

  IconData get _icon {
    if (device.type == DeviceType.light && device.lightIcon == LightIcon.lamp) {
      return device.isOn ? Icons.emoji_objects : Icons.emoji_objects_outlined;
    }
    switch (device.type) {
      case DeviceType.light:
        return device.isOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline;
      case DeviceType.curtain:
        return device.isOn ? Icons.blinds_rounded : Icons.blinds;
      case DeviceType.aircon:
        return Icons.ac_unit_rounded;
    }
  }

  void _handleCompactTap() {
    if (device.type == DeviceType.curtain) {
      if (device.hasCurtainScenes) {
        provider.triggerCurtainScene(device.id, device.isOn ? 'close' : 'open');
      } else {
        provider.setCurtainPreset(device.id, device.isOn ? 0 : 50);
      }
    } else {
      provider.toggleDevice(device.id);
    }
  }

  // Per-type color palette
  _TypeTheme get _theme {
    // Colors matched to sidebar ViewType.iconColor
    switch (device.type) {
      case DeviceType.light:
        return const _TypeTheme(
          activeCard:   Color(0xFFFBBF24),  // amber  — sidebar Lights color
          activeBorder: Color(0xFFFDE68A),
          iconBg:       Color(0xFFFDE68A),
          badgeBg:      Color(0xFFFBBF24),
          statusText:   Color(0xFFFEF3C7),
          badgeText:    Color(0xFFFEF9C3),
        );
      case DeviceType.curtain:
        return const _TypeTheme(
          activeCard:   Color(0xFFC084FC),  // light violet — sidebar Blinds color
          activeBorder: Color(0xFFD8B4FE),
          iconBg:       Color(0xFFD8B4FE),
          badgeBg:      Color(0xFFC084FC),
          statusText:   Color(0xFFEDE9FE),
          badgeText:    Color(0xFFF5F3FF),
        );
      case DeviceType.aircon:
        return const _TypeTheme(
          activeCard:   Color(0xFF67E8F9),  // cyan — sidebar Aircon color
          activeBorder: Color(0xFFA5F3FC),
          iconBg:       Color(0xFFA5F3FC),
          badgeBg:      Color(0xFF67E8F9),
          statusText:   Color(0xFFCFFAFE),
          badgeText:    Color(0xFFECFEFF),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final on    = device.isOn;
    final theme = _theme;

    if (compact && device.type == DeviceType.curtain) {
      return _buildCompactCurtainCard(on, theme);
    }

    if (compact) {
      final bool showLightStatusPill = device.type == DeviceType.light;
      final String lightStatus = on ? 'ON' : 'OFF';
      final bool showAirconModeButtons = device.type == DeviceType.aircon &&
          (device.sceneAuto != null || device.sceneCool != null);
      final bool fixedSidebarTint = device.type == DeviceType.aircon;
      // Aircon: follow sidebar sizing (same as Lights card scale)
      final double iconBox = fixedSidebarTint ? 34 : 36;
      final double iconSize = fixedSidebarTint ? 17 : 16;
      final EdgeInsets contentPadding =
          fixedSidebarTint ? const EdgeInsets.all(8) : const EdgeInsets.all(12);
      final bool activeTint = on || fixedSidebarTint;
      final baseA = _surface(const Color(0xFF1B1C24), 0.92);
      // Lights: full black 2nd background (no tint, 100%).
      final baseB = (device.type == DeviceType.light || device.type == DeviceType.aircon)
          ? Colors.black
          : _surface(const Color(0xFF14151C), 0.92);
      final tintAmt = activeTint ? 0.08 : 0.0;
      final bgA =
          tintAmt == 0.0 ? baseA : Color.lerp(baseA, theme.activeCard, tintAmt)!;
      final bgB = (device.type == DeviceType.light || device.type == DeviceType.aircon)
          ? Colors.black
          : (tintAmt == 0.0
              ? baseB
              : Color.lerp(baseB, theme.activeCard, tintAmt)!);

      return GestureDetector(
        onTap: _handleCompactTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: contentPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgA, bgB],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: activeTint
                  ? theme.activeCard.withOpacity(0.22)
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
                  color: theme.activeCard.withOpacity(0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Icon + status badge row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: activeTint
                          ? theme.activeCard.withOpacity(0.18)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_icon,
                        size: iconSize,
                        color: activeTint
                            ? theme.activeCard
                            : Colors.white.withOpacity(0.35)),
                  ),
                  if (showLightStatusPill)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: on
                            ? theme.activeCard.withOpacity(0.92)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: on
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        lightStatus,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: on
                              ? const Color(0xFF111827)
                              : Colors.white.withOpacity(0.55),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: showAirconModeButtons ? 4 : 8),

              // Name — auto-scales font down to fit, never clips
              if (showAirconModeButtons) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: on ? Colors.white : Colors.white.withOpacity(0.70),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 20,
                        child: Row(
                          children: [
                            if (device.sceneAuto != null)
                              Expanded(
                                child: _AirconModeMiniBtn(
                                  label: 'Auto',
                                  color: theme.activeCard,
                                  active: device.airconMode == AirconMode.auto,
                                  onTap: () => provider.triggerAirconScene(
                                    device.id,
                                    device.sceneAuto!,
                                    mode: AirconMode.auto,
                                  ),
                                ),
                              ),
                            if (device.sceneAuto != null && device.sceneCool != null)
                              const SizedBox(width: 8),
                            if (device.sceneCool != null)
                              Expanded(
                                child: _AirconModeMiniBtn(
                                  label: 'Cool',
                                  color: theme.activeCard,
                                  active: device.airconMode == AirconMode.cool,
                                  onTap: () => provider.triggerAirconScene(
                                    device.id,
                                    device.sceneCool!,
                                    mode: AirconMode.cool,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: Text(
                      _displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: on ? Colors.white : Colors.white.withOpacity(0.70),
                      ),
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],

              // Status label pinned to bottom (except Lights and Aircon)
              if (!showLightStatusPill && !showAirconModeButtons)
                Text(
                  device.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: on
                        ? theme.statusText.withOpacity(0.9)
                        : Colors.white.withOpacity(0.35),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      );
    }

    // Expanded card
    return _buildExpandedCard(context, on, theme);
  }

  // Compact curtain card — shows Open / Stop / Close / Tilt buttons
  Widget _buildCompactCurtainCard(bool on, _TypeTheme theme) {
    const btnH = 36.0;
    final r = BorderRadius.circular(18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _surface(const Color(0xFF1B1C24), 0.92),
            Colors.black,
          ],
        ),
        borderRadius: r,
        border: Border.all(
          color: on
              ? theme.activeCard.withOpacity(0.22)
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
              color: theme.activeCard.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // This card is typically placed in a fixed-height box.
              // Use the full height so buttons can be larger.
              mainAxisSize: MainAxisSize.max,
              children: [
          // Icon + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                // Match Lights bulb sizing (compact card header)
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: on
                      ? theme.activeCard.withOpacity(0.18)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 18,
                    color: on
                        ? theme.activeCard
                        : Colors.white.withOpacity(0.35)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: on ? Colors.white : Colors.white.withOpacity(0.80),
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Action buttons — fixed 2-row layout:
          // Open / Stop / Close
          // Tilt / Straighten
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              Row(
                children: [
                  if (device.sceneCurtainOpen != null)
                    Expanded(
                      child: SizedBox(
                        height: btnH,
                        child: _CurtainMiniBtn(
                          label: 'Open',
                          color: theme.activeBorder,
                          onTap: () =>
                              provider.triggerCurtainScene(device.id, 'open'),
                        ),
                      ),
                    ),
                  if (device.sceneCurtainOpen != null) const SizedBox(width: 6),
                  if (device.sceneCurtainStop != null)
                    Expanded(
                      child: SizedBox(
                        height: btnH,
                        child: _CurtainMiniBtn(
                          label: 'Stop',
                          color: theme.activeBorder,
                          onTap: () =>
                              provider.triggerCurtainScene(device.id, 'stop'),
                        ),
                      ),
                    ),
                  if (device.sceneCurtainStop != null) const SizedBox(width: 6),
                  if (device.sceneCurtainClose != null)
                    Expanded(
                      child: SizedBox(
                        height: btnH,
                        child: _CurtainMiniBtn(
                          label: 'Close',
                          color: theme.activeBorder,
                          onTap: () =>
                              provider.triggerCurtainScene(device.id, 'close'),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (device.sceneCurtainTilt != null)
                    Expanded(
                      child: SizedBox(
                        height: btnH,
                        child: _CurtainMiniBtn(
                          label: 'Tilt',
                          color: theme.activeBorder,
                          onTap: () =>
                              provider.triggerCurtainScene(device.id, 'tilt'),
                        ),
                      ),
                    ),
                  if (device.sceneCurtainTilt != null) const SizedBox(width: 6),
                  if (device.sceneCurtainUntilt != null)
                    Expanded(
                      child: SizedBox(
                        height: btnH,
                        child: _CurtainMiniBtn(
                          label: 'Straighten',
                          color: theme.activeBorder,
                          onTap: () =>
                              provider.triggerCurtainScene(device.id, 'untilt'),
                        ),
                      ),
                    ),
                ],
              ),
                ],
              ),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCard(BuildContext context, bool on, _TypeTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface(Colors.black.withOpacity(0.40)),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: device.status
              ? Colors.black.withOpacity(0.50)
              : Colors.black.withOpacity(0.50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + toggle (only for non-scene curtains)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: device.status
                      ? const Color(0xFFC084FC).withOpacity(0.50)
                      : const Color(0xFF67E8F9).withOpacity(0.50),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _icon,
                  size: 22,
                  color: device.status ? const Color(0xFFC084FC) : const Color(0xFF67E8F9),
                ),
              ),
              if (!device.hasCurtainScenes)
                _ToggleSwitch(
                  value: device.status,
                  onChanged: (_) => provider.toggleDevice(device.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: device.status ? Colors.white : Colors.grey[400],
              ),
              maxLines: 2,
              softWrap: true,
            ),
          ),
          Text(
            device.room,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              letterSpacing: 0.8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Aircon scene buttons
          if (device.type == DeviceType.aircon &&
              (device.sceneAuto != null || device.sceneCool != null)) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                if (device.sceneAuto != null)
                  _SceneButton(
                    label: 'Auto',
                    active: device.airconMode == AirconMode.auto,
                    onTap: () => provider.triggerAirconScene(
                        device.id, device.sceneAuto!,
                        mode: AirconMode.auto),
                  ),
                if (device.sceneCool != null)
                  _SceneButton(
                    label: 'Cool',
                    active: device.airconMode == AirconMode.cool,
                    onTap: () => provider.triggerAirconScene(
                        device.id, device.sceneCool!,
                        mode: AirconMode.cool),
                  ),
              ],
            ),
          ],

          // Curtain scene buttons
          if (device.type == DeviceType.curtain && device.hasCurtainScenes) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (device.sceneCurtainOpen != null)
                  _SceneButton(label: 'Open', active: false,
                      onTap: () => provider.triggerCurtainScene(device.id, 'open')),
                if (device.sceneCurtainStop != null)
                  _SceneButton(label: 'Stop', active: false,
                      onTap: () => provider.triggerCurtainScene(device.id, 'stop')),
                if (device.sceneCurtainClose != null)
                  _SceneButton(label: 'Close', active: false,
                      onTap: () => provider.triggerCurtainScene(device.id, 'close')),
                if (device.sceneCurtainTilt != null)
                  _SceneButton(label: 'Tilt', active: false,
                      onTap: () => provider.triggerCurtainScene(device.id, 'tilt')),
                if (device.sceneCurtainUntilt != null)
                  _SceneButton(label: 'Straighten', active: false,
                      onTap: () => provider.triggerCurtainScene(device.id, 'untilt')),
              ],
            ),
          ],

          // Curtain presets (no scenes)
          if (device.type == DeviceType.curtain && !device.hasCurtainScenes) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _SceneButton(
                  label: 'Close',
                  active: device.value != null && device.value! <= 10,
                  onTap: () => provider.setCurtainPreset(device.id, 0),
                ),
                const SizedBox(width: 8),
                _SceneButton(
                  label: 'Open',
                  active: device.value != null && (device.value! - 50).abs() <= 10,
                  onTap: () => provider.setCurtainPreset(device.id, 50),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Tilt',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 1)),
                const SizedBox(width: 10),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbColor: Colors.white,
                      activeTrackColor: const Color(0xFFF97316),
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      overlayColor: Colors.transparent,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      min: 0,
                      max: 100,
                      value: (device.value ?? 0).clamp(0, 100),
                      onChanged: (v) =>
                          provider.setCurtainPosition(device.id, v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${(device.value ?? 0).round()}%',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ],

          // Running indicator
          if (device.status) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFB923C),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'RUNNING',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFB923C),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle switch
// ---------------------------------------------------------------------------

class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const _ToggleSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value
              ? const Color(0xFFF97316)
              : const Color(0xFF52525B).withOpacity(0.7),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scene button
// ---------------------------------------------------------------------------

class _SceneButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SceneButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF22D3EE).withOpacity(0.3)
              : DeviceCard._surface(Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? const Color(0xFF22D3EE).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: active ? const Color(0xFF67E8F9) : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini action button for compact curtain cards
// ─────────────────────────────────────────────────────────────────────────────

class _CurtainMiniBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CurtainMiniBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
                DeviceCard._surface(const Color(0xFF232634), 0.90),
                DeviceCard._surface(const Color(0xFF1C1F2B), 0.90),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini mode button for compact aircon cards (Auto / Cool)
// ─────────────────────────────────────────────────────────────────────────────

class _AirconModeMiniBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _AirconModeMiniBtn({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? DeviceCard._surface(color.withOpacity(0.85), 0.92)
              : DeviceCard._surface(Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? Colors.transparent : color.withOpacity(0.22),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: active ? const Color(0xFF0B1220) : Colors.white.withOpacity(0.70),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-type color palette
// ─────────────────────────────────────────────────────────────────────────────

class _TypeTheme {
  final Color activeCard;
  final Color activeBorder;
  final Color iconBg;
  final Color badgeBg;
  final Color statusText;
  final Color badgeText;

  const _TypeTheme({
    required this.activeCard,
    required this.activeBorder,
    required this.iconBg,
    required this.badgeBg,
    required this.statusText,
    required this.badgeText,
  });
}
