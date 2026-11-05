import 'package:flutter/material.dart';

Future<bool> confirmRoadRoutingConsent(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Calculate driving directions?'),
      content: const Text(
        'GeauxPark will send your current location and the selected lot location '
        'to the public OSRM routing server (router.project-osrm.org) to find a '
        'road route and turn-by-turn steps.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Calculate route'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
