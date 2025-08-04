import 'package:flutter/foundation.dart';
import '../../../../core/services/aws_api_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_display_service.dart';

enum GymKeyActivationState { initial, loading, activated, error }

class GymKeyActivationCubit extends ChangeNotifier {
  final AWSApiService _apiService;
  final AuthService _authService;

  GymKeyActivationState _state = GymKeyActivationState.initial;
  String? _errorMessage;
  bool _isActivated = false;

  GymKeyActivationCubit(this._apiService, this._authService);

  GymKeyActivationState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == GymKeyActivationState.loading;
  bool get isActivated => _isActivated;
  bool get hasError => _state == GymKeyActivationState.error;

  Future<void> activateWithGymKey(String gymKey) async {
    try {
      _setState(GymKeyActivationState.loading);
      _clearError();

      await _apiService.linkAccountToGym(gymKey);

      UserDisplayService.clearGlobalCache();

      _isActivated = true;
      _setState(GymKeyActivationState.activated);
    } catch (e) {
      String errorMessage = 'Error activando cuenta';

      if (e.toString().contains('403') || e.toString().contains('forbidden')) {
        errorMessage = 'Clave inválida. Verifica con tu entrenador/administrador.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'La clave no existe. Contacta con el administrador.';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Tu sesión ha expirado. Inicia sesión nuevamente.';
      } else if (e.toString().contains('unique constraint') || e.toString().contains('already exists')) {
        errorMessage = 'Ya estás vinculado a este gimnasio.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      }

      _setError(errorMessage);
      _setState(GymKeyActivationState.error);
    }
  }

  Future<bool> needsActivation() async {
    try {
      final response = await _apiService.getUserMe();
      final userData = response.data;

      final gimnasio = userData['gimnasio'];
      final gyms = userData['gyms'] as List?;

      final needsLink = gimnasio == null && (gyms == null || gyms.isEmpty);

      return needsLink;
    } catch (e) {
      return true;
    }
  }

  Future<String?> getUserRole() async {
    try {
      final attributes = await _authService.getUserAttributes();

      for (final attr in attributes) {
        final key = attr['name'];
        final value = attr['value'];

        if (key == 'custom:role') {
          return value;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  void reset() {
    _state = GymKeyActivationState.initial;
    _errorMessage = null;
    _isActivated = false;
    notifyListeners();
  }

  void _setState(GymKeyActivationState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}