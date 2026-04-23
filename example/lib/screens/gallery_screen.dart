import 'package:flutter/material.dart';
import 'package:shader_transitions/shader_transitions.dart';

import 'destination_screen.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _TransitionDemo {
  const _TransitionDemo({
    required this.label,
    required this.icon,
    required this.config,
    required this.color,
  });

  final String label;
  final IconData icon;
  final ShaderTransitionConfig config;
  final Color color;
}

const List<_TransitionDemo> _demos = [
  // Diamond variants
  _TransitionDemo(
    label: 'Diamond\n↘ diagonal',
    icon: Icons.diamond_outlined,
    config: ShaderTransitionConfig.diamond(
      direction: SweepDirection.topLeftToBottomRight,
    ),
    color: Color(0xFF7C4DFF),
  ),
  _TransitionDemo(
    label: 'Diamond\n→ left to right',
    icon: Icons.diamond_outlined,
    config: ShaderTransitionConfig.diamond(
      direction: SweepDirection.leftToRight,
      size: 32.0,
    ),
    color: Color(0xFF651FFF),
  ),
  _TransitionDemo(
    label: 'Diamond\n↓ top to bottom',
    icon: Icons.diamond_outlined,
    config: ShaderTransitionConfig.diamond(
      direction: SweepDirection.topToBottom,
      size: 48.0,
    ),
    color: Color(0xFF6200EA),
  ),
  _TransitionDemo(
    label: 'Diamond\n↗ bottom-left',
    icon: Icons.diamond_outlined,
    config: ShaderTransitionConfig.diamond(
      direction: SweepDirection.bottomLeftToTopRight,
      size: 28.0,
    ),
    color: Color(0xFF3D5AFE),
  ),

  // Circle / iris
  _TransitionDemo(
    label: 'Circle\niris wipe',
    icon: Icons.radio_button_unchecked,
    config: ShaderTransitionConfig.circle(),
    color: Color(0xFF00BCD4),
  ),

  // Wipe variants
  _TransitionDemo(
    label: 'Wipe\n→ left to right',
    icon: Icons.swipe_right_outlined,
    config: ShaderTransitionConfig.wipe(
      direction: SweepDirection.leftToRight,
      size: 6.0,
    ),
    color: Color(0xFF00897B),
  ),
  _TransitionDemo(
    label: 'Wipe\n← right to left',
    icon: Icons.swipe_left_outlined,
    config: ShaderTransitionConfig.wipe(
      direction: SweepDirection.rightToLeft,
      size: 6.0,
    ),
    color: Color(0xFF43A047),
  ),
  _TransitionDemo(
    label: 'Wipe\n↓ top to bottom',
    icon: Icons.swipe_down_outlined,
    config: ShaderTransitionConfig.wipe(
      direction: SweepDirection.topToBottom,
      size: 8.0,
    ),
    color: Color(0xFFF57F17),
  ),
  _TransitionDemo(
    label: 'Wipe\n↑ bottom to top',
    icon: Icons.swipe_up_outlined,
    config: ShaderTransitionConfig.wipe(
      direction: SweepDirection.bottomToTop,
      size: 8.0,
    ),
    color: Color(0xFFE65100),
  ),
  _TransitionDemo(
    label: 'Wipe\nhard edge',
    icon: Icons.vertical_split_outlined,
    config: ShaderTransitionConfig.wipe(
      direction: SweepDirection.leftToRight,
      size: 0.0,
    ),
    color: Color(0xFFC62828),
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  void _push(BuildContext context, ShaderTransitionConfig config) {
    Navigator.of(context).push(
      ShaderPageRoute(
        page: DestinationScreen(config: config),
        config: config,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shader Transitions'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Tap a card to preview the transition.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _demos.length,
              itemBuilder: (context, index) {
                final demo = _demos[index];
                return _TransitionCard(
                  demo: demo,
                  onTap: () => _push(context, demo.config),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------

class _TransitionCard extends StatelessWidget {
  const _TransitionCard({required this.demo, required this.onTap});

  final _TransitionDemo demo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                demo.color.withValues(alpha: 0.8),
                demo.color,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(demo.icon, size: 36, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                demo.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
