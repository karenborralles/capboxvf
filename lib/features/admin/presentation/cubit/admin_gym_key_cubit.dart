import 'package:flutter/foundation.dart';
import '../../data/services/admin_gym_key_service.dart';

enum AdminGymKeyState { initial, loading, loaded, saving, error }

class AdminGymKeyCubit extends ChangeNotifier {
  final AdminGymKeyService _keyService;

  AdminGymKeyState _state = AdminGymKeyState.initial;
  String? _gymKey;
  String? _errorMessage;

  AdminGymKeyCubit(this._keyService);

  AdminGymKeyState get state => _state;
  String? get gymKey => _gymKey;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AdminGymKeyState.loading;
  bool get isSaving => _state == AdminGymKeyState.saving;
  bool get hasError => _state == AdminGymKeyState.error;
  bool get hasData => _gymKey != null;

  Future<void> loadGymKey() async {
    try {
      _setState(AdminGymKeyState.loading);
      _clearError();
      _gymKey = await _keyService.getGymKey();
      _setState(AdminGymKeyState.loaded);
    } catch (e) {
      _setError('Error cargando clave del gimnasio: $e');
      _setState(AdminGymKeyState.error);
    }
  }

  Future<void> updateGymKey(String newKey) async {
    try {
      _setState(AdminGymKeyState.saving);
      _clearError();
      await _keyService.updateGymKey(newKey);
      _gymKey = newKey;
      _setState(AdminGymKeyState.loaded);
    } catch (e) {
      _setError('Error actualizando clave del gimnasio: $e');
      _setState(AdminGymKeyState.error);
    }
  }

  String generateNewKey(String gymName) {
    return _keyService.generateNewKey(gymName);
  }

  bool isValidKeyFormat(String key, String gymName) {
    return _keyService.isValidKeyFormat(key, gymName);
  }

  String getExpectedPrefix(String gymName) {
    return _keyService.getExpectedPrefix(gymName);
  }

  Future<Map<String, dynamic>> activarCoachesExistentes() async {
    try {
      final result = await _keyService.activarCoachesExistentes();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  void _setState(AdminGymKeyState newState) {
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