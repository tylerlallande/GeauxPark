import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../server/lib/parking_server.dart';

void main() {
  final source = jsonEncode([
    {
      'id': 'student-lot',
      'permitTypes': ['student'],
      'gameDay': true,
    },
    {
      'id': 'visitor-lot',
      'permitTypes': ['visitor'],
      'gameDay': false,
    },
  ]);
  final store = LotStore.fromJson(source);

  test('filters lots by game-day status and permit type', () {
    expect(store.find(gameDay: true).single['id'], 'student-lot');
    expect(store.find(permitType: 'VISITOR').single['id'], 'visitor-lot');
  });

  test('returns a lot by id and null for an unknown id', () {
    expect(store.findById('student-lot')?['gameDay'], isTrue);
    expect(store.findById('missing'), isNull);
  });
}
