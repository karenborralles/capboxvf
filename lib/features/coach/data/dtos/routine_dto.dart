class RoutineListDto {
  final String id;
  final String nombre;
  final String nivel;
  final int cantidadEjercicios;
  final int duracionEstimadaMinutos;

  RoutineListDto({
    required this.id,
    required this.nombre,
    required this.nivel,
    required this.cantidadEjercicios,
    required this.duracionEstimadaMinutos,
  });

  factory RoutineListDto.fromJson(Map<String, dynamic> json) {
    return RoutineListDto(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      nivel: json['nivel'] ?? '',
      cantidadEjercicios: json['cantidadEjercicios'] ?? 0,
      duracionEstimadaMinutos: json['duracionEstimadaMinutos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'nivel': nivel,
        'cantidadEjercicios': cantidadEjercicios,
        'duracionEstimadaMinutos': duracionEstimadaMinutos,
      };
}

class RoutineDetailDto {
  final String id;
  final String nombre;
  final String nivel;
  final String? coachId;
  final int? sportId;
  final String? descripcion;
  final List<EjercicioDto> ejercicios;

  RoutineDetailDto({
    required this.id,
    required this.nombre,
    required this.nivel,
    this.coachId,
    this.sportId,
    this.descripcion,
    required this.ejercicios,
  });

  factory RoutineDetailDto.fromJson(Map<String, dynamic> json) {
    return RoutineDetailDto(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      nivel: json['nivel'] ?? '',
      coachId: json['coachId'],
      sportId: json['sportId'],
      descripcion: json['descripcion'],
      ejercicios: (json['ejercicios'] as List? ?? [])
          .map((e) => EjercicioDto.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'nivel': nivel,
        'coachId': coachId,
        'sportId': sportId,
        'descripcion': descripcion,
        'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
      };
}

class EjercicioDto {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? setsReps;
  final int? duracionEstimadaSegundos;
  final String? categoria;

  EjercicioDto({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.setsReps,
    this.duracionEstimadaSegundos,
    this.categoria,
  });

  factory EjercicioDto.fromJson(Map<String, dynamic> json) {
    return EjercicioDto(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      setsReps: json['setsReps'],
      duracionEstimadaSegundos: json['duracionEstimadaSegundos'],
      categoria: json['categoria'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'setsReps': setsReps,
        'duracionEstimadaSegundos': duracionEstimadaSegundos,
        'categoria': categoria,
      };
}

class CreateRoutineDto {
  final String nombre;
  final String nivel;
  final String sportId;
  final String? descripcion;
  final List<CreateEjercicioDto> ejercicios;

  CreateRoutineDto({
    required this.nombre,
    required this.nivel,
    required this.sportId,
    this.descripcion,
    required this.ejercicios,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'nivel': nivel,
        'sportId': sportId,
        'descripcion': descripcion,
        'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
      };
}

class CreateEjercicioDto {
  final String id;
  final String nombre;
  final String? descripcion;
  final String setsReps;
  final int duracionEstimadaSegundos;
  final String categoria;

  CreateEjercicioDto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.setsReps,
    required this.duracionEstimadaSegundos,
    required this.categoria,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'setsReps': setsReps,
        'duracionEstimadaSegundos': duracionEstimadaSegundos,
        'categoria': categoria,
      };
}

class AssignmentDto {
  final String idAsignacion;
  final String tipoPlan;
  final String idPlan;
  final String nombrePlan;
  final String idAsignador;
  final String estado;
  final DateTime fechaAsignacion;

  AssignmentDto({
    required this.idAsignacion,
    required this.tipoPlan,
    required this.idPlan,
    required this.nombrePlan,
    required this.idAsignador,
    required this.estado,
    required this.fechaAsignacion,
  });

  factory AssignmentDto.fromJson(Map<String, dynamic> json) {
    return AssignmentDto(
      idAsignacion: json['idAsignacion'],
      tipoPlan: json['tipoPlan'],
      idPlan: json['idPlan'],
      nombrePlan: json['nombrePlan'],
      idAsignador: json['idAsignador'],
      estado: json['estado'],
      fechaAsignacion: DateTime.parse(json['fechaAsignacion']),
    );
  }

  Map<String, dynamic> toJson() => {
        'idAsignacion': idAsignacion,
        'tipoPlan': tipoPlan,
        'idPlan': idPlan,
        'nombrePlan': nombrePlan,
        'idAsignador': idAsignador,
        'estado': estado,
        'fechaAsignacion': fechaAsignacion.toIso8601String(),
      };
}