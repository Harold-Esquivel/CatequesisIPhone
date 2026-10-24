import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'borgona_theme.dart';

class ModuleNavigation extends StatefulWidget {
  const ModuleNavigation({
    super.key,
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(labels.length == icons.length),
       assert(labels.length > 1);
  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  @override
  State<ModuleNavigation> createState() => _ModuleNavigationState();
}

class _ModuleNavigationState extends State<ModuleNavigation>
    with SingleTickerProviderStateMixin {
  static const _spring = Cubic(.34, 1.56, .64, 1);
  late final AnimationController _controller;
  late int _settled;
  int? _destination;
  int? _queued;
  int _from = 0;
  int _durationMs = 550;
  @override
  void initState() {
    super.initState();
    _settled = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(ModuleNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        !_controller.isAnimating) {
      _settled = widget.selectedIndex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      setState(() {
        _settled = index;
        _destination = null;
        _queued = null;
      });
      widget.onChanged(index);
      return;
    }
    if (_controller.isAnimating) {
      _queued = index;
      return;
    }
    if (index == _settled) return;
    _from = _settled;
    _durationMs = 550 + math.min((index - _from).abs() - 1, 3) * 50;
    setState(() {
      _destination = index;
    });
    _controller.duration = Duration(milliseconds: _durationMs);
    _controller.forward(from: 0);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _destination == null) return;
    final landed = _destination!;
    final next = _queued;
    _queued = null;
    setState(() {
      _settled = landed;
      _destination = null;
    });
    widget.onChanged(landed);
    if (next != null && next != landed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _select(next);
      });
    }
  }

  double _progress(double elapsed, double start, double duration) =>
      ((elapsed - start) / duration).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: DecoratedBox(
        decoration: NeoDecoration(borderRadius: BorderRadius.circular(32)),
        child: SizedBox(
          height: 80,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              children: List.generate(widget.labels.length, (index) {
                final elapsed = _controller.value * _durationMs;
                double active = index == _settled ? 1 : 0;
                double lift = 0;
                if (_destination != null) {
                  final direction = (_destination! - _from).sign;
                  final step = (index - _from) * direction;
                  final distance = (_destination! - _from).abs();
                  active = index == _from ? 1 - _progress(elapsed, 0, 120) : 0;
                  if (step > 0 && step < distance) {
                    final phase = _progress(
                      elapsed,
                      100 + (step - 1) * 90,
                      240,
                    );
                    lift = phase < .5
                        ? _spring.transform(phase * 2)
                        : 1 - Curves.easeInOut.transform((phase - .5) * 2);
                  }
                  if (index == _destination) {
                    active = _progress(elapsed, _durationMs - 210, 210);
                    lift = math.sin(active * math.pi) * .35;
                  }
                }
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: index == _settled,
                    label: widget.labels[index],
                    child: Tooltip(
                      message: widget.labels[index],
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: ValueKey('module-tap-$index'),
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _select(index),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.translate(
                                key: ValueKey('module-lift-$index'),
                                offset: Offset(0, -18 * lift),
                                child: Transform.scale(
                                  scale: 1 + .18 * lift,
                                  child: _ModuleIcon(
                                    icon: widget.icons[index],
                                    active: active,
                                    lift: lift,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              ExcludeSemantics(
                                child: Text(
                                  widget.labels[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.2,
                                    fontWeight: active > .5
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active > .5
                                        ? Borgona.burgundy
                                        : Borgona.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ModuleIcon extends StatelessWidget {
  const _ModuleIcon({
    required this.icon,
    required this.active,
    required this.lift,
  });
  final IconData icon;
  final double active;
  final double lift;
  @override
  Widget build(BuildContext context) {
    final raised = active > 0 || lift > 0;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(
          raised ? Borgona.surface : Borgona.sunken,
          Borgona.burgundy,
          active,
        ),
        border: active > 0
            ? Border.all(
                color: Borgona.burgundy.withValues(alpha: .4 * active),
                width: 1.5,
              )
            : null,
        boxShadow: raised
            ? (active > 0 ? Borgona.active : Borgona.raised)
            : null,
      ),
      child: CustomPaint(
        foregroundPainter: raised
            ? null
            : _InsetPainter(dark: Borgona.darkMode.value),
        child: Icon(
          icon,
          size: 23,
          color: Color.lerp(Borgona.secondary, Colors.white, active),
        ),
      ),
    );
  }
}

class _InsetPainter extends CustomPainter {
  const _InsetPainter({required this.dark});
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final circle = Path()..addOval(bounds);
    canvas.save();
    canvas.clipPath(circle);
    for (final entry in [
      (
        const Offset(5, 5),
        dark ? const Color(0x99040810) : const Color(0x260F1C2E),
      ),
      (
        const Offset(-5, -5),
        dark ? const Color(0x503E536F) : const Color(0xD9FFFFFF),
      ),
    ]) {
      final shadow = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(bounds.inflate(40))
        ..addOval(bounds.shift(entry.$1));
      canvas.drawPath(
        shadow,
        Paint()
          ..color = entry.$2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetPainter oldDelegate) => oldDelegate.dark != dark;
}
