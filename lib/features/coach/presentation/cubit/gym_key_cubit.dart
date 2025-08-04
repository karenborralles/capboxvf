import 'package:flutter/foundation.dart';
import '../../data/services/gym_key_service.dart';

enum GymKeyState { initial, loading, loaded, error }

class GymKeyCubit extends ChangeNotifier {
  final GymKeyService _gymKeyService;

  GymKeyState _state = GymKeyState.initial;
  String? _gymKey;
  String? _errorMessage;

  GymKeyCubit(this._gymKeyService);

  GymKeyState get state => _state;
  String? get gymKey => _gymKey;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == GymKeyState.loading;
  bool get hasError => _state == GymKeyState.error;
  bool get hasKey => _gymKey != null && _gymKey!.isNotEmpty;

  Future<void> loadGymKey() async {
    try {
      _setState(GymKeyState.loading);
      _clearError();

      print('CUBIT: Cargando clave del gimnasio');

      final keyResponse = await _gymKeyService.getMyGymKey();
      _gymKey = keyResponse.claveGym;
      print('CUBIT: Clave cargada desde backend - $_gymKey');

      _setState(GymKeyState.loaded);
    } catch (e) {
      print('CUBIT: Error cargando clave - $e');
      _setError('Error cargando clave del gimnasio: $e');
      _setState(GymKeyState.error);
    }
  }

  Future<void> refreshGymKey() async {
    await loadGymKey();
  }

  void copyKeyToClipboard() {
    if (_gymKey != null) {
      print('CUBIT: Clave copiada al portapapeles - $_gymKey');
      _showSuccessMessage('Clave copiada al portapapeles');
    }
  }

  void _showSuccessMessage(String message) {
    print('CUBIT: $message');
  }

  String getShareText() {
    if (_gymKey == null) return '';

    return '''
Invitación al Gimnasio CapBox

¡Únete a nuestro gimnasio!

Clave de acceso: $_gymKey

1. Descarga la app CapBox
2. Regístrate como "Boxeador"
3. Ingresa esta clave
4. ¡Comienza a entrenar!
''';
  }

  bool isKeyValid() {
    return _gymKey != null &&
        _gymKey!.isNotEmpty &&
        _gymKey!.length >= 3;
  }

  Map<String, String> getKeyInfo() {
    if (_gymKey == null) return {};

    return {
      'clave': _gymKey!,
      'longitud': _gymKey!.length.toString(),
      'formato': _gymKey!.contains('-') ? 'Con guiones' : 'Sin guiones',
      'estado': isKeyValid() ? 'Válida' : 'Inválida',
    };
  }

  void _setState(GymKeyState newState) {
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