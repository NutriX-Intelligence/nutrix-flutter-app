import 'package:flutter/material.dart';

/// Spacing scale. Codifies the 4pt rhythm the app already mostly follows —
/// use these instead of ad-hoc `SizedBox(height: 10)` / `14` / `6` values.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

/// Corner radius scale. `card`/`lg` match `CardThemeData` in both themes —
/// keep them equal so nothing changes shape when the theme toggles.
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Depth. One shadow for a resting card, one for an overlay/sheet — the app
/// previously had 7 one-off `BoxShadow`s with 4 different blur radii.
class AppElevation {
  static List<BoxShadow> card(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.28)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> sheet(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
      ];
}
