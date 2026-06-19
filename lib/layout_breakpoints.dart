import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';

/// Shared layout breakpoints for phone, tablet, desktop, and foldables.
class LayoutBreakpoints {
  LayoutBreakpoints._();

  static const double phoneMaxShortestSide = 600;

  /// Unfolded foldables (~6:5, e.g. Galaxy Z Fold5 at 2176×1812) and similar
  /// near-square tablets in landscape.
  static const double compactLandscapeMaxAspect = 1.35;

  /// Cover screen (~2316×904) — ultra-wide aspect when folded.
  static const double foldCoverMinAspect = 2.1;
  static const double foldCoverMaxAspect = 3.3;

  static const double sidebarWidthDefault = 280;
  static const double sidebarWidthCompact = 232;

  /// Upper bound for portrait tablet floor plan (excludes desktop monitors).
  static const double tabletPortraitMaxShortestSide = 1200;

  static bool isPortrait(Size size) => size.height >= size.width;

  static bool isLandscape(Size size) => size.width > size.height;

  /// True on Android/iOS builds — not web or desktop targets.
  static bool get isNativeMobilePlatform {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  /// Fold panel detection on a physical phone/tablet only (not desktop browser size).
  static bool isMobileFoldableLayout(Size size) =>
      isNativeMobilePlatform && isFoldableDevice(size);

  /// Desktop / tablet landscape with enough room to scale the transparent plan up.
  static bool isLargeLandscapeScreen(Size size) =>
      isLandscape(size) &&
      size.longestSide >= 1024 &&
      size.shortestSide >= 600;

  /// Z Fold inner (~2176×1812). Logical size varies with DPR — use aspect, not fixed px.
  static bool isUnfoldedFoldable(Size size) {
    final shortest = size.shortestSide;
    final longest = size.longestSide;
    if (longest < 520) return false;
    if (shortest < 420) return false;
    final aspect = longest / shortest;
    return aspect >= 1.12 && aspect < compactLandscapeMaxAspect;
  }

  /// Z Fold cover (~2316×904) — narrow outer display, any orientation.
  static bool isFoldableCoverScreen(Size size) {
    final shortest = size.shortestSide;
    final longest = size.longestSide;
    if (longest < 600) return false;
    final aspect = longest / shortest;
    return aspect >= foldCoverMinAspect && aspect <= foldCoverMaxAspect;
  }

  /// Inner or cover fold panel — never show fixed sidebar.
  static bool isFoldableDevice(Size size) =>
      isUnfoldedFoldable(size) || isFoldableCoverScreen(size);

  static bool isPhoneLayout(Size size) {
    if (isFoldableDevice(size)) return false;
    return size.shortestSide < phoneMaxShortestSide;
  }

  /// Near-square large displays: unfolded foldables (~6:5), portrait or landscape.
  static bool isNearSquareTablet(Size size) => isUnfoldedFoldable(size);

  /// Phone + mobile foldables → drawer. Desktop/web keeps fixed sidebar.
  static bool useDrawerLayout(Size size) {
    if (isMobileFoldableLayout(size)) return true;
    if (isPhoneLayout(size)) return true;
    return false;
  }

  /// Portrait unfold on Z Fold / near-square tablets.
  static bool isPortraitUnfold(Size size) =>
      isNearSquareTablet(size) && isPortrait(size);

  /// Vertical floor plan asset: portrait phone, mobile foldable, or large tablet.
  static bool usePortraitMobileFloorPlan(Size size) {
    if (!isPortrait(size)) return false;
    if (isPhoneLayout(size)) return true;
    if (isMobileFoldableLayout(size)) return true;
    return size.shortestSide >= phoneMaxShortestSide &&
        size.shortestSide < tabletPortraitMaxShortestSide;
  }

  /// Portrait tablet with fixed sidebar (e.g. iPad) — narrow floor plan area.
  static bool useSidebarPortraitTablet(Size size) =>
      isPortrait(size) &&
      !useDrawerLayout(size) &&
      usePortraitMobileFloorPlan(size);

  /// Shortest-side bucket for small phones / small tablets.
  static bool isCompactScreen(Size size) => size.shortestSide < phoneMaxShortestSide;

  static double sidebarWidth(Size size) {
    if (isPhoneLayout(size)) return sidebarWidthDefault;
    if (isUnfoldedFoldable(size)) return sidebarWidthCompact;
    if (isFoldableCoverScreen(size)) return sidebarWidthDefault;
    return sidebarWidthDefault;
  }

  /// Full-screen floor plan (no fixed sidebar) on mobile fold only.
  static bool useImmersiveFloorPlan(Size size) => isMobileFoldableLayout(size);

  static bool sidebarCompact(Size size) =>
      isPhoneLayout(size) || isUnfoldedFoldable(size);
}
