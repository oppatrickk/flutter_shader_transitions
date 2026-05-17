import 'package:flutter/material.dart';
import 'package:shader_transitions/shader_transitions.dart';

/// The target screen pushed by each gallery card.
///
/// Shows details about the active transition and lets the user pop back
/// (which plays the reverse animation) or push another layer forward.
class DestinationScreen extends StatelessWidget {
  const DestinationScreen({super.key, required this.transition});

  final ShaderTransition transition;

  String get _typeName => switch (transition) {
        DiamondTransition() => 'Diamond',
        CircleTransition() => 'Circle',
        WipeTransition() => 'Wipe',
        ClockTransition() => 'Clock',
        PolygonTransition() => 'Polygon',
        DissolveTransition() => 'Dissolve',
        FadeShaderTransition() => 'Fade',
      };

  String _directionName(SweepDirection d) => switch (d) {
        SweepDirection.topLeftToBottomRight => 'Top-left → Bottom-right',
        SweepDirection.bottomRightToTopLeft => 'Bottom-right → Top-left',
        SweepDirection.leftToRight => 'Left → Right',
        SweepDirection.rightToLeft => 'Right → Left',
        SweepDirection.topToBottom => 'Top → Bottom',
        SweepDirection.bottomToTop => 'Bottom → Top',
        SweepDirection.topRightToBottomLeft => 'Top-right → Bottom-left',
        SweepDirection.bottomLeftToTopRight => 'Bottom-left → Top-right',
      };

  Color get _accentColor => switch (transition) {
        DiamondTransition() => const Color(0xFF7C4DFF),
        CircleTransition() => const Color(0xFF00BCD4),
        WipeTransition() => const Color(0xFF00897B),
        ClockTransition() => const Color(0xFFEF6C00),
        PolygonTransition() => const Color(0xFFAD1457),
        DissolveTransition() => const Color(0xFF455A64),
        FadeShaderTransition() => const Color(0xFF5E35B1),
      };

  IconData get _icon => switch (transition) {
        DiamondTransition() => Icons.diamond_outlined,
        CircleTransition() => Icons.radio_button_unchecked,
        WipeTransition() => Icons.swipe_right_outlined,
        ClockTransition() => Icons.access_time,
        PolygonTransition() => Icons.pentagon_outlined,
        DissolveTransition() => Icons.grain,
        FadeShaderTransition() => Icons.gradient,
      };

  /// Per-type detail rows for the info panel.
  List<(String, String)> _details() {
    final t = transition;
    switch (t) {
      case DiamondTransition():
        return [
          ('Direction', _directionName(t.direction)),
          ('Duration', '${t.duration.inMilliseconds} ms'),
          ('Cell size', '${t.cellSize.toStringAsFixed(0)} px'),
          ('Invert', t.invert ? 'Yes' : 'No'),
        ];
      case CircleTransition():
        return [
          ('Origin', '${t.origin.x}, ${t.origin.y}'),
          ('Duration', '${t.duration.inMilliseconds} ms'),
          ('Invert', t.invert ? 'Contracting' : 'Expanding'),
        ];
      case WipeTransition():
        return [
          ('Direction', _directionName(t.direction)),
          ('Duration', '${t.duration.inMilliseconds} ms'),
          ('Softness', '${t.softness.toStringAsFixed(0)} px'),
          ('Invert', t.invert ? 'Yes' : 'No'),
        ];
      case ClockTransition():
        return [
          ('Sectors', '${t.sectors}'),
          ('Duration', '${t.duration.inMilliseconds} ms'),
          ('Invert', t.invert ? 'Counter-clockwise' : 'Clockwise'),
        ];
      case PolygonTransition():
        return [
          ('Sides', '${t.sides}'),
          ('Duration', '${t.duration.inMilliseconds} ms'),
          ('Invert', t.invert ? 'Contracting' : 'Expanding'),
        ];
      case DissolveTransition():
        return [
          ('Grain', t.grain.toStringAsFixed(0)),
          ('Duration', '${t.duration.inMilliseconds} ms'),
          ('Invert', t.invert ? 'Yes' : 'No'),
        ];
      case FadeShaderTransition():
        return [
          ('Duration', '${t.duration.inMilliseconds} ms'),
          ('Invert', t.invert ? 'Fade out' : 'Fade in'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('$_typeName Transition'),
        centerTitle: true,
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero icon
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Icon(_icon, size: 72, color: accent),
              ),

              const SizedBox(height: 32),

              // Transition details
              InfoRow(label: 'Type', value: _typeName, accent: accent),
              for (final (label, value) in _details()) ...[
                const Divider(height: 24),
                InfoRow(label: label, value: value, accent: accent),
              ],

              const Spacer(),

              // Push another layer to show stacking works
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  ShaderPageRoute(
                    page: DestinationScreen(transition: transition),
                    transition: transition,
                  ),
                ),
                icon: const Icon(Icons.layers_outlined),
                label: const Text('Push again (stack test)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Pop (reverse transition)'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: accent,
          ),
        ),
      ],
    );
  }
}
