import 'package:flutter/foundation.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/aws_api_service.dart';

enum AWSRegisterState {
  initial,
  registering,
  awaitingConfirmation,
  success,
  error,
}

class AWSRegisterCubit extends ChangeNotifier {
  final AuthService _authService;
  final AWSApiService _apiService;

  AWSRegisterState _state = AWSRegisterState.initial;
  String? _errorMessage;
  String? _successMessage;
  String? _pendingEmail;

  AWSRegisterCubit(this._authService, this._apiService);

  AWSRegisterState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get pendingEmail => _pendingEmail;
  bool get isLoading => _state == AWSRegisterState.registering;
  bool get isAwaitingConfirmation => _state == AWSRegisterState.awaitingConfirmation;

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? gymName,
  }) async {
    try {
      _setState(AWSRegisterState.registering);
      _clearMessages();

      final cognitoResult = await _apiService.registerUser(
        email: email,
        password: password,
        nombre: fullName,
        rol: role,
        nombreGimnasio: gymName,
      );

      if (cognitoResult != null) {
        _pendingEmail = email;
        _setState(AWSRegisterState.awaitingConfirmation);
        _setSuccessMessage(
          'Se ha enviado un código de confirmación a tu email. Por favor, revisa tu bandeja de entrada.',
        );
        return;
      }

      _setState(AWSRegisterState.success);
      _setSuccessMessage(
        '¡Registro completado exitosamente! Ya puedes iniciar sesión.',
      );
    } catch (e) {
      _handleRegistrationError(e);
    }
  }

  Future<void> confirmRegistration(String confirmationCode) async {
    if (_pendingEmail == null) {
      _setErrorMessage('No hay registro pendiente de confirmación');
      return;
    }

    try {
      _setState(AWSRegisterState.registering);
      _clearMessages();

      final result = await _authService.confirmSignUp(
        email: _pendingEmail!,
        confirmationCode: confirmationCode,
      );

      if (result) {
        _setState(AWSRegisterState.success);
        _setSuccessMessage(
          '¡Registro confirmado exitosamente! Ya puedes iniciar sesión.',
        );
        _pendingEmail = null;
      } else {
        _setErrorMessage('Error confirmando el registro. Verifica el código.');
        _setState(AWSRegisterState.error);
      }
    } catch (e) {
      _setErrorMessage('Error confirmando el registro: ${e.toString()}');
      _setState(AWSRegisterState.error);
    }
  }

  void setPendingEmail(String email) {
    _pendingEmail = email;
    notifyListeners();
  }

  Future<void> resendConfirmationCode() async {
    if (_pendingEmail == null) {
      _setErrorMessage('No hay registro pendiente de confirmación');
      return;
    }

    try {
      await _authService.resendSignUpCode(_pendingEmail!);
      _setSuccessMessage('Código de confirmación reenviado. Revisa tu email.');
    } catch (e) {
      _setErrorMessage('Error reenviando código: ${e.toString()}');
    }
  }

  Future<void> _registerInBackend(
    String email,
    String password,
    String fullName,
    String role,
    String? gymName,
  ) async {
    try {
      final response = await _apiService.registerUser(
        email: email,
        password: password,
        nombre: fullName,
        rol: role,
        nombreGimnasio: gymName,
      );

      _setState(AWSRegisterState.success);
      _setSuccessMessage(
        '¡Registro completado exitosamente! Ya puedes iniciar sesión.',
      );
    } catch (e) {
      _setState(AWSRegisterState.success);
      _setSuccessMessage(
        'Registro en Cognito exitoso. Inicia sesión para continuar.',
      );
    }
  }

  void _handleCognitoError(Exception e) {
    String userMessage;
    final message = e.toString().toLowerCase();

    if (message.contains('an account with the given email already exists')) {
      userMessage = 'Ya existe una cuenta con este email. Intenta iniciar sesión.';
    } else if (message.contains('password did not conform with policy')) {
      userMessage = 'La contraseña no cumple con los requisitos de seguridad.';
    } else if (message.contains('invalid verification code provided')) {
      userMessage = 'Código de verificación inválido. Verifica e intenta de nuevo.';
    } else if (message.contains('user cannot be confirmed')) {
      userMessage = 'El usuario ya está confirmado. Puedes iniciar sesión.';
    } else {
      userMessage = 'Error de autenticación: ${e.toString()}';
    }

    _setErrorMessage(userMessage);
    _setState(AWSRegisterState.error);
  }

  void _handleRegistrationError(dynamic e) {
    String userMessage;
    final message = e.toString().toLowerCase();

    if (message.contains('email already exists') || message.contains('ya existe')) {
      userMessage = 'Ya existe una cuenta con este email. Intenta iniciar sesión.';
    } else if (message.contains('password') && message.contains('policy')) {
      userMessage = 'La contraseña no cumple con los requisitos de seguridad.';
    } else if (message.contains('validation') || message.contains('validación')) {
      userMessage = 'Datos de registro inválidos. Verifica la información.';
    } else if (message.contains('gym') && message.contains('name')) {
      userMessage = 'El nombre del gimnasio es requerido para administradores.';
    } else if (message.contains('network') || message.contains('connection')) {
      userMessage = 'Error de conexión. Verifica tu internet e intenta de nuevo.';
    } else {
      userMessage = 'Error durante el registro: ${e.toString()}';
    }

    _setErrorMessage(userMessage);
    _setState(AWSRegisterState.error);
  }

  void reset() {
    _setState(AWSRegisterState.initial);
    _clearMessages();
    _pendingEmail = null;
  }

  void _setState(AWSRegisterState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}