import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/floor_plan.dart';
import '../widgets/device_grid.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ViewType _activeView = ViewType.rooms;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final media = MediaQuery.of(context);
    final isPortrait = media.orientation == Orientation.portrait || media.size.width < 800;

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: isPortrait
          ? Drawer(
              width: 260,
              backgroundColor: Colors.transparent,
              child: Sidebar(
                activeView: _activeView,
                onNavigate: (v) {
                  setState(() => _activeView = v);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar (only on desktop/landscape)
          if (!isPortrait)
            Sidebar(
              activeView: _activeView,
              onNavigate: (v) => setState(() => _activeView = v),
            ),

          // Vertical divider
          if (!isPortrait)
            Container(
              width: 1,
              color: Colors.white.withOpacity(0.05),
            ),

          // Main content
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    if (isPortrait)
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu_rounded, color: Colors.white70),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        title: Text(
                          _activeView.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Expanded(child: _buildContent()),
                  ],
                ),
                if (provider.syncError != null)
                  Positioned(
                    top: isPortrait ? 60 : 12,
                    right: 12,
                    child: _SyncErrorToast(message: provider.syncError!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeView) {
      case ViewType.rooms:
        return const FloorPlanWidget();
      case ViewType.devices:
        return DeviceGrid(defaultFilter: ViewType.devices);
      case ViewType.curtain:
        return DeviceGrid(defaultFilter: ViewType.curtain);
      case ViewType.aircon:
        return DeviceGrid(defaultFilter: ViewType.aircon);
      case ViewType.light:
        return DeviceGrid(defaultFilter: ViewType.light);
    }
  }
}

class _SyncErrorToast extends StatelessWidget {
  final String message;

  const _SyncErrorToast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF87171).withOpacity(0.5)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
      ),
    );
  }
}
