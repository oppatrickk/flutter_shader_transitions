import 'package:flutter/material.dart';
import 'package:shader_transitions/shader_transitions.dart';

import 'destination_screen.dart';

// Below this width (logical px) the gallery uses page navigation instead of
// the two-column master/detail layout.
const double wideLayoutBreakpoint = 720;

/// Which sealed [ShaderTransition] family a catalogue entry builds.
enum DemoType { diamond, circle, wipe, clock, polygon, dissolve, fade, bars }

class TypeOption {
  const TypeOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.accent,
    required this.description,
  });

  final DemoType type;
  final String label;
  final IconData icon;
  final Color accent;
  final String description;
}

const List<TypeOption> types = [
  TypeOption(
    type: DemoType.diamond,
    label: 'Diamond',
    icon: Icons.diamond_outlined,
    accent: Color(0xFF7C4DFF),
    description: 'Grid of diamonds sweeps across the screen.',
  ),
  TypeOption(
    type: DemoType.circle,
    label: 'Circle iris',
    icon: Icons.radio_button_unchecked,
    accent: Color(0xFF00BCD4),
    description: 'Circular iris reveal from any origin.',
  ),
  TypeOption(
    type: DemoType.wipe,
    label: 'Wipe',
    icon: Icons.swipe_right_outlined,
    accent: Color(0xFF00897B),
    description: 'Linear feathered wipe in any of 8 directions.',
  ),
  TypeOption(
    type: DemoType.clock,
    label: 'Clock',
    icon: Icons.access_time,
    accent: Color(0xFFEF6C00),
    description: 'Radial sweep, optionally fanned into sectors.',
  ),
  TypeOption(
    type: DemoType.polygon,
    label: 'Polygon',
    icon: Icons.pentagon_outlined,
    accent: Color(0xFFAD1457),
    description: 'Regular-polygon iris; high sides ≈ circle.',
  ),
  TypeOption(
    type: DemoType.dissolve,
    label: 'Dissolve',
    icon: Icons.grain,
    accent: Color(0xFF455A64),
    description: 'Noise-grain dissolve; grain controls softness.',
  ),
  TypeOption(
    type: DemoType.fade,
    label: 'Fade',
    icon: Icons.gradient,
    accent: Color(0xFF5E35B1),
    description: 'Uniform shader cross-fade.',
  ),
  TypeOption(
    type: DemoType.bars,
    label: 'Bars',
    icon: Icons.view_week_outlined,
    accent: Color(0xFF00838F),
    description: 'Venetian-blind reveal; count parallel bars.',
  ),
];

TypeOption optionFor(DemoType t) => types.firstWhere((o) => o.type == t);

// ---------------------------------------------------------------------------
// Gallery screen — layout-aware shell.
// ---------------------------------------------------------------------------

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  DemoType? _selectedType;

  void _push(BuildContext context, ShaderTransition transition) {
    Navigator.of(context).push(
      ShaderPageRoute(
        page: DestinationScreen(transition: transition),
        transition: transition,
      ),
    );
  }

  void _openEditorPage(BuildContext context, DemoType type) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => EditorPage(type: type)),
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
          return constraints.maxWidth >= wideLayoutBreakpoint
              ? _buildWide(context)
              : _buildNarrow(context);
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
          child: TypeList(
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
              ? const EmptyState()
              : TransitionEditor(
                  key: ValueKey(_selectedType),
                  type: _selectedType!,
                  onTest: (t) => _push(context, t),
                ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return TypeList(
      selected: null,
      onSelect: (t) => _openEditorPage(context, t),
    );
  }
}

// ---------------------------------------------------------------------------
// Left-column type list
// ---------------------------------------------------------------------------

class TypeList extends StatelessWidget {
  const TypeList({super.key, required this.selected, required this.onSelect});

  final DemoType? selected;
  final ValueChanged<DemoType> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: types.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final option = types[index];
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
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            option.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          selected: selected == option.type,
          selectedTileColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onSelect(option.type),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

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

class EditorPage extends StatelessWidget {
  const EditorPage({super.key, required this.type});

  final DemoType type;

  @override
  Widget build(BuildContext context) {
    final option = optionFor(type);
    return Scaffold(
      appBar: AppBar(
        title: Text(option.label),
        centerTitle: true,
        backgroundColor: option.accent,
        foregroundColor: Colors.white,
      ),
      body: TransitionEditor(
        type: type,
        onTest: (t) {
          Navigator.of(context).push(
            ShaderPageRoute(
              page: DestinationScreen(transition: t),
              transition: t,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor
// ---------------------------------------------------------------------------

class ColorChoice {
  const ColorChoice(this.label, this.color);
  final String label;
  final Color? color;
}

const List<ColorChoice> colorChoices = [
  ColorChoice('None', null),
  ColorChoice('Black', Color(0xFF000000)),
  ColorChoice('White', Color(0xFFFFFFFF)),
  ColorChoice('Indigo', Color(0xFF1A237E)),
  ColorChoice('Red', Color(0xFFC62828)),
];

String directionLabel(SweepDirection d) => switch (d) {
      SweepDirection.topLeftToBottomRight => '↘ Top-left → Bottom-right',
      SweepDirection.bottomRightToTopLeft => '↖ Bottom-right → Top-left',
      SweepDirection.leftToRight => '→ Left → Right',
      SweepDirection.rightToLeft => '← Right → Left',
      SweepDirection.topToBottom => '↓ Top → Bottom',
      SweepDirection.bottomToTop => '↑ Bottom → Top',
      SweepDirection.topRightToBottomLeft => '↙ Top-right → Bottom-left',
      SweepDirection.bottomLeftToTopRight => '↗ Bottom-left → Top-right',
    };

class TransitionEditor extends StatefulWidget {
  const TransitionEditor({
    super.key,
    required this.type,
    required this.onTest,
  });

  final DemoType type;
  final ValueChanged<ShaderTransition> onTest;

  @override
  State<TransitionEditor> createState() => _TransitionEditorState();
}

class _TransitionEditorState extends State<TransitionEditor> {
  SweepDirection _direction = SweepDirection.leftToRight;
  double _durationMs = 700;
  double _size = 40; // cell size (diamond) / softness (wipe)
  int _count = 6; // sectors (clock) / sides (polygon)
  bool _invert = false;
  Color? _color;
  double _coverHoldMs = 0;

  static const double _minSizePx = 1.0;
  static const double _maxSizePx = 100.0;

  @override
  void initState() {
    super.initState();
    switch (widget.type) {
      case DemoType.diamond:
        _direction = SweepDirection.topLeftToBottomRight;
        _durationMs = 800;
        _size = 40;
      case DemoType.circle:
        _durationMs = 700;
      case DemoType.wipe:
        _direction = SweepDirection.leftToRight;
        _durationMs = 600;
        _size = 6;
      case DemoType.clock:
        _durationMs = 700;
        _count = 1;
      case DemoType.polygon:
        _durationMs = 700;
        _count = 6;
      case DemoType.dissolve:
        _durationMs = 600;
        _size = 8;
      case DemoType.fade:
        _durationMs = 400;
      case DemoType.bars:
        _direction = SweepDirection.leftToRight;
        _durationMs = 600;
        _size = 4;
        _count = 6;
    }
  }

  bool get _hasCount =>
      widget.type == DemoType.clock ||
      widget.type == DemoType.polygon ||
      widget.type == DemoType.bars;

  ShaderTransition _currentTransition() {
    final duration = Duration(milliseconds: _durationMs.round());
    final cover = _color == null
        ? null
        : TransitionCover(
            color: _color!,
            hold: Duration(milliseconds: _coverHoldMs.round()),
          );
    return switch (widget.type) {
      DemoType.diamond => DiamondTransition(
          direction: _direction,
          duration: duration,
          cellSize: _size,
          invert: _invert,
          cover: cover,
        ),
      DemoType.circle => CircleTransition(
          duration: duration,
          invert: _invert,
          cover: cover,
        ),
      DemoType.wipe => WipeTransition(
          direction: _direction,
          duration: duration,
          softness: _size,
          invert: _invert,
          cover: cover,
        ),
      DemoType.clock => ClockTransition(
          duration: duration,
          sectors: _count,
          invert: _invert,
          cover: cover,
        ),
      DemoType.polygon => PolygonTransition(
          duration: duration,
          sides: _count,
          invert: _invert,
          cover: cover,
        ),
      DemoType.dissolve => DissolveTransition(
          duration: duration,
          grain: _size,
          invert: _invert,
          cover: cover,
        ),
      DemoType.fade => FadeShaderTransition(
          duration: duration,
          invert: _invert,
          cover: cover,
        ),
      DemoType.bars => BarsTransition(
          direction: _direction,
          duration: duration,
          count: _count,
          softness: _size,
          invert: _invert,
          cover: cover,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final option = optionFor(widget.type);
    final hasDirection = widget.type == DemoType.diamond ||
        widget.type == DemoType.wipe ||
        widget.type == DemoType.bars;
    final hasSize = widget.type == DemoType.diamond ||
        widget.type == DemoType.wipe ||
        widget.type == DemoType.dissolve ||
        widget.type == DemoType.bars;
    final sizeLabel = switch (widget.type) {
      DemoType.diamond => 'Cell size',
      DemoType.dissolve => 'Grain',
      _ => 'Softness',
    };
    final countLabel = switch (widget.type) {
      DemoType.clock => 'Sectors',
      DemoType.bars => 'Bars',
      _ => 'Sides',
    };
    final countMin = widget.type == DemoType.polygon ? 3 : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: option.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: option.accent.withValues(alpha: 0.3)),
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
                      Text(option.description,
                          style: theme.textTheme.bodySmall),
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
                        child: Text(directionLabel(d)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _direction = v);
              },
            ),
            const SizedBox(height: 20),
          ],
          Text('Duration: ${_durationMs.round()} ms',
              style: theme.textTheme.labelLarge),
          Slider(
            value: _durationMs,
            min: 100,
            max: 2000,
            divisions: 19,
            label: '${_durationMs.round()} ms',
            onChanged: (v) => setState(() => _durationMs = v),
          ),
          if (hasSize) ...[
            const SizedBox(height: 4),
            Text('$sizeLabel: ${_size.toStringAsFixed(1)} px',
                style: theme.textTheme.labelLarge),
            Slider(
              value: _size.clamp(_minSizePx, _maxSizePx),
              min: _minSizePx,
              max: _maxSizePx,
              onChanged: (v) => setState(() => _size = v),
            ),
          ],
          if (_hasCount) ...[
            const SizedBox(height: 4),
            Text('$countLabel: $_count', style: theme.textTheme.labelLarge),
            Slider(
              value: _count.toDouble().clamp(countMin.toDouble(), 12.0),
              min: countMin.toDouble(),
              max: 12,
              divisions: 12 - countMin,
              label: '$_count',
              onChanged: (v) => setState(() => _count = v.round()),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Invert'),
            subtitle: Text(
              switch (widget.type) {
                DemoType.circle ||
                DemoType.polygon =>
                  'Contracting instead of expanding',
                DemoType.clock => 'Counter-clockwise sweep',
                _ => 'Reverse which side reveals first',
              },
              style: theme.textTheme.bodySmall,
            ),
            value: _invert,
            onChanged: (v) => setState(() => _invert = v),
          ),
          const SizedBox(height: 8),
          Text('Cover color', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in colorChoices)
                ColorChip(
                  choice: choice,
                  selected: _color == choice.color,
                  onTap: () => setState(() => _color = choice.color),
                ),
            ],
          ),
          if (_color != null) ...[
            const SizedBox(height: 16),
            Text('Cover hold: ${_coverHoldMs.round()} ms',
                style: theme.textTheme.labelLarge),
            Slider(
              value: _coverHoldMs.clamp(0.0, 3000.0),
              min: 0,
              max: 3000,
              divisions: 30,
              label: '${_coverHoldMs.round()} ms',
              onChanged: (v) => setState(() => _coverHoldMs = v),
            ),
            Text(
              'Time held at full cover, taken from within the duration. '
              'Clamped so each wipe still gets a share.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => widget.onTest(_currentTransition()),
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

class ColorChip extends StatelessWidget {
  const ColorChip({
    super.key,
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final ColorChoice choice;
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
                border:
                    Border.all(color: theme.colorScheme.outline, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: fill == null
                  ? Icon(Icons.block,
                      size: 12, color: theme.colorScheme.outline)
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
