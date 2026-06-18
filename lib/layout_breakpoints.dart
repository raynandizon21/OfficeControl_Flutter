import 'package:flutter/material.dart';

/// Shared layout breakpoints for phone, tablet, desktop, and foldables.
class LayoutBreakpoints {
  LayoutBreakpoints._();

  static const double phoneMaxShortestSide = 600;

  /// Unfolded foldables (~6:5, e.g. Galaxy Z Fold5 at 2176×1812) and similar
  /// near-square tablets in landscape.
  static const double compactLandscapeMaxAspect = 1.35;

  static const double sidebarWidthDefault = 280;
  static const double sidebarWidthCompact = 232;

  /// Z Fold5 unfolded at DPR 2.5–3 can report shortestSide ~580–690 — still fold.
  static bool isUnfoldedFoldable(Size size) {
    final shortest = size.shortestSide;
    final longest = size.longestSide;
    if (longest < 650) return false;
    final aspect = longest / shortest;
    return aspect >= 1.12 && aspect < compactLandscapeMaxAspect;
  }

  static bool isPhoneLayout(Size size) {
    if (isUnfoldedFoldable(size)) return false;
    return size.shortestSide < phoneMaxShortestSide;
  }

  /// Near-square large displays: unfolded foldables (~6:5), portrait or landscape.
  static bool isNearSquareTablet(Size size) => isUnfoldedFoldable(size);

  /// Phone + unfolded foldable in portrait → drawer instead of fixed sidebar.
  static bool useDrawerLayout(Size size) {
    if (isPhoneLayout(size)) return true;
    return isPortraitUnfold(size);
  }

  /// Portrait unfold on Z Fold / near-square tablets.
  static bool isPortraitUnfold(Size size) =>
      isNearSquareTablet(size) && size.height > size.width;

  /// Full-screen floor plan (no sidebar) on Z Fold / near-square.
  static bool useImmersiveFloorPlan(Size size) => isNearSquareTablet(size);

  static double sidebarWidth(Size size) {
    if (isPhoneLayout(size)) return sidebarWidthDefault;
    if (isNearSquareTablet(size)) return sidebarWidthCompact;
    return sidebarWidthDefault;
  }

  static bool sidebarCompact(Size size) =>
      isPhoneLayout(size) || isNearSquareTablet(size);
}
