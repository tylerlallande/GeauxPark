import 'parking_locations.dart';
import 'campus_parking_locations.dart';

final sampleParkingDetails = <String, Map<String, dynamic>>{
  for (final location in campusParkingLocations)
    location.id: location.toDetails(),
  for (final entry in _details.entries)
    entry.key: {
      ...entry.value,
      'latitude': parkingLocations[entry.key]!.latitude,
      'longitude': parkingLocations[entry.key]!.longitude,
    },
};

const _details = <String, Map<String, dynamic>>{
  'welcome-center': {
    'lotId': 'welcome-center',
    'description': 'At Highland Road and Dalrymple Drive, the Welcome Center provides visitor parking passes, parking help, campus maps, and directions.',
    'hours': 'Metered parking: weekdays, 7:00 AM–8:00 PM. Campus parking and driving restrictions: weekdays, 7:00 AM–4:30 PM.',
    'eventRestrictions': r'Metered parking is $1.50 per hour. Temporary permits are $10 per day for eligible Zone 1, Zone 3, and All Zone lots. Always follow posted signs.',
    'amenities': [
      'Visitor parking passes',
      'Guest and conference parking arrangements',
      'Reserved VIP parking assistance',
      'Campus maps and directions',
      'Up to five courtesy permit days for eligible students and employees',
    ],
  },
  'union-square-garage': {
    'lotId': 'union-square-garage',
    'description': 'Visitor metered parking is available on floors 2–4 of Union Square Garage.',
    'hours': 'Metered parking is enforced weekdays, 7:00 AM–8:00 PM.',
    'eventRestrictions':
        'Event pricing and entry restrictions may apply on game days.',
    'amenities': ['Covered parking', 'Accessible spaces', 'Well lit'],
  },
  'west-stadium-lot': {
    'lotId': 'west-stadium-lot',
    'description': 'West Stadium Lot includes metered visitor parking. Check posted signs before leaving your vehicle.',
    'hours': 'Metered parking is enforced weekdays, 7:00 AM–8:00 PM.',
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
