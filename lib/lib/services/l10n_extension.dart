import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n.dart';

// Extension to easily access translations from any widget
extension L10nExtension on BuildContext {
  // Get translation without listening (safe for callbacks/events)
  String tr(String key) {
    return Provider.of<L10n>(this, listen: false).tr(key);
  }

  // Get L10n instance without listening (for callbacks/events)
  L10n get l10n => Provider.of<L10n>(this, listen: false);
}
