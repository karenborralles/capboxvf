class PlanningRepository {
  Future<List<Routine>> getRoutines({String? nivel}) async {
    await Future.delayed(Duration(seconds: 2));
    return [Routine(id: '1', name: 'Rutina Básica')];
  }

  Future<RoutineDetail> getRoutineDetail(String id) async {
    await Future.delayed(Duration(seconds: 2));
    return RoutineDetail(id: id, name: 'Rutina Básica Detallada');
  }

  Future<List<Assignment>> getMyAssignments() async {
    await Future.delayed(Duration(seconds: 2));
    return [Assignment(id: '1', name: 'Asignación 1')];
  }
}

class Routine {
  final String id;
  final String name;

  Routine({required this.id, required this.name});
}

class RoutineDetail {
  final String id;
  final String name;

  RoutineDetail({required this.id, required this.name});
}

class Assignment {
  final String id;
  final String name;

  Assignment({required this.id, required this.name});
}
