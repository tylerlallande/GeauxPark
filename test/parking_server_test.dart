// The server contract is tested from its standalone server directory.
// ignore_for_file: avoid_relative_lib_imports

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../server/lib/parking_server.dart';

void main() {
  final source = jsonEncode([
    {
      'id': 'student-lot',
      'permitTypes': ['commuter'],
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
    expect(store.find(permitType: 'COMMUTER').single['id'], 'student-lot');
  });

  test('returns a lot by id and null for an unknown id', () {
    expect(store.findById('student-lot')?['gameDay'], isTrue);
    expect(store.findById('missing'), isNull);
  });
}
