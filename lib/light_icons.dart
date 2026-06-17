import 'package:flutter/material.dart';
import 'models/device.dart';

/// Floor plan + device card — classic bulb with rays (matches floor plan markers).
IconData lightMarkerIcon(LightIcon? type, {required bool on}) {
  return on ? Icons.wb_incandescent : Icons.wb_incandescent_outlined;
}