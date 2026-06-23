import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants.dart';

/// Font Awesome fan (`fa-solid fa-fan` / `fa-light fa-fan`).
const _fanIcon = FontAwesomeIcons.fan;

class PropellerFanIcon extends StatefulWidget {
  final bool active;
  final double size;
  final double shapeScale;
  final Color? color;

  const PropellerFanIcon({
    super.key,
    required this.active,
    this.size = 20,
    this.shapeScale = 1.0,
    this.color,
  });

  @override
  State<PropellerFanIcon> createState() => _PropellerFanIconState();
}

class _PropellerFanIconState extends State<PropellerFanIcon>
    with TickerProviderStateMixin {
  Ticker? _ticker;
  Duration? _previousElapsed;
  double _angle = 0;
  double _angularVelocity = 0;

  static const _spinPeriodSec = 2.0;
  static const _maxOmega = 2 * math.pi / _spinPeriodSec;
  static const _coastDurationSec = 1.4;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _angularVelocity = _maxOmega;
      _startTicker();
    }
  }

  @override
  void didUpdateWidget(covariant PropellerFanIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _angularVelocity = _maxOmega;
      _startTicker();
    } else if (!widget.active && oldWidget.active) {
      _startTicker();
    }
  }

  void _startTicker() {
    _previousElapsed = null;
    _ticker ??= createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final previous = _previousElapsed;
    _previousElapsed = elapsed;
    if (previous == null) return;

    final dt = (elapsed - previous).inMicroseconds / 1000000.0;
    if (dt <= 0) return;

    if (widget.active) {
      _angularVelocity = _maxOmega;
    } else if (_angularVelocity > 0) {
      const decel = _maxOmega / _coastDurationSec;
      _angularVelocity = math.max(0, _angularVelocity - decel * dt);
    }

    final wasSpinning = _angularVelocity > 0.001;
    if (wasSpinning) {
      _angle += _angularVelocity * dt;
      if (_angle >= 2 * math.pi) {
        _angle %= 2 * math.pi;
      }
    }

    if (mounted) {
      setState(() {});
    }

    if (!wasSpinning) {
      _disposeTicker();
    }
  }

  void _disposeTicker() {
    _ticker?.dispose();
    _ticker = null;
    _previousElapsed = null;
  }

  @override
  void dispose() {
    _disposeTicker();
    super.dispose();
  }

  bool get _isSpinning => _angularVelocity > 0.001;

  @override
  Widget build(BuildContext context) {
    final defaultColor =
        widget.active || _isSpinning ? kIotOn : kIotOff;
    final iconColor = widget.color ?? defaultColor;
    final scale = widget.shapeScale.clamp(0.1, 1.0);

    Widget icon = FaIcon(
      _fanIcon,
      size: widget.size * scale,
      color: iconColor,
    );

    if (_isSpinning) {
      icon = Transform.rotate(angle: _angle, child: icon);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(child: icon),
    );
  }
}
