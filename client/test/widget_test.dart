import 'package:flutter_test/flutter_test.dart';

import 'package:erand_client/models/errand.dart';
import 'package:erand_client/models/user.dart';

void main() {
  test('errand statuses map from API values', () {
    expect(ErrandStatus.fromWire('Open'), ErrandStatus.open);
    expect(ErrandStatus.fromWire('In Progress'), ErrandStatus.inProgress);
    expect(ErrandStatus.fromWire('Completed').isFinal, isTrue);
    expect(ErrandStatus.fromWire('Cancelled').isFinal, isTrue);
    expect(ErrandStatus.fromWire('Accepted').isFinal, isFalse);
  });

  test('user roles map from API values', () {
    expect(UserRole.fromWire('requester'), UserRole.requester);
    expect(UserRole.fromWire('runner'), UserRole.runner);
    expect(UserRole.runner.wireValue, 'runner');
  });

  test('errand parses server payload and applies optimistic status updates', () {
    final errand = Errand.fromJson({
      'id': 'errand-1',
      'requester_id': 'user-1',
      'runner_id': null,
      'title': 'Parcel pickup',
      'description': 'Collect the parcel.',
      'pickup_address': 'Store',
      'dropoff_address': 'Home',
      'status': 'Open',
      'created_at': '2026-01-01T10:00:00Z',
      'updated_at': '2026-01-01T10:00:00Z',
      'accepted_at': null,
      'completed_at': null,
    });

    expect(errand.status, ErrandStatus.open);
    expect(errand.runnerId, isNull);
    expect(errand.copyWith(status: ErrandStatus.accepted).status, ErrandStatus.accepted);
  });
}
