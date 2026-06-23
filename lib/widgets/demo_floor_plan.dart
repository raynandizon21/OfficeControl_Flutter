import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DemoFloorLevel { first, second, third }

extension DemoFloorLevelX on DemoFloorLevel {
  String get label => switch (this) {
        DemoFloorLevel.first => '1st Floor',
        DemoFloorLevel.second => '2nd Floor',
        DemoFloorLevel.third => '3rd Floor',
      };

  String get assetPath => switch (this) {
        DemoFloorLevel.first => 'assets/images/1ST_FLOOR (1).png',
        DemoFloorLevel.second => 'assets/images/2ND_FLOOR (1).png',
        DemoFloorLevel.third => 'assets/images/3RD_FLOOR (1).png',
      };

  /// Values below 1.0 zoom out the floor plan on first load.
  double get displayScale => switch (this) {
        DemoFloorLevel.first => 0.88,
        DemoFloorLevel.second => 0.88,
        DemoFloorLevel.third => 1.0,
      };
}

/// Flutter web serves files as `1ST_FLOOR%20(1).png` but [Image.asset] requests
/// `1ST_FLOOR%2520(1).png`, causing 404. Use a single-encoded network URL.
String _webAssetUrl(String assetPath) {
  final encoded =
      assetPath.split('/').map(Uri.encodeComponent).join('/');
  return Uri.base.resolve(encoded).toString();
}

const _demoFloorBackground = BoxDecoration(
  color: Color(0xFF833AB4),
  gradient: LinearGradient(
    colors: [
      Color(0xFF833AB4),
      Color(0xFFFD1D1D),
      Color(0xFFFCB045),
    ],
    stops: [0.0, 0.5, 1.0],
    transform: GradientRotation(151 * math.pi / 180),
  ),
);

class DemoFloorPlanWidget extends StatelessWidget {
  final DemoFloorLevel floor;

  const DemoFloorPlanWidget({super.key, required this.floor});

  @override
  Widget build(BuildContext context) {
    final path = floor.assetPath;

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: DecoratedBox(decoration: _demoFloorBackground),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = floor.displayScale;
            final imageW = constraints.maxWidth * scale;
            final imageH = constraints.maxHeight * scale;

            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: kIsWeb
                    ? Image.network(
                        _webAssetUrl(path),
                        fit: BoxFit.contain,
                        width: imageW,
                        height: imageH,
                        errorBuilder: (_, __, ___) => _loadError(floor.label),
                      )
                    : Image.asset(
                        path,
                        fit: BoxFit.contain,
                        width: imageW,
                        height: imageH,
                        errorBuilder: (_, __, ___) => _loadError(floor.label),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _loadError(String label) {
    return Text(
      'Could not load $label',
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 14,
      ),
    );
  }
}
