import '../../../../core/services/aws_api_service.dart';
import '../dtos/gym_key_dto.dart';
import 'dart:math';

class GymKeyService {
  final AWSApiService _apiService;

  GymKeyService(this._apiService);

  Future<GymKeyResponse> getMyGymKey() async {
    try {
      print('GYM_KEY: Obteniendo MI clave de gimnasio');
      print('GYM_KEY: URL: GET /users/me/gym/key');

      final response = await _apiService.getMyGymKey();

      print('GYM_KEY: Respuesta completa: ${response.data}');
      print('GYM_KEY: Status code: ${response.statusCode}');

      final gymKeyResponse = GymKeyResponse.fromJson(response.data);

      print('GYM_KEY: Mi clave obtenida - ${gymKeyResponse.claveGym}');

      return gymKeyResponse;
    } catch (e) {
      print('GYM_KEY: Error detallado obteniendo mi clave - $e');
      print('GYM_KEY: Tipo de error: ${e.runtimeType}');

      if (e.toString().contains('404')) {
        print('GYM_KEY: Endpoint /gyms/my/key no existe en el backend');
      }

      rethrow;
    }
  }

  Future<String?> getGymKeyWithErrorHandling() async {
    try {
      final response = await getMyGymKey();
      return response.claveGym;
    } catch (e) {
      print('GYM_KEY: Error manejado - $e');

      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('403') || errorMessage.contains('forbidden')) {
        throw Exception(
          'Solo los entrenadores pueden obtener la clave del gimnasio',
        );
      } else if (errorMessage.contains('404') ||
          errorMessage.contains('not found')) {
        throw Exception('No estás asociado a ningún gimnasio');
      } else if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw Exception('Tu sesión ha expirado. Inicia sesión nuevamente');
      } else {
        throw Exception('Error obteniendo la clave del gimnasio');
      }
    }
  }

  GymKeyResponse getMockGymKey() {
    return GymKeyResponse(claveGym: 'gym1234');
  }

  GymKeyResponse generateUniqueKey(String coachId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);
    return GymKeyResponse(claveGym: 'ZIK$timestamp');
  }

  GymKeyResponse generateKeyFromGymName(String gymName) {
    if (gymName.isEmpty) {
      throw ArgumentError('El nombre del gimnasio no puede estar vacío');
    }

    final prefix = gymName.trim().toUpperCase().substring(0, 3);

    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final suffix = String.fromCharCodes(
      Iterable.generate(
        4 + random.nextInt(3),
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );

    final newKey = '$prefix$suffix';
    print('GYM_KEY: Generando clave para gimnasio "$gymName" -> "$newKey"');

    return GymKeyResponse(claveGym: newKey);
  }
}