import 'package:flutter/material.dart';
import 'package:shader_transitions/shader_transitions.dart';

/// The target screen pushed by each gallery card.
///
/// Shows details about the active transition and lets the user pop back
/// (which plays the reverse animation) or push another layer forward.
class DestinationScreen extends StatelessWidget {
  const DestinationScreen({super.key, required this.config});

  final ShaderTransitionConfig config;

  String get _typeName => switch (config.type) {
        TransitionType.diamond => 'Diamond',
        TransitionType.circle => 'Circle',
        TransitionType.wipe => 'Wipe',
      };

  String get _directionName => switch (config.direction) {
        SweepDirection.topLeftToBottomRight => 'Top-left → Bottom-right',
        SweepDirection.bottomRightToTopLeft => 'Bottom-right → Top-left',
        SweepDirection.leftToRight => 'Left → Right',
        SweepDirection.rightToLeft => 'Right → Left',
        SweepDirection.topToBottom => 'Top → Bottom',
        SweepDirection.bottomToTop => 'Bottom → Top',
        SweepDirection.topRightToBottomLeft => 'Top-right → Bottom-left',
        SweepDirection.bottomLeftToTopRight => 'Bottom-left → Top-right',
      };

  Color get _accentColor => switch (config.type) {
        TransitionType.diamond => const Color(0xFF7C4DFF),
        TransitionType.circle => const Color(0xFF00BCD4),
        TransitionType.wipe => const Color(0xFF00897B),
      };

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
                child: Icon(
                  config.type == TransitionType.diamond
                      ? Icons.diamond_outlined
                      : config.type == TransitionType.circle
                          ? Icons.radio_button_unchecked
                          : Icons.swipe_right_outlined,
                  size: 72,
                  color: accent,
                ),
              ),

              const SizedBox(height: 32),

              // Transition details
              InfoRow(label: 'Type', value: _typeName, accent: accent),
              const Divider(height: 24),
              InfoRow(
                label: 'Direction',
                value: config.type == TransitionType.circle
                    ? 'Center outward'
                    : _directionName,
                accent: accent,
              ),
              const Divider(height: 24),
              InfoRow(
                label: 'Duration',
                value: '${config.transitionDuration.inMilliseconds} ms',
                accent: accent,
              ),
              if (config.type != TransitionType.circle) ...[
                const Divider(height: 24),
                InfoRow(
                  label: config.type == TransitionType.diamond
                      ? 'Cell size'
                      : 'Feather',
                  value: '${config.size.toStringAsFixed(0)} px',
                  accent: accent,
                ),
              ],

              const Spacer(),

              // Push another layer to show stacking works
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  ShaderPageRoute(
                    page: DestinationScreen(config: config),
                    config: config,
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
