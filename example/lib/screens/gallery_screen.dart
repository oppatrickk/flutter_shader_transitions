import 'package:flutter/material.dart';
import 'package:shader_transitions/shader_transitions.dart';

import 'destination_screen.dart';

// Anything below this width (in logical pixels) gets the page-navigation flow
// instead of the two-column master/detail layout.
const double _wideLayoutBreakpoint = 720;

// ---------------------------------------------------------------------------
// Type catalogue
// ---------------------------------------------------------------------------

class _TypeOption {
  const _TypeOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.accent,
    required this.description,
  });

  final TransitionType type;
  final String label;
  final IconData icon;
  final Color accent;
  final String description;
}

const List<_TypeOption> _types = [
  _TypeOption(
    type: TransitionType.diamond,
    label: 'Diamond',
    icon: Icons.diamond_outlined,
    accent: Color(0xFF7C4DFF),
    description: 'Grid of diamonds sweeps across the screen.',
  ),
  _TypeOption(
    type: TransitionType.circle,
    label: 'Circle iris',
    icon: Icons.radio_button_unchecked,
    accent: Color(0xFF00BCD4),
    description: 'Circular iris wipe expanding from the center.',
  ),
  _TypeOption(
    type: TransitionType.wipe,
    label: 'Wipe',
    icon: Icons.swipe_right_outlined,
    accent: Color(0xFF00897B),
    description: 'Linear feathered wipe in any of 8 directions.',
  ),
];

_TypeOption _optionFor(TransitionType t) =>
    _types.firstWhere((o) => o.type == t);

// ---------------------------------------------------------------------------
// Editor presets — values used when an editor mounts for a given type.
// ---------------------------------------------------------------------------

ShaderTransitionConfig _defaultsFor(TransitionType t) => switch (t) {
      TransitionType.diamond => const ShaderTransitionConfig.diamond(),
      TransitionType.circle => const ShaderTransitionConfig.circle(),
      TransitionType.wipe => const ShaderTransitionConfig.wipe(),
    };

// ---------------------------------------------------------------------------
// Gallery screen — layout-aware shell.
// ---------------------------------------------------------------------------

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Tracked only for the wide (two-column) layout. The narrow layout uses a
  // pushed page so the gallery itself stays type-agnostic.
  TransitionType? _selectedType;

  void _push(BuildContext context, ShaderTransitionConfig config) {
    Navigator.of(context).push(
      ShaderPageRoute(
        page: DestinationScreen(config: config),
        config: config,
      ),
    );
  }

  void _openEditorPage(BuildContext context, TransitionType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _EditorPage(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shader Transitions'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideLayoutBreakpoint;
          if (isWide) {
            return _buildWide(context);
          }
          return _buildNarrow(context);
        },
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 260,
          child: _TypeList(
            selected: _selectedType,
            onSelect: (t) => setState(() => _selectedType = t),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: theme.colorScheme.outlineVariant,
        ),
        Expanded(
          child: _selectedType == null
              ? const _EmptyState()
              : _TransitionEditor(
                  // ValueKey ensures the editor remounts (and resets its state)
                  // when the user picks a different type from the list.
                  key: ValueKey(_selectedType),
                  type: _selectedType!,
                  onTest: (config) => _push(context, config),
                ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return _TypeList(
      selected: null,
      onSelect: (t) => _openEditorPage(context, t),
    );
  }
}

// ---------------------------------------------------------------------------
// Left-column type list (used in both layouts)
// ---------------------------------------------------------------------------

class _TypeList extends StatelessWidget {
  const _TypeList({required this.selected, required this.onSelect});

  final TransitionType? selected;
  final ValueChanged<TransitionType> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _types.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final option = _types[index];
        final isSelected = selected == option.type;
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: option.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(option.icon, color: option.accent),
          ),
          title: Text(
            option.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            option.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          selected: isSelected,
          selectedTileColor: theme.colorScheme.primaryContainer
              .withValues(alpha: 0.35),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onSelect(option.type),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state shown in the wide layout before a type is picked
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Pick a transition type on the left to configure it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Narrow-layout editor page — wraps the editor in a Scaffold + back button
// ---------------------------------------------------------------------------

class _EditorPage extends StatelessWidget {
  const _EditorPage({required this.type});

  final TransitionType type;

  @override
  Widget build(BuildContext context) {
    final option = _optionFor(type);
    return Scaffold(
      appBar: AppBar(
        title: Text(option.label),
        centerTitle: true,
        backgroundColor: option.accent,
        foregroundColor: Colors.white,
      ),
      body: _TransitionEditor(
        type: type,
        onTest: (config) {
          Navigator.of(context).push(
            ShaderPageRoute(
              page: DestinationScreen(config: config),
              config: config,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor — shared by both layouts
// ---------------------------------------------------------------------------

class _ColorChoice {
  const _ColorChoice(this.label, this.color);
  final String label;
  final Color? color;
}

const List<_ColorChoice> _colorChoices = [
  _ColorChoice('None', null),
  _ColorChoice('Black', Color(0xFF000000)),
  _ColorChoice('White', Color(0xFFFFFFFF)),
  _ColorChoice('Indigo', Color(0xFF1A237E)),
  _ColorChoice('Red', Color(0xFFC62828)),
];

String _directionLabel(SweepDirection d) => switch (d) {
      SweepDirection.topLeftToBottomRight => '↘ Top-left → Bottom-right',
      SweepDirection.bottomRightToTopLeft => '↖ Bottom-right → Top-left',
      SweepDirection.leftToRight => '→ Left → Right',
      SweepDirection.rightToLeft => '← Right → Left',
      SweepDirection.topToBottom => '↓ Top → Bottom',
      SweepDirection.bottomToTop => '↑ Bottom → Top',
      SweepDirection.topRightToBottomLeft => '↙ Top-right → Bottom-left',
      SweepDirection.bottomLeftToTopRight => '↗ Bottom-left → Top-right',
    };

class _TransitionEditor extends StatefulWidget {
  const _TransitionEditor({
    super.key,
    required this.type,
    required this.onTest,
  });

  final TransitionType type;
  final ValueChanged<ShaderTransitionConfig> onTest;

  @override
  State<_TransitionEditor> createState() => _TransitionEditorState();
}

class _TransitionEditorState extends State<_TransitionEditor> {
  late SweepDirection _direction;
  late double _transitionDurationMs;
  late double _size;
  Color? _color;
  double _coverDurationMs = 0.0;

  // Diamond uSize is clamped to ≥ 1 px in the shader; mirror that here so
  // the slider can't request a value the shader will silently override.
  static const double _minSizePx = 1.0;
  static const double _maxSizePx = 100.0;

  @override
  void initState() {
    super.initState();
    final defaults = _defaultsFor(widget.type);
    _direction = defaults.direction;
    _transitionDurationMs =
        defaults.transitionDuration.inMilliseconds.toDouble();
    _size = defaults.size;
    _color = defaults.color;
    _coverDurationMs = defaults.coverDuration.inMilliseconds.toDouble();
  }

  ShaderTransitionConfig _currentConfig() {
    final transitionDuration =
        Duration(milliseconds: _transitionDurationMs.round());
    // Cover hold is meaningful only when there's a cover color to hold on.
    final coverDuration = _color == null
        ? Duration.zero
        : Duration(milliseconds: _coverDurationMs.round());
    return switch (widget.type) {
      TransitionType.diamond => ShaderTransitionConfig.diamond(
          direction: _direction,
          transitionDuration: transitionDuration,
          size: _size,
          color: _color,
          coverDuration: coverDuration,
        ),
      TransitionType.circle => ShaderTransitionConfig.circle(
          transitionDuration: transitionDuration,
          color: _color,
          coverDuration: coverDuration,
        ),
      TransitionType.wipe => ShaderTransitionConfig.wipe(
          direction: _direction,
          transitionDuration: transitionDuration,
          size: _size,
          color: _color,
          coverDuration: coverDuration,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final option = _optionFor(widget.type);
    final hasDirection = widget.type != TransitionType.circle;
    final hasSize = widget.type != TransitionType.circle;
    final sizeLabel =
        widget.type == TransitionType.diamond ? 'Cell size' : 'Feather';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: option.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: option.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(option.icon, size: 32, color: option.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: option.accent,
                        ),
                      ),
                      Text(
                        option.description,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (hasDirection) ...[
            Text('Direction', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<SweepDirection>(
              initialValue: _direction,
              isExpanded: true,
              items: SweepDirection.values
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(_directionLabel(d)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _direction = v);
              },
            ),
            const SizedBox(height: 20),
          ],

          Text(
            'Transition duration: ${_transitionDurationMs.round()} ms',
            style: theme.textTheme.labelLarge,
          ),
          Slider(
            value: _transitionDurationMs,
            min: 100,
            max: 2000,
            divisions: 19,
            label: '${_transitionDurationMs.round()} ms',
            onChanged: (v) => setState(() => _transitionDurationMs = v),
          ),

          if (hasSize) ...[
            const SizedBox(height: 4),
            Text(
              '$sizeLabel: ${_size.toStringAsFixed(1)} px',
              style: theme.textTheme.labelLarge,
            ),
            Slider(
              value: _size.clamp(_minSizePx, _maxSizePx),
              min: _minSizePx,
              max: _maxSizePx,
              onChanged: (v) => setState(() => _size = v),
            ),
          ],

          const SizedBox(height: 12),
          Text('Cover color', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in _colorChoices)
                _ColorSwatch(
                  choice: choice,
                  selected: _color == choice.color,
                  onTap: () => setState(() => _color = choice.color),
                ),
            ],
          ),

          if (_color != null) ...[
            const SizedBox(height: 16),
            Text(
              'Cover duration: ${_coverDurationMs.round()} ms',
              style: theme.textTheme.labelLarge,
            ),
            Slider(
              value: _coverDurationMs.clamp(0.0, 3000.0),
              min: 0,
              max: 3000,
              divisions: 30,
              label: '${_coverDurationMs.round()} ms',
              onChanged: (v) => setState(() => _coverDurationMs = v),
            ),
            Text(
              'How long the screen stays at full cover, taken from within the '
              'transition duration. Clamped so each wipe still gets a share.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],

          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => widget.onTest(_currentConfig()),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Test transition'),
            style: FilledButton.styleFrom(
              backgroundColor: option.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _ColorChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final fill = choice.color;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: fill ?? Colors.transparent,
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: fill == null
                  ? Icon(
                      Icons.block,
                      size: 12,
                      color: theme.colorScheme.outline,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(choice.label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
