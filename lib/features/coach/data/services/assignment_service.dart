import 'package:capbox/core/services/aws_api_service.dart';

class AssignmentService {
  final AWSApiService _apiService;
  AssignmentService(this._apiService);

  Future<AssignmentResponseDto> assignRoutine({
    required String rutinaId,
    required List<String> atletaIds,
  }) async {
    try {
      final payload = {
        'rutinaId': rutinaId,
        'metaId': null,
        'atletaIds': atletaIds,
      };

      print('[AssignmentService] POST /planning/v1/assignments');
      print(
        '[AssignmentService] Asignando rutina $rutinaId a ${atletaIds.length} atleta(s)',
      );
      print('[AssignmentService] Payload:');
      print(payload);

      final response = await _apiService.post(
        '/planning/v1/assignments',
        data: payload,
      );

      print('[AssignmentService] Response status: ${response.statusCode}');
      print('[AssignmentService] Response data:');
      print(response.data);

      final resultado = AssignmentResponseDto.fromJson(response.data);
      print(
        '[AssignmentService] ${resultado.asignacionesCreadas} asignaciones creadas',
      );

      return resultado;
    } catch (e) {
      print('[AssignmentService] ERROR asignando rutina: $e');
      if (e.toString().contains('404')) {
        print('[AssignmentService] Rutina o atleta no encontrado');
      } else if (e.toString().contains('403')) {
        print(
          '[AssignmentService] Sin permisos para asignar rutinas (solo entrenadores)',
        );
      } else if (e.toString().contains('422')) {
        print('[AssignmentService] Datos de asignación inválidos');
      }
      rethrow;
    }
  }

  Future<List<AthleteAssignmentDto>> getMyAssignments() async {
    try {
      print('[AssignmentService] GET /planning/v1/assignments/me');
      print('[AssignmentService] Obteniendo asignaciones del atleta actual');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final timestampedEndpoint = '/planning/v1/assignments/me?_t=$timestamp';
      print(
        '[AssignmentService] Endpoint con anti-cache: $timestampedEndpoint',
      );

      final response = await _apiService.get(timestampedEndpoint);

      print('[AssignmentService] Response status: ${response.statusCode}');
      print('[AssignmentService] Response data:');
      print(response.data);

      if (response.data is List) {
        final asignaciones =
            (response.data as List)
                .map((e) => AthleteAssignmentDto.fromJson(e))
                .toList();
        print(
          '[AssignmentService] ${asignaciones.length} asignaciones cargadas',
        );
        return asignaciones;
      } else {
        print(
          '[AssignmentService] RESPUESTA INESPERADA: expected List, got ${response.data.runtimeType}',
        );
        print('[AssignmentService] Contenido: ${response.data}');
        return [];
      }
    } catch (e) {
      print('[AssignmentService] ERROR obteniendo asignaciones: $e');
      if (e.toString().contains('404')) {
        print(
          '[AssignmentService] Endpoint /planning/v1/assignments/me no encontrado',
        );
      } else if (e.toString().contains('401')) {
        print(
          '[AssignmentService] Token de autenticación inválido o expirado',
        );
      } else if (e.toString().contains('403')) {
        print(
          '[AssignmentService] Sin permisos para consultar asignaciones (solo atletas)',
        );
      }
      rethrow;
    }
  }

  Future<void> cancelAssignment(String assignmentId) async {
    try {
      print(
        '[AssignmentService] DELETE /planning/v1/assignments/$assignmentId',
      );
      print('[AssignmentService] Cancelando asignación ID: $assignmentId');

      final response = await _apiService.request(
        'DELETE',
        '/planning/v1/assignments/$assignmentId',
      );

      print('[AssignmentService] Response status: ${response.statusCode}');
      print('[AssignmentService] Response data:');
      print(response.data);
      print('[AssignmentService] Asignación cancelada exitosamente');
    } catch (e) {
      print('[AssignmentService] ERROR cancelando asignación: $e');
      if (e.toString().contains('404')) {
        print(
          '[AssignmentService] Asignación con ID $assignmentId no encontrada',
        );
      } else if (e.toString().contains('403')) {
        print(
          '[AssignmentService] Sin permisos para cancelar esta asignación',
        );
      }
      rethrow;
    }
  }

  Future<AthleteAssignmentDto> updateAssignmentStatus(
    String assignmentId,
    String status,
  ) async {
    try {
      final payload = {'estado': status};

      print(
        '[AssignmentService] PATCH /planning/v1/assignments/$assignmentId',
      );
      print(
        '[AssignmentService] Actualizando estado de asignación a: $status',
      );
      print('[AssignmentService] Payload:');
      print(payload);

      final response = await _apiService.patch(
        '/planning/v1/assignments/$assignmentId',
        data: payload,
      );

      print('[AssignmentService] Response status: ${response.statusCode}');
      print('[AssignmentService] Response data:');
      print(response.data);

      final asignacionActualizada = AthleteAssignmentDto.fromJson(
        response.data,
      );
      print(
        '[AssignmentService] Estado actualizado a: ${asignacionActualizada.estado}',
      );

      return asignacionActualizada;
    } catch (e) {
      print(
        '[AssignmentService] ERROR actualizando estado de asignación: $e',
      );
      if (e.toString().contains('404')) {
        print(
          '[AssignmentService] Asignación con ID $assignmentId no encontrada',
        );
      } else if (e.toString().contains('403')) {
        print(
          '[AssignmentService] Sin permisos para actualizar esta asignación',
        );
      } else if (e.toString().contains('422')) {
        print(
          '[AssignmentService] Estado inválido. Estados válidos: PENDIENTE, EN_PROGRESO, COMPLETADA',
        );
      }
      rethrow;
    }
  }
}

class AssignmentResponseDto {
  final String mensaje;
  final int asignacionesCreadas;

  AssignmentResponseDto({
    required this.mensaje,
    required this.asignacionesCreadas,
  });

  factory AssignmentResponseDto.fromJson(Map<String, dynamic> json) {
    return AssignmentResponseDto(
      mensaje: json['mensaje'],
      asignacionesCreadas: json['asignacionesCreadas'],
    );
  }
}

class AthleteAssignmentDto {
  final String id;
  final String nombreRutina;
  final String nombreEntrenador;
  final String estado;
  final DateTime fechaAsignacion;
  final String rutinaId;
  final String assignerId;

  AthleteAssignmentDto({
    required this.id,
    required this.nombreRutina,
    required this.nombreEntrenador,
    required this.estado,
    required this.fechaAsignacion,
    required this.rutinaId,
    required this.assignerId,
  });

  factory AthleteAssignmentDto.fromJson(Map<String, dynamic> json) {
    return AthleteAssignmentDto(
      id: json['id'],
      nombreRutina: json['nombreRutina'],
      nombreEntrenador: json['nombreEntrenador'],
      estado: json['estado'],
      fechaAsignacion: DateTime.parse(json['fechaAsignacion']),
      rutinaId: json['rutinaId'],
      assignerId: json['assignerId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombreRutina': nombreRutina,
        'nombreEntrenador': nombreEntrenador,
        'estado': estado,
        'fechaAsignacion': fechaAsignacion.toIso8601String(),
        'rutinaId': rutinaId,
        'assignerId': assignerId,
      };
}