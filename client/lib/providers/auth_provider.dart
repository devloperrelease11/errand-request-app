import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

enum AuthState { initial, restoring, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  AuthState _state = AuthState.initial;
  User? _user;
  String? _error;
  bool _busy = false;

  AuthState get state => _state;
  User? get user => _user;
  String? get error => _error;
  bool get busy => _busy;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    if (_state != AuthState.initial) return;
    _state = AuthState.restoring;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null || token.isEmpty) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }
      _api.setToken(token);
      final user = await _api.me();
      _user = user;
      _state = AuthState.authenticated;
    } on ApiException catch (error) {
      await _storage.clearToken();
      _api.setToken(null);
      _error = error.isUnauthorized ? null : error.message;
      _state = AuthState.unauthenticated;
    } catch (_) {
      _api.setToken(null);
      _error = 'Could not restore your session. Please sign in again.';
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _api.login(email: email.trim(), password: password);
      _api.setToken(token);
      final user = await _api.me();
      await _storage.saveToken(token);
      _user = user;
      _state = AuthState.authenticated;
    } on ApiException catch (error) {
      _api.setToken(null);
      _error = error.message;
      rethrow;
    } catch (_) {
      _api.setToken(null);
      _error = 'Unable to sign in. Check your connection and try again.';
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _api.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      await login(email: email, password: password);
    } on ApiException catch (error) {
      _error = error.message;
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _busy = true;
    notifyListeners();
    try {
      await _api.logout();
    } catch (_) {
      _error = null;
    }
    await _storage.clearToken();
    _api.setToken(null);
    _user = null;
    _error = null;
    _state = AuthState.unauthenticated;
    _busy = false;
    notifyListeners();
  }
}
