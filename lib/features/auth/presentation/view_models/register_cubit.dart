import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository_impl.dart';

class RegisterCubit extends ChangeNotifier {
  final AuthRepositoryImpl _authRepository;

  RegisterCubit(this._authRepository);

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isRegistered = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isRegistered => _isRegistered;

  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    print('INICIANDO REGISTRO...');
    print('Email: $email');
    print('Nombre: $nombre');
    print('Rol: $rol');

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _isRegistered = false;
    notifyListeners();

    try {
      print('Enviando datos al backend...');

      final result = await _authRepository.register(
        email: email,
        password: password,
        nombre: nombre,
        rol: rol,
      );

      print('REGISTRO EXITOSO!');
      print('ID Usuario: ${result['userId']}');
      print('Mensaje: ${result['message']}');

      _successMessage = result['message'];
      _isRegistered = true;
      _errorMessage = null;
    } catch (e) {
      print('ERROR EN REGISTRO: ${e.toString()}');
      print('Detalles del error: $e');

      _errorMessage = _parseError(e.toString());
      _successMessage = null;
      _isRegistered = false;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('Registro completado (loading: $_isLoading)');
    }
  }

  String _parseError(String error) {
    if (error.contains('400')) {
      return 'Datos inválidos. Verifica tu información.';
    } else if (error.contains('409')) {
      return 'Este email ya está registrado.';
    } else if (error.contains('401')) {
      return 'Clave de gimnasio incorrecta.';
    } else if (error.contains('Connection')) {
      return 'Error de conexión. Verifica tu internet.';
    } else {
      return 'Error de registro: $error';
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _isRegistered = false;
    notifyListeners();
  }
}