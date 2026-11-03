import 'parking_locations.dart';

final sampleParkingDetails = <String, Map<String, dynamic>>{
  for (final entry in _details.entries)
    entry.key: {
      ...entry.value,
      'latitude': parkingLocations[entry.key]!.latitude,
      'longitude': parkingLocations[entry.key]!.longitude,
    },
};

const _details = <String, Map<String, dynamic>>{
  'union-square-garage': {
    'lotId': 'union-square-garage',
    'description':
        'Covered parking near the Student Union with convenient campus access.',
    'hours': 'Open daily, 6:00 AM–11:00 PM',
    'eventRestrictions':
        'Event pricing and entry restrictions may apply on game days.',
    'amenities': ['Covered parking', 'Accessible spaces', 'Well lit'],
  },
  'west-stadium-lot': {
    'lotId': 'west-stadium-lot',
    'description': 'Surface parking within walking distance of Tiger Stadium.',
    'hours': 'Hours vary by campus event',
    'eventRestrictions': 'A valid event permit may be required before kickoff.',
    'amenities': ['Accessible spaces', 'Event shuttle nearby'],
  },
  'nicholson-gateway': {
    'lotId': 'nicholson-gateway',
    'description':
        'Parking near Nicholson Gateway with access to campus transit routes.',
    'hours': 'Open daily; posted restrictions apply',
    'amenities': ['Campus transit nearby'],
  },
};
