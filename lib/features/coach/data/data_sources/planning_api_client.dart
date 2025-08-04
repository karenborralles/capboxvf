import 'package:dio/dio.dart';
import '../../../../core/api/api_config.dart';
import '../dtos/routine_dto.dart';

class PlanningApiClient {
  final Dio _dio;

  PlanningApiClient(this._dio);

  Future<List<RoutineListDto>> getRoutines({
    String? nivel,
    required String token,
  }) async {
    String endpoint = ApiConfig.routines;
    if (nivel != null) {
      endpoint = ApiConfig.routinesByLevel(nivel);
    }

    final response = await _dio.get(
      ApiConfig.getPlanificacionUrl(endpoint),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return (response.data as List)
        .map((json) => RoutineListDto.fromJson(json))
        .toList();
  }

  Future<RoutineDetailDto> getRoutineDetail(
    String routineId,
    String token,
  ) async {
    final response = await _dio.get(
      ApiConfig.getPlanificacionUrl(ApiConfig.routineById(routineId)),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return RoutineDetailDto.fromJson(response.data);
  }

  Future<List<AssignmentDto>> getMyAssignments(String token) async {
    final response = await _dio.get(
      ApiConfig.getPlanificacionUrl(ApiConfig.myAssignments),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return (response.data as List)
        .map((json) => AssignmentDto.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> assignRoutine({
    required String athleteId,
    required String routineId,
    required String token,
  }) async {
    final response = await _dio.post(
      ApiConfig.getPlanificacionUrl('/planning/assignments'),
      data: {
        'athleteId': athleteId,
        'routineId': routineId,
        'tipoPlan': 'Rutina',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> updateAssignmentStatus({
    required String assignmentId,
    required String status,
    required String token,
  }) async {
    final response = await _dio.patch(
      ApiConfig.getPlanificacionUrl(
        '/planning/assignments/$assignmentId',
      ),
      data: {'estado': status},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> createRoutine({
    required String nombre,
    required String nivel,
    required List<Map<String, dynamic>> ejercicios,
    required String token,
  }) async {
    final response = await _dio.post(
      ApiConfig.getPlanificacionUrl(ApiConfig.routines),
      data: {'nombre': nombre, 'nivel': nivel, 'ejercicios': ejercicios},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<List<RoutineListDto>> getCoachRoutines(
    String coachId,
    String token,
  ) async {
    final response = await _dio.get(
      ApiConfig.getPlanificacionUrl('/planning/v1/routines/coach/$coachId'),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return (response.data as List)
        .map((json) => RoutineListDto.fromJson(json))
        .toList();
  }
}