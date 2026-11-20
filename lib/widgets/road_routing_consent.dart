import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

Future<bool> confirmRoadRoutingConsent(BuildContext context) async {
  final strings = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(strings.calculateDirectionsTitle),
      content: Text(strings.calculateDirectionsMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.notNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(strings.calculateRoute),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
