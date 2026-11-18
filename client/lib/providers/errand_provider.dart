import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/errand.dart';
import '../models/user.dart';

enum ListState { initial, loading, success, failure }

class ErrandProvider extends ChangeNotifier {
  ErrandProvider(this._api);

  final ApiClient _api;

  List<Errand> _open = [];
  List<Errand> _mine = [];
  List<Errand> _assigned = [];
  ListState _openState = ListState.initial;
  ListState _mineState = ListState.initial;
  ListState _assignedState = ListState.initial;
  String? _openError;
  String? _mineError;
  String? _assignedError;
  bool _actionBusy = false;

  List<Errand> get open => List.unmodifiable(_open);
  List<Errand> get mine => List.unmodifiable(_mine);
  List<Errand> get assigned => List.unmodifiable(_assigned);
  ListState get openState => _openState;
  ListState get mineState => _mineState;
  ListState get assignedState => _assignedState;
  String? get openError => _openError;
  String? get mineError => _mineError;
  String? get assignedError => _assignedError;
  bool get actionBusy => _actionBusy;

  Future<void> refreshFor(UserRole role) async {
    if (role == UserRole.runner) {
      await Future.wait([refreshOpen(), refreshAssigned()]);
    } else {
      await refreshMine();
    }
  }

  Future<void> refreshOpen() => _load(
    fetch: _api.openErrands,
    setItems: (items) => _open = items,
    setState: (state) => _openState = state,
    setError: (message) => _openError = message,
  );

  Future<void> refreshMine() => _load(
    fetch: _api.myErrands,
    setItems: (items) => _mine = items,
    setState: (state) => _mineState = state,
    setError: (message) => _mineError = message,
  );

  Future<void> refreshAssigned() => _load(
    fetch: _api.assignedErrands,
    setItems: (items) => _assigned = items,
    setState: (state) => _assignedState = state,
    setError: (message) => _assignedError = message,
  );

  Future<void> _load({
    required Future<List<Errand>> Function() fetch,
    required void Function(List<Errand>) setItems,
    required void Function(ListState) setState,
    required void Function(String?) setError,
  }) async {
    setState(ListState.loading);
    setError(null);
    notifyListeners();
    try {
      setItems(await fetch());
      setState(ListState.success);
    } on ApiException catch (error) {
      setError(error.message);
      setState(ListState.failure);
    } catch (_) {
      setError('Something went wrong. Please try again.');
      setState(ListState.failure);
    }
    notifyListeners();
  }

  Future<Errand> createErrand({
    required String title,
    required String description,
    required String pickupAddress,
    required String dropoffAddress,
  }) async {
    final created = await _api.createErrand(
      title: title,
      description: description,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
    );
    await refreshMine();
    return created;
  }

  Future<Errand> performAction({
    required Errand errand,
    required String action,
    required UserRole role,
  }) async {
    _actionBusy = true;
    notifyListeners();
    try {
      final updated = await _api.errandAction(errand.id, action);
      await refreshFor(role);
      return updated;
    } finally {
      _actionBusy = false;
      notifyListeners();
    }
  }
}
