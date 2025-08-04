import 'package:capbox/features/auth/domain/use_cases/login_user_usecase.dart';
import 'package:capbox/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginCubit extends ChangeNotifier {
  final LoginUserUseCase _loginUserUseCase;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  LoginCubit(this._loginUserUseCase);

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _loginUserUseCase(email: email, password: password);
      _currentUser = user;

      await _secureStorage.write(key: 'auth_token', value: user.token);
      await _secureStorage.write(key: 'user_id', value: user.id);
      await _secureStorage.write(key: 'user_role', value: user.role.name);
      await _secureStorage.write(key: 'user_email', value: user.email);
      await _secureStorage.write(key: 'user_name', value: user.name);
    } catch (e) {
      _errorMessage = 'Error de autenticación: ${e.toString()}';
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _secureStorage.deleteAll();
    notifyListeners();
  }

  String getHomeRoute() {
    if (_currentUser == null) return '/';

    switch (_currentUser!.role) {
      case UserRole.athlete:
        return '/boxer-home';
      case UserRole.coach:
        return '/coach-home';
      case UserRole.admin:
        return '/admin-home';
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final userId = await _secureStorage.read(key: 'user_id');
      final userRole = await _secureStorage.read(key: 'user_role');
      final userEmail = await _secureStorage.read(key: 'user_email');
      final userName = await _secureStorage.read(key: 'user_name');

      if (token != null &&
          userId != null &&
          userRole != null &&
          userEmail != null &&
          userName != null) {
        _currentUser = User(
          id: userId,
          email: userEmail,
          name: userName,
          role: _parseStoredRole(userRole),
          createdAt: DateTime.now(),
          token: token,
        );
        _errorMessage = null;
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _currentUser = null;
      _errorMessage = 'Error al verificar autenticación';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UserRole _parseStoredRole(String role) {
    switch (role.toLowerCase()) {
      case 'athlete':
        return UserRole.athlete;
      case 'coach':
        return UserRole.coach;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.athlete;
    }
  }
}