import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    assert(localizations != null, 'AppLocalizations not found — wrap app with localizationsDelegates');
    return localizations!;
  }
}
