import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'auth_interceptor.dart';
import '../../features/admin/data/dtos/perfil_usuario_dto.dart';
import '../../features/admin/data/dtos/clave_gimnasio_dto.dart';
import '../api/api_config.dart';

class AWSApiService {
  final Dio _dio;
  final AuthService _authService;

  static const String baseUrl = 'https://api.capbox.site';

  AWSApiService(this._authService) : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(AuthInterceptor());
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      print('API: GET $path');
      final response = await _dio.get(path, queryParameters: queryParameters);
      print('API: GET $path completado');
      return response;
    } catch (e) {
      print('API: Error en GET $path - $e');
      rethrow;
    }
  }

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      print('API: POST $path');
      final response = await _dio.post(path, data: data);
      print('API: POST $path completado');
      return response;
    } catch (e) {
      print('API: Error en POST $path - $e');
      rethrow;
    }
  }

  Future<Response> patch(String path, {Map<String, dynamic>? data}) async {
    try {
      print('API: PATCH $path');
      final response = await _dio.patch(path, data: data);
      print('API: PATCH $path completado');
      return response;
    } catch (e) {
      print('API: Error en PATCH $path - $e');
      rethrow;
    }
  }

  Future<Response> linkAccountToGym(String claveGym) async {
    try {
      print('API: Vinculando cuenta con gimnasio');
      print('API: Endpoint: POST /gyms/link');
      print('API: Clave: $claveGym');

      final response = await _dio.post(
        ApiConfig.linkGym,
        data: {'claveGym': claveGym},
      );

      print('API: Cuenta vinculada exitosamente');
      print('API: Respuesta: ${response.data}');
      return response;
    } catch (e) {
      print('API: Error vinculando cuenta - $e');
      rethrow;
    }
  }

  Future<Response> getUserMe() async {
    try {
      print('API: Obteniendo información del usuario actual');
      print('API: Endpoint: GET ${ApiConfig.userProfile}');

      final response = await _dio.get(ApiConfig.userProfile);

      print('API: Información del usuario obtenida');
      print('API: Respuesta: ${response.data}');
      return response;
    } catch (e) {
      print('API: Error obteniendo información del usuario - $e');
      rethrow;
    }
  }

  Future<Response> getUserProfile() async {
    try {
      print('API: Obteniendo perfil de usuario');

      final response = await _dio.get(ApiConfig.userProfile);

      print('API: Perfil obtenido');
      return response;
    } catch (e) {
      print('API: Error obteniendo perfil - $e');
      rethrow;
    }
  }

  Future<Response> registerUser({
    required String email,
    required String password,
    required String nombre,
    required String rol,
    String? nombreGimnasio,
  }) async {
    try {
      print('API: Registrando usuario en backend');

      final requestData = {
        'email': email,
        'password': password,
        'nombre': nombre,
        'rol': rol,
        if (nombreGimnasio != null) 'nombreGimnasio': nombreGimnasio,
      };

      print('DATOS A ENVIAR:');
      print('  Email: "$email"');
      print('  Password: "${password.length} caracteres"');
      print('  Nombre: "$nombre"');
      print('  Rol: "$rol"');
      if (nombreGimnasio != null) print('  Nombre Gimnasio: "$nombreGimnasio"');
      print('  JSON completo: ${requestData.toString()}');

      final response = await _dio.post(
        ApiConfig.register,
        data: requestData,
        options: Options(validateStatus: (status) => status! < 600),
      );

      print('API: Status Code: ${response.statusCode}');
      print('API: Respuesta del backend: ${response.data}');

      if (response.statusCode == 201) {
        print('API: Usuario registrado en backend');
        return response;
      } else {
        print('API: Error del servidor - Status: ${response.statusCode}');
        print('API: Respuesta de error: ${response.data}');
        throw Exception('Error registrando usuario: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('API: Error de Dio - ${e.response?.statusCode}');
      print('API: Respuesta del servidor - ${e.response?.data}');

      if (e.response == null) {
        throw Exception('Error de conexión: No se pudo conectar con el servidor');
      }

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message']?.toString() ?? '';
          throw Exception('Error de validación: $message');
        }
      }

      if (e.response?.statusCode == 409) {
        throw Exception('Ya existe una cuenta con este email');
      }

      if (e.response?.statusCode == 422) {
        throw Exception('Datos de registro inválidos');
      }

      throw Exception('Error registrando usuario: ${e.response?.statusCode}');
    } catch (e) {
      print('API: Error inesperado - $e');
      rethrow;
    }
  }

  Future<Response> getMyGymKey() async {
    try {
      print('API: Obteniendo clave del gimnasio del entrenador');
      print('API: Endpoint: GET ${ApiConfig.userGymKey}');

      final response = await _dio.get(ApiConfig.userGymKey);

      print('API: Clave del gimnasio obtenida');
      print('API: Respuesta: ${response.data}');
      return response;
    } catch (e) {
      print('API: Error obteniendo clave del gimnasio - $e');
      rethrow;
    }
  }

  Future<Response> getAdminGymKey() async {
    try {
      print('API: Obteniendo clave del gimnasio del admin');
      print('API: Endpoint: GET ${ApiConfig.adminGymKey}');

      final response = await _dio.get(ApiConfig.adminGymKey);

      print('API: Clave del gimnasio obtenida');
      print('API: Respuesta: ${response.data}');
      return response;
    } catch (e) {
      print('API: Error obteniendo clave del gimnasio - $e');
      rethrow;
    }
  }

  Future<Response> updateAdminGymKey(String newKey) async {
    try {
      print('API: Actualizando clave del gimnasio del administrador');
      print('API: Endpoint: PATCH ${ApiConfig.adminGymKey}');
      print('API: Nueva clave: $newKey');

      final response = await _dio.patch(
        ApiConfig.adminGymKey,
        data: {'nuevaClave': newKey},
        options: Options(validateStatus: (status) => status! < 600),
      );

      print('API: Status Code: ${response.statusCode}');
      print('API: Respuesta del backend: ${response.data}');

      if (response.statusCode == 200) {
        print('API: Clave del gimnasio actualizada');
        return response;
      } else {
        print('API: Error del servidor - Status: ${response.statusCode}');
        print('API: Respuesta de error: ${response.data}');
        throw Exception('Error actualizando clave: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('API: Error de Dio - ${e.response?.statusCode}');
      print('API: Respuesta del servidor - ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message']?.toString() ?? '';
          throw Exception('Error de validación: $message');
        }
      }

      throw Exception('Error actualizando clave: ${e.response?.statusCode}');
    } catch (e) {
      print('API: Error inesperado - $e');
      rethrow;
    }
  }

  Future<Response> getGymMembers(String gymId) async {
    try {
      print('API: Obteniendo miembros del gimnasio');
      print('API: Gym ID: $gymId');

      final response = await _dio.get(ApiConfig.gymMembersByGym(gymId));

      print('API: Miembros obtenidos');
      return response;
    } catch (e) {
      print('API: Error obteniendo miembros - $e');
      rethrow;
    }
  }

  Future<Response> getPendingRequests() async {
    try {
      print('API: Obteniendo solicitudes pendientes');

      final data = _addCoachUserId({});

      final response = await _dio.get(
        ApiConfig.pendingRequests,
        data: data,
      );

      print('API: Solicitudes obtenidas');
      return response;
    } catch (e) {
      print('API: Error obteniendo solicitudes - $e');
      rethrow;
    }
  }

  Future<Response> registerAttendance({
    required DateTime date,
    required List<String> athleteIds,
  }) async {
    try {
      print('API: Registrando asistencia');
      print('API: Fecha: $date');
      print('API: Atletas: $athleteIds');

      final data = _addCoachUserId({
        'fecha': date.toIso8601String(),
        'atletaIds': athleteIds,
      });

      final response = await _dio.post(
        '/performance/attendance',
        data: data,
      );

      print('API: Asistencia registrada');
      return response;
    } catch (e) {
      print('API: Error registrando asistencia - $e');
      rethrow;
    }
  }

  Future<Response> registerTrainingSession({
    required String routineId,
    required int duration,
    required String notes,
  }) async {
    try {
      print('API: Registrando sesión de entrenamiento');
      print('API: Rutina: $routineId');
      print('API: Duración: $duration minutos');

      final data = _addAthleteUserId({
        'routineId': routineId,
        'duration': duration,
        'notes': notes,
        'completedAt': DateTime.now().toIso8601String(),
      });

      final response = await _dio.post(
        '/performance/sessions',
        data: data,
      );

      print('API: Sesión registrada');
      return response;
    } catch (e) {
      print('API: Error registrando sesión - $e');
      rethrow;
    }
  }

  Future<Response> approveAthlete({
    required String athleteId,
    required Map<String, dynamic> physicalData,
    required Map<String, dynamic> tutorData,
  }) async {
    print('API: Aprobando atleta $athleteId con datos completos');

    final Map<String, dynamic> body = {
      'nivel': physicalData['nivel'] ?? 'principiante',
      'alturaCm': physicalData['estatura'] ?? 170,
      'pesoKg': physicalData['peso'] ?? 70,
      'guardia': physicalData['guardia'] ?? 'orthodox',
      'alergias': physicalData['condicionesMedicas'] ?? '',
      'contactoEmergenciaNombre': tutorData['nombreTutor'] ?? '',
      'contactoEmergenciaTelefono': tutorData['telefonoTutor'] ?? '',
    };

    print('API: Body enviado - $body');

    try {
      final response = await _dio.post(
        ApiConfig.approveAthlete(athleteId),
        data: body,
      );

      print('API: Atleta aprobado exitosamente');
      return response;
    } on DioException catch (e) {
      print('API: Error aprobando atleta - $e');

      if (e.response?.statusCode == 403) {
        throw Exception('Error 403: No tienes permisos para aprobar atletas. Contacta al administrador.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Error 404: No se encontró solicitud para este atleta. El atleta podría no estar vinculado al gimnasio correctamente.');
      } else {
        throw Exception('Error aprobando atleta: ${e.message}');
      }
    } catch (e) {
      print('API: Error inesperado aprobando atleta - $e');
      throw Exception('Error inesperado aprobando atleta: $e');
    }
  }

  static const String _adminUserId = '00000000-0000-0000-0000-000000000001';
  static const String _coachUserId = '00000000-0000-0000-0000-000000000002';
  static const String _athleteUserId = '00000000-0000-0000-0000-000000000003';

  Map<String, dynamic> _addTestUserId(Map<String, dynamic> data, {String? userId}) {
    final newData = Map<String, dynamic>.from(data);
    newData['userId'] = userId ?? _athleteUserId;
    return newData;
  }

  Map<String, dynamic> _addAdminUserId(Map<String, dynamic> data) {
    return _addTestUserId(data, userId: _adminUserId);
  }

  Map<String, dynamic> _addCoachUserId(Map<String, dynamic> data) {
    return _addTestUserId(data, userId: _coachUserId);
  }

  Map<String, dynamic> _addAthleteUserId(Map<String, dynamic> data) {
    return _addTestUserId(data, userId: _athleteUserId);
  }

  Future<Response> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      print('API: $method $path');

      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );

      print('API: $method $path completado');
      return response;
    } catch (e) {
      print('API: Error en $method $path - $e');
      rethrow;
    }
  }
}