import 'package:flutter/material.dart';

/// What the camera is doing right now, from the user's point of view.
enum ScanPhase {
  /// The camera was asked to start and has not delivered frames yet.
  starting,

  /// Frames are being analysed: any code in front of the lens will be read.
  scanning,

  /// The user stopped the reading, or a result is being shown.
  paused,

  /// The camera could not start: no permission, no device, or an error.
  unavailable,
}

/// Permanent, always-visible answer to "is it scanning right now?".
///
/// The first version of the scanner showed only a hint text, so a camera that
/// silently failed to start looked exactly like a camera waiting for a code.
/// The moving bar is the part that makes the difference legible at a glance,
/// and the action button gives the user a way out without leaving the screen.
class ScanStatusBar extends StatelessWidget {
  const ScanStatusBar({
    required this.phase,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.animate = true,
    super.key,
  });

  final ScanPhase phase;

  /// Secondary line: what the user should do next.
  final String message;

  final String? actionLabel;
  final VoidCallback? onAction;

  /// False when the user asked for reduced motion: the bar is then drawn
  /// filled and still, so the state is still readable without movement.
  final bool animate;

  String get _title => switch (phase) {
        ScanPhase.starting => 'Preparando inspección…',
        ScanPhase.scanning => 'Inspección activa',
        ScanPhase.paused => 'Inspección en pausa',
        ScanPhase.unavailable => 'Sensor no disponible',
      };

  IconData get _icon => switch (phase) {
        ScanPhase.starting => Icons.hourglass_top_outlined,
        ScanPhase.scanning => Icons.qr_code_scanner,
        ScanPhase.paused => Icons.pause_circle_outline,
        ScanPhase.unavailable => Icons.videocam_off_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = switch (phase) {
      ScanPhase.starting || ScanPhase.scanning => colors.primary,
      ScanPhase.paused => Colors.white,
      ScanPhase.unavailable => colors.error,
    };
    return Semantics(
      liveRegion: true,
      label: '$_title. $message',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF07120F).withValues(alpha: 0.9),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(11)),
                  child: Icon(_icon, color: accent, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        phase == ScanPhase.scanning ? 'QR · ANÁLISIS LOCAL' : 'ROOTCAUSE SENSOR',
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            _ScanProgressBar(phase: phase, accent: accent, animate: animate),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(phase == ScanPhase.paused ? Icons.play_arrow : Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The horizontal bar itself: it moves only while the camera is really
/// analysing frames.
class _ScanProgressBar extends StatelessWidget {
  const _ScanProgressBar({required this.phase, required this.accent, required this.animate});

  final ScanPhase phase;
  final Color accent;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final bool busy = phase == ScanPhase.starting || phase == ScanPhase.scanning;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        // A null value is the moving, indeterminate bar; a fixed value draws a
        // still bar, which is what a paused camera or reduced motion needs.
        value: busy && animate ? null : (busy ? 1 : 0),
        minHeight: 6,
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    );
  }
}
