import '../../domain/entities/routine.dart';
import '../../../boxer/domain/entities/training_session.dart';
import '../dtos/routine_dto.dart';

class RoutineMapper {
  static Routine fromListDto(RoutineListDto dto) {
    return Routine(
      id: dto.id,
      sportId: 'boxing',
      coachId: '',
      name: dto.nombre,
      targetLevel: dto.nivel,
      description: 'Rutina nivel ${dto.nivel}',
      dueDate: DateTime.now().add(Duration(days: 30)),
    );
  }

  static Routine fromDetailDto(RoutineDetailDto dto) {
    return Routine(
      id: dto.id,
      sportId: 'boxing',
      coachId: '',
      name: dto.nombre,
      targetLevel: dto.nivel,
      description: 'Rutina con ${dto.ejercicios.length} ejercicios',
      dueDate: DateTime.now().add(Duration(days: 30)),
    );
  }

  static Exercise fromEjercicioDto(EjercicioDto dto) {
    return Exercise(
      id: dto.id,
      sportId: 'boxing',
      name: dto.nombre,
      description: dto.setsReps ?? 'Sin descripción',
    );
  }

  static List<Exercise> fromEjerciciosList(List<EjercicioDto> dtos) {
    return dtos.map((dto) => fromEjercicioDto(dto)).toList();
  }

  static Map<String, dynamic> toCreateJson(
    Routine routine,
    List<Exercise> exercises,
  ) {
    return {
      'nombre': routine.name,
      'nivel': routine.targetLevel,
      'ejercicios': exercises
          .map(
            (exercise) => {
              'nombre': exercise.name,
              'setsReps': exercise.description,
            },
          )
          .toList(),
    };
  }
}

class AssignmentMapper {
  static AthleteAssignment fromDto(AssignmentDto dto) {
    return AthleteAssignment(
      id: dto.idAsignacion,
      athleteId: '',
      assignerId: dto.idAsignador,
      routineId: dto.tipoPlan == 'Rutina' ? dto.idPlan : null,
      goalId: dto.tipoPlan == 'Meta' ? dto.idPlan : null,
      status: _parseStatus(dto.estado),
      assignedAt: dto.fechaAsignacion,
    );
  }

  static AssignmentStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDIENTE':
        return AssignmentStatus.pending;
      case 'EN_PROGRESO':
        return AssignmentStatus.inProgress;
      case 'COMPLETADO':
        return AssignmentStatus.completed;
      case 'CANCELADO':
        return AssignmentStatus.cancelled;
      default:
        return AssignmentStatus.pending;
    }
  }

  static String statusToString(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return 'PENDIENTE';
      case AssignmentStatus.inProgress:
        return 'EN_PROGRESO';
      case AssignmentStatus.completed:
        return 'COMPLETADO';
      case AssignmentStatus.cancelled:
        return 'CANCELADO';
    }
  }
}