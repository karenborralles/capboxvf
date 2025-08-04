import '../../../../core/services/aws_api_service.dart';
import 'dart:math';

class AdminGymKeyService {
  final AWSApiService _apiService;

  AdminGymKeyService(this._apiService);

  Future<String> getGymKey() async {
    try {
      print('ADMIN: Obteniendo clave del gimnasio desde /users/me/gym/key');

      final response = await _apiService.getAdminGymKey();

      final key =
          response.data['claveGym'] ??
          response.data['claveGimnasio'] ??
          response.data['gymKey'] ??
          response.data['clave'];

      if (key == null || key.isEmpty) {
        throw Exception('Clave del gimnasio no encontrada en respuesta');
      }

      print('ADMIN: Clave obtenida - $key');
      return key;
    } catch (e) {
      print('ADMIN: Error obteniendo clave - $e');
      if (e.toString().contains('404')) {
        throw Exception('No tienes un gimnasio asignado. Contacta al administrador.');
      } else if (e.toString().contains('403')) {
        throw Exception('No tienes permisos para ver la clave del gimnasio.');
      }
      rethrow;
    }
  }

  Future<void> updateGymKey(String newKey) async {
    try {
      if (newKey.length < 8) {
        throw Exception('La nueva clave debe tener al menos 8 caracteres');
      }

      if (!RegExp(r'^[A-Z0-9\-_]+$').hasMatch(newKey)) {
        throw Exception(
          'La clave solo puede contener letras mayúsculas, números, guiones y guiones bajos',
        );
      }

      print('ADMIN: Actualizando clave del gimnasio a: $newKey (${newKey.length} caracteres)');

      await _apiService.updateAdminGymKey(newKey);

      print('ADMIN: Clave actualizada exitosamente');
    } catch (e) {
      print('ADMIN: Error actualizando clave - $e');
      rethrow;
    }
  }

  String generateNewKey(String gymName) {
    if (gymName.isEmpty) {
      throw ArgumentError('El nombre del gimnasio no puede estar vacío');
    }

    final prefix = gymName.trim().toUpperCase().substring(0, 3);

    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final suffix = String.fromCharCodes(
      Iterable.generate(
        5 + random.nextInt(3),
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );

    final newKey = '$prefix$suffix';
    print('ADMIN: Generando clave para gimnasio "$gymName" -> "$newKey" (${newKey.length} caracteres)');

    if (newKey.length < 8) {
      throw Exception('Error generando clave: debe tener al menos 8 caracteres');
    }

    return newKey;
  }

  bool isValidKeyFormat(String key, String gymName) {
    if (key.isEmpty || gymName.isEmpty) return false;

    final expectedPrefix = gymName.trim().toUpperCase().substring(0, 3);

    if (!key.toUpperCase().startsWith(expectedPrefix)) {
      return false;
    }

    if (key.length < 8) {
      return false;
    }

    final suffix = key.substring(3);
    if (suffix.length < 5) {
      return false;
    }

    if (!RegExp(r'^[A-Z0-9\-_]+$').hasMatch(key)) {
      return false;
    }

    return true;
  }

  String getExpectedPrefix(String gymName) {
    if (gymName.isEmpty) return '';
    return gymName.trim().toUpperCase().substring(0, 3);
  }

  Future<Map<String, dynamic>> activarCoachesExistentes() async {
    try {
      print('ADMIN: Activando coaches existentes...');

      final response = await _apiService.post(
        '/identity/v1/usuarios/fix-coaches-estado',
        data: {},
      );

      print('ADMIN: Coaches activados exitosamente');
      print('ADMIN: Respuesta: ${response.data}');

      return response.data;
    } catch (e) {
      print('ADMIN: Error activando coaches - $e');
      rethrow;
    }
  }

  Future<bool> testEndpointFixCoaches() async {
    try {
      print('ADMIN: Probando endpoint fix-coaches-estado...');

      final response = await _apiService.post(
        '/identity/v1/usuarios/fix-coaches-estado',
        data: {},
      );

      print('ADMIN: Endpoint existe y funciona');
      print('ADMIN: Respuesta: ${response.data}');

      return true;
    } catch (e) {
      print('ADMIN: Endpoint NO existe o error - $e');
      return false;
    }
  }
}